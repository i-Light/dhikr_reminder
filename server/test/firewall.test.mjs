import assert from 'node:assert/strict';
import { test } from 'node:test';

import { FIREWALL, serve } from '../src/firewall.mjs';
import { createLimiter } from '../src/limiter.mjs';
import { DHIKR, admin, list, makeApp, newInstall, submit } from './helpers.mjs';

const OTHER = '198.51.100.9';

async function writtenRows(app) {
  const [row] = await app.db.all('SELECT COUNT(*) AS c FROM rate_events');
  return row.c;
}

// ------------------------------------------------------------------- client --

test('only the app may use the api: a browser, curl or a scanner is turned away', async () => {
  const app = makeApp();
  for (const agent of ['', 'curl/8.4.0', 'Mozilla/5.0 (Windows NT 10.0) Chrome/120', 'python-requests/2.31']) {
    const res = await app.call('GET', '/v1/challenge', { headers: { 'User-Agent': agent } });
    assert.equal(res.status, 403, `agent "${agent}"`);
  }
  assert.equal((await app.call('GET', '/v1/challenge')).status, 200);
});

test('the page for the dev team and the health check do not need the app', async () => {
  const app = makeApp();
  const browser = { 'User-Agent': 'Mozilla/5.0 Chrome/120' };
  assert.equal((await app.call('GET', '/health', { headers: browser })).status, 200);
  assert.equal((await app.call('GET', '/admin', { headers: browser })).status, 200);
  assert.equal((await admin(app, 'GET', '/admin/api/requests', undefined, browser)).status, 200);
});

// ------------------------------------------------------------------ shapes --

test('a very long address and a method the service never uses are refused', async () => {
  const app = makeApp();
  const long = await app.call('GET', `/v1/challenge?${'a'.repeat(FIREWALL.urlMax)}`);
  assert.equal(long.status, 414);
  for (const method of ['PUT', 'PATCH', 'OPTIONS']) {
    const res = await app.call(method, '/v1/requests');
    assert.equal(res.status, 405, method);
    assert.match(res.headers.get('allow'), /GET/);
  }
});

// ------------------------------------------------------------------- volume --

test('one address gets a limited number of api calls a minute, and the next minute is fresh', async () => {
  const app = makeApp();
  const install = newInstall();
  let blockedAt = null;
  for (let i = 1; i <= FIREWALL.apiPerMinute + 5; i++) {
    const res = await list(app, install);
    if (res.status === 429 && blockedAt === null) {
      blockedAt = i;
      assert.equal(res.json.error, 'rate_limited');
      assert.ok(res.json.retryAfter > 0);
      assert.ok(Number(res.headers.get('retry-after')) > 0);
    }
  }
  assert.equal(blockedAt, FIREWALL.apiPerMinute + 1);
  // Somebody else is untouched.
  assert.equal((await list(app, install, OTHER)).status, 200);
  app.clock.t += 61;
  assert.equal((await list(app, install)).status, 200);
});

test('being limited is not a strike: a busy address is not banned', async () => {
  const app = makeApp();
  const install = newInstall();
  for (let i = 0; i < FIREWALL.apiPerMinute * 3; i++) await list(app, install);
  app.clock.t += 61;
  assert.equal((await list(app, install)).status, 200);
});

test('the dev team page has its own, lower limit', async () => {
  const app = makeApp();
  let last;
  for (let i = 0; i <= FIREWALL.adminPerMinute; i++) last = await admin(app, 'GET', '/admin/api/requests');
  assert.equal(last.status, 429);
});

test('a flood of puzzles, status checks and wrong tokens writes nothing to the database', async () => {
  const app = makeApp();
  const install = newInstall();
  for (let i = 0; i < 40; i++) await app.call('GET', '/v1/challenge');
  for (let i = 0; i < 30; i++) await list(app, install);
  for (let i = 0; i < 8; i++) {
    await app.call('GET', '/admin/api/requests', { headers: { Authorization: `Bearer wrong-${i}` } });
  }
  assert.equal(await writtenRows(app), 0);
});

test('a real request still records only what it needs', async () => {
  const app = makeApp();
  assert.equal((await submit(app, newInstall())).status, 201);
  // One accepted request: the address and the whole service are counted, and so is the install.
  assert.ok((await writtenRows(app)) <= 3);
});

// -------------------------------------------------------------------- bans --

test('an address that keeps sending bad requests is banned for a while', async () => {
  const app = makeApp();
  for (let i = 0; i < FIREWALL.strikesToBan; i++) {
    assert.equal((await app.call('GET', `/wp-login-${i}.php`)).status, 404);
  }
  const banned = await app.call('GET', '/health');
  assert.equal(banned.status, 429);
  assert.ok(banned.json.retryAfter > FIREWALL.banSeconds - 5);
  // Somebody else is untouched, and the ban ends.
  assert.equal((await app.call('GET', '/health', { ip: OTHER })).status, 200);
  app.clock.t += FIREWALL.banSeconds + 1;
  assert.equal((await app.call('GET', '/health')).status, 200);
});

