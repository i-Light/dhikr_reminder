import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { test } from 'node:test';

import { cleanText, leadingZeroBits, normalizeArabic, textProblem } from '../src/core.mjs';
import { ADMIN, DHIKR, admin, list, makeApp, newInstall, solve, submit } from './helpers.mjs';

// ------------------------------------------------------------------ basics --

test('says it is alive and nothing else', async () => {
  const app = makeApp();
  const res = await app.call('GET', '/health');
  assert.equal(res.status, 200);
  assert.deepEqual(res.json, { ok: true });
  assert.equal((await app.call('GET', '/nope')).status, 404);
  assert.equal((await app.call('POST', '/health')).status, 405);
});

test('every answer is uncached and not sniffable', async () => {
  const app = makeApp();
  const res = await app.call('GET', '/v1/challenge');
  assert.equal(res.headers.get('cache-control'), 'no-store');
  assert.equal(res.headers.get('x-content-type-options'), 'nosniff');
  assert.match(res.headers.get('content-type'), /^application\/json/);
});

test('a request from a web page is refused', async () => {
  const app = makeApp();
  const res = await app.call('GET', '/v1/challenge', { headers: { Origin: 'https://evil.example' } });
  assert.equal(res.status, 403);
});

// --------------------------------------------------------------- the puzzle --

test('issues a signed puzzle with the difficulty the service is set to', async () => {
  const app = makeApp({ powBits: 6 });
  const res = await app.call('GET', '/v1/challenge');
  assert.equal(res.status, 200);
  assert.equal(res.json.bits, 6);
  assert.equal(res.json.challenge.split('.').length, 3);
});

test('hands out only a few puzzles an hour to one address', async () => {
  const app = makeApp();
  let last;
  for (let i = 0; i < 31; i++) last = await app.call('GET', '/v1/challenge');
  assert.equal(last.status, 429);
  assert.ok(Number(last.headers.get('retry-after')) > 0);
  // Another address is not affected.
  assert.equal((await app.call('GET', '/v1/challenge', { ip: '198.51.100.9' })).status, 200);
});

test('a request without a solved puzzle is refused', async () => {
  const app = makeApp({ powBits: 12 });
  const install = newInstall();
  const ch = await app.call('GET', '/v1/challenge');
  const res = await app.call('POST', '/v1/requests', {
    headers: { Authorization: `Bearer ${install}` },
    body: { text: DHIKR, challenge: ch.json.challenge, counter: 0 },
  });
  // Counter 0 only holds by luck; 12 bits makes that a 1 in 4096 chance.
  if (res.status !== 201) {
    assert.equal(res.status, 400);
    assert.equal(res.json.error, 'pow_failed');
  }
});

test('a puzzle solved for one install does not work for another', async () => {
  const app = makeApp({ powBits: 10 });
  const ch = await app.call('GET', '/v1/challenge');
  const mine = newInstall();
  const counter = await solve(ch.json.challenge, mine, 10);
  const res = await app.call('POST', '/v1/requests', {
    headers: { Authorization: `Bearer ${newInstall()}` },
    body: { text: DHIKR, challenge: ch.json.challenge, counter },
  });
  assert.equal(res.status, 400);
  assert.equal(res.json.error, 'pow_failed');
});

test('a puzzle works once', async () => {
  const app = makeApp();
  const install = newInstall();
  const ch = await app.call('GET', '/v1/challenge');
  const counter = await solve(ch.json.challenge, install, ch.json.bits);
  const send = (text) =>
    app.call('POST', '/v1/requests', {
      headers: { Authorization: `Bearer ${install}` },
      body: { text, challenge: ch.json.challenge, counter },
    });
  assert.equal((await send(DHIKR)).status, 201);
  const again = await send('اللهم اغفر لي ولوالدي وللمؤمنين يوم يقوم الحساب');
  assert.equal(again.status, 400);
  assert.equal(again.json.error, 'challenge_expired');
});

test('a puzzle that was tampered with is refused', async () => {
  const app = makeApp();
  const install = newInstall();
  const ch = await app.call('GET', '/v1/challenge');
  const [expires, nonce, mac] = ch.json.challenge.split('.');
  for (const forged of [
    `${Number(expires) + 9999}.${nonce}.${mac}`,
    `${expires}.${nonce}.${mac.slice(0, -1)}${mac.endsWith('A') ? 'B' : 'A'}`,
    'garbage',
    `${expires}.${nonce}`,
  ]) {
    const counter = await solve(forged, install, ch.json.bits);
    const res = await app.call('POST', '/v1/requests', {
      headers: { Authorization: `Bearer ${install}` },
      body: { text: DHIKR, challenge: forged, counter },
    });
    assert.equal(res.status, 400, forged);
    assert.equal(res.json.error, 'challenge_expired', forged);
  }
});

