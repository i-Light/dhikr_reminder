import { randomBytes } from 'node:crypto';

import { powHolds, toBase64Url } from '../src/core.mjs';
import { openNodeDb } from '../src/db_node.mjs';
import { FIREWALL, createFirewall, serve } from '../src/firewall.mjs';

export const ADMIN = 'test-admin-token-0123456789abcdef';

/** A service on an in-memory database with a clock the test can move. */
export function makeApp({ powBits = 4, env = {} } = {}) {
  const clock = { t: 1_800_000_000 };
  const db = openNodeDb(':memory:');
  const firewall = createFirewall();
  const deps = {
    db,
    env: {
      ADMIN_TOKEN: ADMIN,
      CHALLENGE_SECRET: 'test-challenge-secret',
      IP_SALT: 'test-ip-salt',
      POW_BITS: String(powBits),
      ...env,
    },
    now: () => clock.t,
    randomBytes: (n) => new Uint8Array(randomBytes(n)),
  };
  return {
    db,
    clock,
    deps,
    firewall,
    async call(method, path, { headers = {}, body, ip = '203.0.113.7', raw } = {}) {
      const payload = raw ?? (body === undefined ? undefined : JSON.stringify(body));
      const request = new Request(`https://svc.example${path}`, {
        method,
        headers: {
          'CF-Connecting-IP': ip,
          'User-Agent': FIREWALL.clientAgent,
          ...(payload !== undefined ? { 'Content-Type': 'application/json' } : {}),
          ...headers,
        },
        body: payload,
      });
      const response = await serve(firewall, request, deps);
      const text = await response.text();
      let json = null;
      try {
        json = JSON.parse(text);
      } catch {
        // not JSON
      }
      return { status: response.status, headers: response.headers, json, text };
    },
  };
}

export function newInstall() {
  return toBase64Url(new Uint8Array(randomBytes(32)));
}

/** Finds the counter that solves a puzzle, the way the app does. */
export async function solve(challenge, install, bits) {
  for (let counter = 0; ; counter++) {
    if (await powHolds(challenge, install, counter, bits)) return counter;
  }
}

export const DHIKR = 'اللهم إني أسألك علما نافعا ورزقا طيبا وعملا متقبلا';

/** Gets a puzzle, solves it and posts a request. */
export async function submit(app, install, fields = {}, { ip, headers } = {}) {
  const ch = await app.call('GET', '/v1/challenge', { ip });
  assertOk(ch.status === 200, `challenge answered ${ch.status}`);
  const counter = await solve(ch.json.challenge, install, ch.json.bits);
  return app.call('POST', '/v1/requests', {
    ip,
    headers: { Authorization: `Bearer ${install}`, ...headers },
    body: {
      text: DHIKR,
      challenge: ch.json.challenge,
      counter,
      locale: 'ar',
      platform: 'android',
      appVersion: '0.1.3',
      ...fields,
    },
  });
}

export function list(app, install, ip) {
  return app.call('GET', '/v1/requests', { ip, headers: { Authorization: `Bearer ${install}` } });
}

export function admin(app, method, path, body, headers = {}) {
  return app.call(method, path, {
    body,
    headers: { Authorization: `Bearer ${ADMIN}`, ...headers },
  });
}

function assertOk(condition, message) {
  if (!condition) throw new Error(message);
}