test('refused clients count too: a scanner pretending to be a browser is banned quickly', async () => {
  const app = makeApp();
  for (let i = 0; i < FIREWALL.strikesToBan; i++) {
    await app.call('GET', '/v1/challenge', { headers: { 'User-Agent': 'Mozilla/5.0' } });
  }
  // Even with the right agent from then on, the address stays out until the ban ends.
  assert.equal((await app.call('GET', '/v1/challenge')).status, 429);
});

test('strikes fade: a few mistakes spread over time never add up to a ban', async () => {
  const app = makeApp();
  for (let i = 0; i < FIREWALL.strikesToBan * 2; i++) {
    await app.call('GET', `/nope-${i}`);
    app.clock.t += FIREWALL.strikeWindow / 10;
  }
  assert.equal((await app.call('GET', '/health')).status, 200);
});

test('a person who mistypes a few times is not banned', async () => {
  const app = makeApp();
  const install = newInstall();
  for (let i = 0; i < 6; i++) {
    const res = await submit(app, install, { text: 'abc def ghi jkl mno' });
    assert.equal(res.status, 400);
  }
  assert.equal((await submit(app, install, { text: DHIKR })).status, 201);
});

// ---------------------------------------------------------- the platform's limit --

test('Cloudflare\'s rate limit binding is asked, and its no is respected', async () => {
  const keys = [];
  const app = makeApp({
    env: { RL_V1: { limit: async ({ key }) => (keys.push(key), { success: false }) } },
  });
  const res = await app.call('GET', '/v1/challenge');
  assert.equal(res.status, 429);
  assert.equal(keys.length, 1);
  assert.ok(!keys[0].includes('203.0.113.7'), 'the address itself is never handed over');
  // The health check and the dev team page are not behind that binding.
  assert.equal((await app.call('GET', '/health')).status, 200);
});

test('a missing or broken binding never stops the service', async () => {
  const broken = makeApp({
    env: {
      RL_V1: { limit: async () => { throw new Error('down'); } },
      RL_ADMIN: {},
    },
  });
  assert.equal((await broken.call('GET', '/v1/challenge')).status, 200);
  assert.equal((await admin(broken, 'GET', '/admin/api/requests')).status, 200);
  const yes = makeApp({ env: { RL_V1: { limit: async () => ({ success: true }) } } });
  assert.equal((await yes.call('GET', '/v1/challenge')).status, 200);
});

// ------------------------------------------------------------------- bodies --

test('a body streamed without a length is cut off at the limit, not read in full', async () => {
  const app = makeApp();
  let cancelled = false;
  let sent = 0;
  const body = new ReadableStream({
    pull(controller) {
      sent += 1000;
      controller.enqueue(new TextEncoder().encode('x'.repeat(1000)));
      if (sent >= 1_000_000) controller.close();
    },
    cancel() {
      cancelled = true;
    },
  });
  const request = new Request('https://svc.example/v1/requests', {
    method: 'POST',
    headers: {
      'User-Agent': FIREWALL.clientAgent,
      'CF-Connecting-IP': '203.0.113.7',
      'Content-Type': 'application/json',
      Authorization: `Bearer ${newInstall()}`,
    },
    body,
    duplex: 'half',
  });
  const response = await serve(app.firewall, request, app.deps);
  assert.equal(response.status, 413);
  assert.ok(cancelled, 'the rest of the body was never read');
  assert.ok(sent < 20_000, `read ${sent} bytes`);
});

// ------------------------------------------------------------------ limiter --

test('the counter slides: old events stop counting', () => {
  const limiter = createLimiter();
  for (let i = 0; i < 3; i++) assert.ok(limiter.hit('b', 'k', 60, 3, 1000 + i).ok);
  const denied = limiter.hit('b', 'k', 60, 3, 1010);
  assert.equal(denied.ok, false);
  assert.equal(denied.retryAfter, 1000 + 60 - 1010);
  assert.ok(limiter.hit('b', 'k', 60, 3, 1061).ok);
  assert.equal(limiter.count('b', 'k', 60, 1061), 2);
});

test('the counter keeps buckets and keys apart', () => {
  const limiter = createLimiter();
  assert.ok(limiter.hit('a', 'k', 60, 1, 5).ok);
  assert.ok(limiter.hit('b', 'k', 60, 1, 5).ok);
  assert.ok(limiter.hit('a', 'other', 60, 1, 5).ok);
  assert.equal(limiter.hit('a', 'k', 60, 1, 5).ok, false);
});

test('the counter cannot be made to fill memory', () => {
  const limiter = createLimiter();
  for (let i = 0; i < 30_000; i++) limiter.hit('flood', `key-${i}`, 60, 5, 1000);
  assert.ok(limiter.size <= 20_000, `kept ${limiter.size} counters`);
  for (let i = 0; i < 1000; i++) limiter.add('one', 'key', 3600, 1000 + i);
  assert.ok(limiter.count('one', 'key', 3600, 3000) <= 200);
});