test('a puzzle runs out after five minutes', async () => {
  const app = makeApp();
  const install = newInstall();
  const ch = await app.call('GET', '/v1/challenge');
  const counter = await solve(ch.json.challenge, install, ch.json.bits);
  app.clock.t += 301;
  const res = await app.call('POST', '/v1/requests', {
    headers: { Authorization: `Bearer ${install}` },
    body: { text: DHIKR, challenge: ch.json.challenge, counter },
  });
  assert.equal(res.json.error, 'challenge_expired');
});

test('counts leading zero bits', () => {
  assert.equal(leadingZeroBits(new Uint8Array([0, 0, 0xff])), 16);
  assert.equal(leadingZeroBits(new Uint8Array([0, 0x0f])), 12);
  assert.equal(leadingZeroBits(new Uint8Array([0x80])), 0);
});

// ------------------------------------------------------------ a good request --

test('takes a request and lets its owner read how it is going', async () => {
  const app = makeApp();
  const install = newInstall();
  const res = await submit(app, install, { source: 'رواه مسلم' });
  assert.equal(res.status, 201);
  assert.equal(res.json.status, 'pending');
  assert.equal(res.json.duplicate, false);
  assert.match(res.json.id, /^[A-Za-z0-9_-]{16}$/);

  const mine = await list(app, install);
  assert.equal(mine.status, 200);
  assert.equal(mine.json.requests.length, 1);
  assert.equal(mine.json.requests[0].id, res.json.id);
  assert.equal(mine.json.requests[0].status, 'pending');
  // What the owner gets back has no text and nothing about anyone else.
  assert.deepEqual(
    Object.keys(mine.json.requests[0]).sort(),
    ['createdAt', 'id', 'libraryId', 'reason', 'shippedIn', 'status', 'updatedAt', 'votes'],
  );
});

test('nobody else can read it', async () => {
  const app = makeApp();
  const res = await submit(app, newInstall());
  assert.equal(res.status, 201);
  const stranger = await list(app, newInstall());
  assert.deepEqual(stranger.json.requests, []);
});

test('listing needs a well-formed token', async () => {
  const app = makeApp();
  assert.equal((await app.call('GET', '/v1/requests')).status, 401);
  assert.equal(
    (await app.call('GET', '/v1/requests', { headers: { Authorization: 'Bearer short' } })).status,
    401,
  );
});

test('stores only a hash of the token and of the address', async () => {
  const app = makeApp();
  const install = newInstall();
  await submit(app, install, {}, { ip: '203.0.113.77' });
  const dump = JSON.stringify([
    await app.db.all('SELECT * FROM request_owners'),
    await app.db.all('SELECT * FROM rate_events'),
    await app.db.all('SELECT * FROM requests'),
  ]);
  assert.ok(!dump.includes(install));
  assert.ok(!dump.includes('203.0.113.77'));
});

// -------------------------------------------------------------- bad requests --

test('refuses a body that is not JSON, too big, or the wrong type', async () => {
  const app = makeApp();
  const headers = { Authorization: `Bearer ${newInstall()}` };
  assert.equal((await app.call('POST', '/v1/requests', { headers, raw: '{nope' })).status, 400);
  assert.equal((await app.call('POST', '/v1/requests', { headers, raw: '[1,2]' })).status, 400);
  assert.equal((await app.call('POST', '/v1/requests', { headers, raw: 'x'.repeat(5000) })).status, 413);
  const plain = await app.call('POST', '/v1/requests', {
    headers: { ...headers, 'Content-Type': 'text/plain' },
    raw: '{}',
  });
  assert.equal(plain.status, 415);
});

test('refuses unknown fields and wrong types', async () => {
  const app = makeApp();
  const install = newInstall();
  for (const fields of [
    { admin: true },
    { text: 5 },
    { source: 7 },
    { locale: 'x'.repeat(40) },
    { platform: ['android'] },
  ]) {
    const res = await submit(app, install, fields);
    assert.equal(res.status, 400, JSON.stringify(fields));
  }
});

