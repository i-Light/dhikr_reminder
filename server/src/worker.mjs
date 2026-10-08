// The Cloudflare Worker: wires the firewall and core.mjs to D1 and the Worker's secrets.
import { serve, createFirewall } from './firewall.mjs';
import { d1Db } from './db_d1.mjs';

const REQUIRED = ['DB', 'CHALLENGE_SECRET', 'IP_SALT'];

// Made once per Worker instance, so its counters outlive a single request.
const firewall = createFirewall();

export default {
  async fetch(request, env) {
    const missing = REQUIRED.filter((name) => !env[name]);
    if (missing.length > 0) {
      // Says what is missing in the Worker's log, nothing to the caller.
      console.error(`missing configuration: ${missing.join(', ')}`);
      return new Response(JSON.stringify({ error: 'server_error' }), {
        status: 500,
        headers: { 'Content-Type': 'application/json; charset=utf-8', 'Cache-Control': 'no-store' },
      });
    }
    return serve(firewall, request, {
      db: d1Db(env.DB),
      env,
      now: () => Math.floor(Date.now() / 1000),
      randomBytes: (n) => crypto.getRandomValues(new Uint8Array(n)),
    });
  },
};
