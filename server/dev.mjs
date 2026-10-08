// Runs the request service on this computer, with no Cloudflare:
//
//     node dev.mjs            (a database file, dev.sqlite, next to this file)
//     node dev.mjs --memory   (forgets everything when it stops)
//
// Same code as the Worker (src/core.mjs) over node:sqlite. The secrets below
// are throwaway values for local use; the proof-of-work is turned down so a
// phone solves it in a blink. Set PORT, ADMIN_TOKEN and POW_BITS to change them.
import { createServer } from 'node:http';
import { randomBytes } from 'node:crypto';

import { createFirewall, serve } from './src/firewall.mjs';
import { openNodeDb } from './src/db_node.mjs';

const port = Number(process.env.PORT ?? 8787);
const memory = process.argv.includes('--memory');
const db = openNodeDb(memory ? ':memory:' : new URL('./dev.sqlite', import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1'));

const env = {
  ADMIN_TOKEN: process.env.ADMIN_TOKEN ?? 'dev-admin-token-0123456789abcdef',
  CHALLENGE_SECRET: process.env.CHALLENGE_SECRET ?? 'dev-challenge-secret',
  IP_SALT: process.env.IP_SALT ?? 'dev-ip-salt',
  POW_BITS: process.env.POW_BITS ?? '12',
};

const firewall = createFirewall();

const deps = {
  db,
  env,
  now: () => Math.floor(Date.now() / 1000),
  randomBytes: (n) => new Uint8Array(randomBytes(n)),
};

const server = createServer(async (req, res) => {
  const chunks = [];
  let size = 0;
  for await (const chunk of req) {
    size += chunk.length;
    if (size > 64 * 1024) {
      res.writeHead(413).end();
      return;
    }
    chunks.push(chunk);
  }
  const headers = new Headers();
  for (const [name, value] of Object.entries(req.headers)) {
    if (value !== undefined) headers.set(name, Array.isArray(value) ? value.join(', ') : value);
  }
  headers.set('X-Real-IP', req.socket.remoteAddress ?? 'local');
  const hasBody = req.method !== 'GET' && req.method !== 'HEAD';
  const request = new Request(`http://${req.headers.host ?? `localhost:${port}`}${req.url}`, {
    method: req.method,
    headers,
    body: hasBody ? Buffer.concat(chunks) : undefined,
  });
  const response = await serve(firewall, request, deps);
  res.writeHead(response.status, Object.fromEntries(response.headers));
  res.end(Buffer.from(await response.arrayBuffer()));
});

server.listen(port, '127.0.0.1', () => {
  console.log(`Dhikr request service on http://127.0.0.1:${port}`);
  console.log(`Admin page:  http://127.0.0.1:${port}/admin`);
  console.log(`Admin token: ${env.ADMIN_TOKEN}`);
  console.log(`Proof of work: ${env.POW_BITS} bits. Database: ${memory ? 'memory' : 'dev.sqlite'}`);
});