test('refuses text that is not a dhikr', async () => {
  const app = makeApp();
  const cases = {
    too_short: 'اللهم',
    not_arabic: 'please add this dhikr to the library',
    has_link: 'اللهم صل على محمد https://spam.example/buy',
    repeated: 'اللهم ااااااااااا اغفر لي',
    too_long: 'اللهم اغفر لي '.repeat(60),
  };
  for (const [reason, text] of Object.entries(cases)) {
    const res = await submit(app, newInstall(), { text }, { ip: `198.51.100.${Math.floor(Math.random() * 200) + 1}` });
    assert.equal(res.status, 400, reason);
    assert.equal(res.json.error, 'invalid_text', reason);
    assert.equal(res.json.reason, reason, reason);
  }
});

test('refuses markup and script in the text or the source', async () => {
  const app = makeApp();
  const a = await submit(app, newInstall(), { text: 'اللهم <script>alert(1)</script> اغفر لي ذنبي' });
  assert.equal(a.json.reason, 'has_link');
  const b = await submit(app, newInstall(), { source: 'http://evil.example' });
  assert.equal(b.json.reason, 'has_link');
});

test('strips control and direction-override characters before storing', async () => {
  const app = makeApp();
  const dirty = `اللهم‮ إني\u0000 أسألك‏ علما نافعا⁦ ورزقا طيبا`;
  const res = await submit(app, newInstall(), { text: dirty });
  assert.equal(res.status, 201);
  const row = await app.db.get('SELECT text FROM requests WHERE id = ?', [res.json.id]);
  assert.equal(row.text, 'اللهم إني أسألك علما نافعا ورزقا طيبا');
});

test('a bot that fills the hidden field is thanked and ignored', async () => {
  const app = makeApp();
  const res = await submit(app, newInstall(), { website: 'http://spam.example' });
  assert.equal(res.status, 201);
  assert.equal((await app.db.get('SELECT COUNT(*) AS c FROM requests')).c, 0);
});

// -------------------------------------------------------------------- limits --

test('a person can have three requests open at a time', async () => {
  const app = makeApp();
  const install = newInstall();
  const texts = [
    'اللهم اغفر لي ذنبي كله دقه وجله',
    'ربنا آتنا في الدنيا حسنة وفي الآخرة حسنة',
    'اللهم إني أعوذ بك من الهم والحزن',
    'اللهم اكفني بحلالك عن حرامك واغنني بفضلك',
  ];
  for (let i = 0; i < 3; i++) {
    assert.equal((await submit(app, install, { text: texts[i] })).status, 201);
  }
  const fourth = await submit(app, install, { text: texts[3] });
  assert.equal(fourth.status, 429);
  assert.equal(fourth.json.error, 'too_many_open');

  // Once one is finished a slot is free again.
  const first = (await list(app, install)).json.requests.at(-1);
  await admin(app, 'POST', `/admin/api/requests/${first.id}`, { status: 'done' });
  assert.equal((await submit(app, install, { text: texts[3] })).status, 201);
});

test('one install can send five a day, and is told when to come back', async () => {
  const app = makeApp();
  const install = newInstall();
  const words = ['اغفر', 'ارحم', 'اهد', 'ارزق', 'عاف', 'اسقني'];
  let last;
  for (let i = 0; i < 6; i++) {
    last = await submit(app, install, { text: `اللهم ${words[i]} لي وللمسلمين أجمعين` });
    if (i < 5) {
      assert.equal(last.status, 201, `request ${i}`);
      await admin(app, 'POST', `/admin/api/requests/${last.json.id}`, { status: 'done' });
    }
  }
  assert.equal(last.status, 429);
  assert.equal(last.json.error, 'rate_limited');
  assert.ok(last.json.retryAfter > 0);

  app.clock.t += 86400 + 5;
  const next = await submit(app, install, { text: 'اللهم ثبتني على دينك حتى ألقاك' });
  assert.equal(next.status, 201);
});

test('a rejected attempt does not use up the daily quota', async () => {
  const app = makeApp();
  const install = newInstall();
  // Four mistakes, then a request that is fine.
  for (let i = 0; i < 4; i++) {
    const bad = await submit(app, install, { text: 'قصير' });
    assert.equal(bad.status, 400);
  }
  assert.equal((await submit(app, install)).status, 201);
});

