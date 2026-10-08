// The service's own firewall: it turns requests away before core.mjs, and so
// before the database, ever sees them.
//
// A hosted web application firewall would do this in front of the Worker, but
// those rules belong to a domain you own on Cloudflare and rate limiting there
// is a paid add-on; a `workers.dev` address has neither. This does the same job
// in the Worker itself, with memory instead of the database, so a flood cannot
// use up the database's free daily writes.
//
// In the order a request meets it:
//   1. a ban: an address that sent many bad requests is refused for a while;
//   2. shape: an over-long address or a method the service never uses;
//   3. client: the app sends its own User-Agent. Anything else on /v1 (a
//      browser, curl, a scanner) is turned away. This is a speed bump, not a
//      lock: anyone can copy the header, and the puzzle and limits behind it
//      are what actually hold;
//   4. volume: a per-minute limit per address, kept in memory, and again by
//      Cloudflare's Rate Limiting binding when the Worker has one (RL_V1 and
//      RL_ADMIN in wrangler.toml; without them only the memory limit applies).
//
// After core.mjs has answered, the answer counts: bad requests (400, 401, 403,
// 404, 405, 413, 414, 415) are strikes against the address, and enough of them
// in a short while is a ban. Being limited (429) is not a strike.
//
// Everything here is keyed by the same salted daily hash of the address that
// the rest of the service uses; no address is kept, and all of it is forgotten
// when the Worker instance is.

import { fail, handle, ipKey, tooMany } from './core.mjs';
import { createLimiter } from './limiter.mjs';

export const FIREWALL = Object.freeze({
  urlMax: 400,
  apiPerMinute: 60,
  adminPerMinute: 30,
  otherPerMinute: 120,
  strikeWindow: 600,
  strikesToBan: 25,
  banSeconds: 1800,
  /** Where the app says it comes from: lib/features/requests/data/request_gateway.dart. */
  clientAgent: 'dhikr_reminder-requests',
});

const METHODS = new Set(['GET', 'HEAD', 'POST', 'DELETE']);
const STRIKE_STATUSES = new Set([400, 401, 403, 404, 405, 413, 414, 415]);
const MAX_BANS = 5000;

/** Asks a Cloudflare Rate Limiting binding. Without one, or if it fails, the answer is yes. */
async function platformAllows(binding, key) {
  if (!binding || typeof binding.limit !== 'function') return true;
  try {
    const { success } = await binding.limit({ key });
    return success !== false;
  } catch {
    return true;
  }
}

function areaOf(url) {
  const path = new URL(url).pathname;
  if (path.startsWith('/v1/')) return 'api';
  if (path === '/admin' || path.startsWith('/admin/')) return 'admin';
  return 'other';
}

export function createFirewall() {
  const limiter = createLimiter();
  const bans = new Map();

  function strike(key, t) {
    const strikes = limiter.add('fw-strike', key, FIREWALL.strikeWindow, t);
    if (strikes < FIREWALL.strikesToBan) return;
    if (bans.size >= MAX_BANS) {
      for (const [who, until] of bans) if (until <= t) bans.delete(who);
      if (bans.size >= MAX_BANS) bans.delete(bans.keys().next().value);
    }
    bans.set(key, t + FIREWALL.banSeconds);
    console.warn('firewall: an address was banned after repeated bad requests');
  }

  function reject(key, t, status, error, headers = {}) {
    strike(key, t);
    return { response: fail(status, error, {}, headers) };
  }

  return {
    limiter,

    /**
     * Looks at a request before anything else does. Answers `{ response }` when
     * it is turned away, or `{ key }` (the address's hash) when it may go on.
     */
    async screen(request, env, t) {
      const key = await ipKey(request, env, t);

      const until = bans.get(key);
      if (until !== undefined) {
        if (until > t) return { response: tooMany(until - t) };
        bans.delete(key);
      }

      if (request.url.length > FIREWALL.urlMax) return reject(key, t, 414, 'bad_request');
      if (!METHODS.has(request.method)) {
        return reject(key, t, 405, 'method_not_allowed', { Allow: 'GET, HEAD, POST, DELETE' });
      }

      const area = areaOf(request.url);
      if (area === 'api') {
        const agent = request.headers.get('User-Agent') ?? '';
        if (!agent.startsWith(FIREWALL.clientAgent)) return reject(key, t, 403, 'forbidden');
      }

      const perMinute = {
        api: FIREWALL.apiPerMinute,
        admin: FIREWALL.adminPerMinute,
        other: FIREWALL.otherPerMinute,
      }[area];
      const local = limiter.hit(`fw-${area}`, key, 60, perMinute, t);
      if (!local.ok) return { response: tooMany(local.retryAfter) };
      const binding = area === 'api' ? env.RL_V1 : area === 'admin' ? env.RL_ADMIN : null;
      if (!(await platformAllows(binding, key))) return { response: tooMany(30) };

      return { key };
    },

    /** Counts the answer core.mjs gave: a bad request is a strike. */
    record(key, status, t) {
      if (key && STRIKE_STATUSES.has(status)) strike(key, t);
    },
  };
}

/** One request through the firewall and then the service. */
export async function serve(firewall, request, deps) {
  const t = deps.now();
  const gate = await firewall.screen(request, deps.env, t);
  if (gate.response) return gate.response;
  const response = await handle(request, { ...deps, cheap: firewall.limiter });
  firewall.record(gate.key, response.status, t);
  return response;
}