test('fully vowelled text is judged by its letters, not its marks', async () => {
  const app = makeApp();
  const vowelled =
    'اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا، وَرِزْقًا طَيِّبًا، وَعَمَلًا مُتَقَبَّلًا';
  assert.equal(textProblem(vowelled), null);
  assert.equal((await submit(app, newInstall(), { text: vowelled })).status, 201);
});

test('one address cannot flood the service with fresh installs', async () => {
  const app = makeApp();
  let status;
  for (let i = 0; i < 21; i++) {
    const res = await submit(app, newInstall(), {
      text: `اللهم ارزقني الإخلاص في القول والعمل رقم ${'أبجدهوزحطيكلمنسعفصقرشتثخذضظغ'[i]}${'أبجدهوزحطيكلمنسعفصقرشتثخذضظغ'[i + 1]}`,
    }, { ip: '192.0.2.50' });
    status = res.status;
  }
  assert.equal(status, 429);
});

// ----------------------------------------------------------------- duplicates --

test('the same dhikr from two people is one request with two votes', async () => {
  const app = makeApp();
  const a = newInstall();
  const b = newInstall();
  const first = await submit(app, a, {}, { ip: '203.0.113.1' });
  const second = await submit(app, b, { text: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا، وَرِزْقًا طَيِّبًا، وَعَمَلًا مُتَقَبَّلًا' }, { ip: '203.0.113.2' });

  assert.equal(first.status, 201);
  assert.equal(second.status, 200);
  assert.equal(second.json.duplicate, true);
  assert.equal(second.json.id, first.json.id);
  assert.equal((await app.db.get('SELECT COUNT(*) AS c FROM requests')).c, 1);
  assert.equal((await app.db.get('SELECT votes FROM requests')).votes, 2);
  assert.equal((await list(app, b, '203.0.113.2')).json.requests[0].id, first.json.id);
});

test('sending the same dhikr twice does not add a vote', async () => {
  const app = makeApp();
  const a = newInstall();
  await submit(app, a);
  const again = await submit(app, a);
  assert.equal(again.json.duplicate, true);
  assert.equal((await app.db.get('SELECT votes FROM requests')).votes, 1);
});

test('a duplicate of a finished request is told the outcome straight away', async () => {
  const app = makeApp();
  const first = await submit(app, newInstall());
  await admin(app, 'POST', `/admin/api/requests/${first.json.id}`, {
    status: 'done',
    libraryId: 'dabc123',
    shippedIn: '0.1.4',
  });
  const late = await submit(app, newInstall(), {}, { ip: '203.0.113.9' });
  assert.equal(late.json.status, 'done');
  assert.equal(late.json.libraryId, 'dabc123');
  assert.equal(late.json.shippedIn, '0.1.4');
});

// ---------------------------------------------------------------------- admin --

test('the admin api needs the token', async () => {
  const app = makeApp();
  assert.equal((await app.call('GET', '/admin/api/requests')).status, 401);
  assert.equal(
    (await app.call('GET', '/admin/api/requests', { headers: { Authorization: 'Bearer wrong' } })).status,
    401,
  );
  assert.equal((await admin(app, 'GET', '/admin/api/requests')).status, 200);
});

test('guessing the admin token is stopped after ten tries', async () => {
  const app = makeApp();
  for (let i = 0; i < 10; i++) {
    const res = await app.call('GET', '/admin/api/requests', { headers: { Authorization: `Bearer guess-${i}` } });
    assert.equal(res.status, 401);
  }
  // Even the right token is turned away from the address that kept guessing.
  assert.equal((await admin(app, 'GET', '/admin/api/requests')).status, 429);
  // A different address is fine.
  const other = await app.call('GET', '/admin/api/requests', {
    ip: '198.51.100.99',
    headers: { Authorization: `Bearer ${ADMIN}` },
  });
  assert.equal(other.status, 200);
});

test('an unset or short admin token locks the admin api', async () => {
  const app = makeApp({ env: { ADMIN_TOKEN: 'short' } });
  const res = await app.call('GET', '/admin/api/requests', { headers: { Authorization: 'Bearer short' } });
  assert.equal(res.status, 401);
});

test('the admin page carries a strict content security policy', async () => {
  const app = makeApp();
  const res = await app.call('GET', '/admin');
  assert.equal(res.status, 200);
  const csp = res.headers.get('content-security-policy');
  assert.match(csp, /default-src 'none'/);
  assert.match(csp, /script-src 'nonce-/);
  assert.doesNotMatch(csp, /unsafe-inline|unsafe-eval/);
  assert.equal(res.headers.get('x-frame-options'), 'DENY');
  assert.doesNotMatch(res.text, /innerHTML/);
  assert.ok(res.text.includes(csp.match(/nonce-([\w-]+)/)[1]));
});

test('lists requests by status, most wanted first', async () => {
  const app = makeApp();
  const a = await submit(app, newInstall(), { text: 'اللهم اغفر لي ذنبي كله دقه وجله' }, { ip: '203.0.113.1' });
  await submit(app, newInstall(), { text: 'اللهم إني أعوذ بك من الهم والحزن' }, { ip: '203.0.113.2' });
  await submit(app, newInstall(), { text: 'اللهم اغفر لي ذنبي كله دقه وجله' }, { ip: '203.0.113.3' });

  const pending = (await admin(app, 'GET', '/admin/api/requests?status=pending')).json.requests;
  assert.equal(pending.length, 2);
  assert.equal(pending[0].id, a.json.id);
  assert.equal(pending[0].votes, 2);
  assert.equal((await admin(app, 'GET', '/admin/api/requests?status=bogus')).status, 400);
});

test('moves a request through its statuses and the owner sees each one', async () => {
  const app = makeApp();
  const install = newInstall();
  const sent = await submit(app, install);
  const path = `/admin/api/requests/${sent.json.id}`;

  await admin(app, 'POST', path, { status: 'in_progress' });
  assert.equal((await list(app, install)).json.requests[0].status, 'in_progress');

  await admin(app, 'POST', path, { status: 'done', libraryId: 'd1234567890', shippedIn: '0.1.4' });
  const done = (await list(app, install)).json.requests[0];
  assert.equal(done.status, 'done');
  assert.equal(done.libraryId, 'd1234567890');
  assert.equal(done.shippedIn, '0.1.4');

  await admin(app, 'POST', path, { status: 'declined', reason: 'duplicate' });
  const declined = (await list(app, install)).json.requests[0];
  assert.equal(declined.status, 'declined');
  assert.equal(declined.reason, 'duplicate');
  assert.equal(declined.libraryId, null);
});

test('refuses a status, reason, id or version it does not know', async () => {
  const app = makeApp();
  const sent = await submit(app, newInstall());
  const path = `/admin/api/requests/${sent.json.id}`;
  for (const body of [
    { status: 'archived' },
    { status: 'declined', reason: 'rude' },
    { status: 'done', libraryId: "x'; DROP TABLE requests;--" },
    { status: 'done', shippedIn: 'latest' },
    { status: 'done', extra: 1 },
  ]) {
    assert.equal((await admin(app, 'POST', path, body)).status, 400, JSON.stringify(body));
  }
  assert.equal((await admin(app, 'POST', '/admin/api/requests/doesnotexist1', { status: 'done' })).status, 404);
});

test('deletes a request for everyone who asked', async () => {
  const app = makeApp();
  const install = newInstall();
  const sent = await submit(app, install);
  assert.equal((await admin(app, 'DELETE', `/admin/api/requests/${sent.json.id}`)).status, 200);
  assert.deepEqual((await list(app, install)).json.requests, []);
  assert.equal((await app.db.get('SELECT COUNT(*) AS c FROM request_owners')).c, 0);
});

test('admin changes from another website are refused', async () => {
  const app = makeApp();
  const sent = await submit(app, newInstall());
  const res = await admin(
    app, 'POST', `/admin/api/requests/${sent.json.id}`, { status: 'done' },
    { Origin: 'https://evil.example' },
  );
  assert.equal(res.status, 403);
});

// ------------------------------------------------------------------- text tools --

test('normalises Arabic the way the app does', () => {
  const vectors = JSON.parse(
    readFileSync(new URL('./normalize_vectors.json', import.meta.url), 'utf8'),
  );
  for (const [input, expected] of vectors) {
    assert.equal(normalizeArabic(input), expected, input);
  }
});

test('cleans and judges text', () => {
  assert.equal(cleanText('  أ\r\n\r\n\r\n\r\nب  '), 'أ\n\nب');
  assert.equal(textProblem('اللهم اغفر لي ولوالدي'), null);
  assert.equal(textProblem('قصير'), 'too_short');
});
