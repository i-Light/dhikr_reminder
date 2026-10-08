// The dhikr request service: everything it does, with no Cloudflare in it.
//
// `handle(request, deps)` answers one HTTP request. `deps` is
//   { db, env, now, randomBytes }
// where `db` is the tiny interface in db_d1.mjs / db_node.mjs, `env` holds the
// secrets (ADMIN_TOKEN, CHALLENGE_SECRET, IP_SALT, optional POW_BITS), `now()`
// is unix seconds and `randomBytes(n)` returns n random bytes. Passing them in
// is what lets the tests run the real code against an in-memory database.
//
// What it defends against, in the order a request meets it:
//   * browsers: a request that carries an Origin header is refused, the app is
//     not a web page and a page has no business calling this;
//   * size: bodies over 4 KB are refused before they are parsed;
//   * shape: the JSON must be exactly the documented fields, strictly typed;
//   * cost: a request has to carry the solution to a proof-of-work puzzle the
//     server issued a few minutes ago (stateless, HMAC signed, single use), so
//     spamming it costs the sender CPU for every single request;
//   * volume: sliding-window limits per install, per network address (stored
//     only as a salted daily hash), and one global daily cap;
//   * content: the text is cleaned of control and bidi characters, must be
//     Arabic, and may not carry links, markup or runs of one letter;
//   * duplicates: the same dhikr sent again, by anyone, is folded into the
//     first request as an extra vote instead of a new row;
//   * leaks: the install token is a 256-bit secret of which only the SHA-256 is
//     stored, request ids are random, and a person can only read their own.
//
// firewall.mjs stands in front of all this and turns requests away before any
// of it runs. The counters that need no exactness (puzzles, status polls, wrong
// admin tokens) are kept in memory through `deps.cheap` (limiter.mjs), so a
// flood of them cannot use up the database's free daily writes.

import { createLimiter } from './limiter.mjs';

const encoder = new TextEncoder();

export const LIMITS = Object.freeze({
  textMin: 8,
  textMax: 600,
  sourceMax: 120,
  bodyMax: 4096,
  maxLines: 12,
  openPerInstall: 3,
  submitPerInstallPerDay: 5,
  submitPerIpPerDay: 20,
  submitGlobalPerDay: 300,
  challengePerIpPerHour: 30,
  statusPerInstallPerHour: 120,
  statusPerIpPerHour: 300,
  adminFailuresPerIpPerHour: 10,
  challengeTtlSeconds: 300,
  defaultPowBits: 16,
  listMax: 50,
  adminListMax: 200,
});

export const STATUSES = ['pending', 'in_progress', 'done', 'declined'];
export const REASONS = ['duplicate', 'unclear', 'not_suitable', 'other'];

const HOUR = 3600;
const DAY = 86400;

// ---------------------------------------------------------------- crypto ----

export function toBase64Url(bytes) {
  let binary = '';
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

export async function sha256Bytes(text) {
  return new Uint8Array(await crypto.subtle.digest('SHA-256', encoder.encode(text)));
}

export async function sha256Hex(text) {
  const bytes = await sha256Bytes(text);
  return [...bytes].map((b) => b.toString(16).padStart(2, '0')).join('');
}

async function hmac(secret, message) {
  const key = await crypto.subtle.importKey(
    'raw',
    encoder.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  return new Uint8Array(await crypto.subtle.sign('HMAC', key, encoder.encode(message)));
}

/** Compares two strings without stopping at the first difference. */
export async function safeEqual(a, b) {
  const [x, y] = await Promise.all([sha256Bytes(String(a)), sha256Bytes(String(b))]);
  let diff = 0;
  for (let i = 0; i < x.length; i++) diff |= x[i] ^ y[i];
  return diff === 0;
}

export function leadingZeroBits(bytes) {
  let bits = 0;
  for (const byte of bytes) {
    if (byte === 0) {
      bits += 8;
      continue;
    }
    bits += Math.clz32(byte) - 24;
    break;
  }
  return bits;
}

// ------------------------------------------------------------------ text ----

const TASHKEEL = /[\u{0610}-\u{061A}\u{064B}-\u{065F}\u{0670}\u{06D6}-\u{06DC}\u{06DF}-\u{06E8}\u{06EA}-\u{06ED}]/gu;
const INVISIBLE = /[\u{0640}\u{200B}-\u{200F}\u{202A}-\u{202E}\u{2066}-\u{2069}\u{FEFF}]/gu;
const ALEFS = /[\u{0623}\u{0625}\u{0622}\u{0671}]/gu;
const INDIC_DIGITS = /[\u{0660}-\u{0669}\u{06F0}-\u{06F9}]/gu;
const CONTROLS = /[\u{0000}-\u{0009}\u{000B}-\u{001F}\u{007F}-\u{009F}\u{2028}\u{2029}]/gu;

/** The same folding the app does (lib/features/library/domain/arabic_text.dart). */
export function normalizeArabic(text) {
  return String(text)
    .replace(TASHKEEL, '')
    .replace(INVISIBLE, '')
    .replace(ALEFS, '\u{0627}')
    .replace(/\u{0649}/gu, '\u{064A}')
    .replace(/\u{0629}/gu, '\u{0647}')
    .replace(/\u{0624}/gu, '\u{0648}')
    .replace(/\u{0626}/gu, '\u{064A}')
    .replace(INDIC_DIGITS, (d) => {
      const code = d.codePointAt(0);
      return String.fromCharCode(0x30 + code - (code >= 0x06f0 ? 0x06f0 : 0x0660));
    })
    .toLowerCase()
    .replace(/[^\p{L}\p{N}]+/gu, ' ')
    .trim();
}

export function arabicLetterCount(text) {
  let n = 0;
  for (const ch of text) {
    const c = ch.codePointAt(0);
    if ((c >= 0x0621 && c <= 0x064a) || (c >= 0x0671 && c <= 0x06d3)) n++;
  }
  return n;
}

export function letterCount(text) {
  return (text.match(/\p{L}/gu) ?? []).length;
}

/** Control, bidi and zero-width characters out, spacing tidied, line breaks kept. */
export function cleanText(raw) {
  return String(raw)
    .replace(/\r\n?/g, '\n')
    .replace(CONTROLS, '')
    .replace(INVISIBLE, '')
    .replace(/[ \t]+/g, ' ')
    .replace(/ ?\n ?/g, '\n')
    .replace(/\n{3,}/g, '\n\n')
    .trim();
}

/** Why [text] cannot be a dhikr request, or null when it can. */
export function textProblem(text) {
  // Lengths are of the words, not of the vowel marks on them, so a fully
  // vowelled dhikr is not held to a shorter limit than a bare one.
  const bare = text.replace(TASHKEEL, '');
  if (bare.length < LIMITS.textMin) return 'too_short';
  if (bare.length > LIMITS.textMax || text.split('\n').length > LIMITS.maxLines) return 'too_long';
  if (/[<>`]|https?:|www\.|\w@\w|:\/\/|\{\{|javascript:/iu.test(text)) return 'has_link';
  const arabic = arabicLetterCount(bare);
  if (arabic < 6 || arabic / Math.max(1, letterCount(bare)) < 0.6) return 'not_arabic';
  if (/(.)\1{5,}/u.test(bare.replace(/\s+/g, ''))) return 'repeated';
  const symbols = [...bare].filter((c) => !/[\p{L}\p{N}\p{M}\s]/u.test(c)).length;
  if (symbols / bare.length > 0.4) return 'repeated';
  return null;
}

// -------------------------------------------------------------- responses ---

const BASE_HEADERS = {
  'Cache-Control': 'no-store',
  'X-Content-Type-Options': 'nosniff',
  'Referrer-Policy': 'no-referrer',
  'Cross-Origin-Resource-Policy': 'same-origin',
};

function json(status, body, extra = {}) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...BASE_HEADERS, 'Content-Type': 'application/json; charset=utf-8', ...extra },
  });
}

export function fail(status, error, extra = {}, headers = {}) {
  return json(status, { error, ...extra }, headers);
}

/** The answer to someone who has asked too often. The app shows its own wording. */
export function tooMany(retryAfter) {
  return fail(429, 'rate_limited', { retryAfter }, { 'Retry-After': String(retryAfter) });
}

/** The in-memory counters: the Worker passes a long-lived one, tests get their own. */
function cheapOf(deps) {
  return deps.cheap ?? (deps.cheap = createLimiter());
}

// -------------------------------------------------------------- rate limit --

/**
 * Counts one event against `bucket`/`key` and says whether it is allowed.
 * Sliding window: events older than `window` seconds stop counting.
 */
async function hit(db, bucket, key, window, max, now) {
  const since = now - window;
  const row = await db.get(
    'SELECT COUNT(*) AS c, MIN(at) AS oldest FROM rate_events WHERE bucket = ? AND key = ? AND at > ?',
    [bucket, key, since],
  );
  if ((row?.c ?? 0) >= max) {
    return { ok: false, retryAfter: Math.max(1, (row.oldest ?? now) + window - now) };
  }
  await db.run('INSERT INTO rate_events (bucket, key, at) VALUES (?, ?, ?)', [bucket, key, now]);
  return { ok: true };
}

async function limited(db, checks, now) {
  for (const [bucket, key, window, max] of checks) {
    const result = await hit(db, bucket, key, window, max, now);
    if (!result.ok) return tooMany(result.retryAfter);
  }
  return null;
}

async function pruneOccasionally(db, now, randomBytes) {
  if (randomBytes(1)[0] % 16 !== 0) return;
  await db.run('DELETE FROM rate_events WHERE at < ?', [now - 2 * DAY]);
  await db.run('DELETE FROM used_challenges WHERE expires_at < ?', [now]);
}

const ipKeys = new WeakMap();

/** A salted hash of the caller's address that changes every day; worked out once per request. */
export async function ipKey(request, env, now) {
  const known = ipKeys.get(request);
  if (known) return known;
  const ip = request.headers.get('CF-Connecting-IP') ?? request.headers.get('X-Real-IP') ?? 'local';
  const salt = toBase64Url(await hmac(env.IP_SALT, String(Math.floor(now / DAY))));
  const key = (await sha256Hex(`${salt}:${ip}`)).slice(0, 32);
  ipKeys.set(request, key);
  return key;
}

// ------------------------------------------------------ proof of work -------

export function powBits(env) {
  const n = Number.parseInt(env.POW_BITS ?? '', 10);
  return Number.isInteger(n) && n >= 0 && n <= 28 ? n : LIMITS.defaultPowBits;
}

async function issueChallenge(env, now, randomBytes) {
  const expires = now + LIMITS.challengeTtlSeconds;
  const nonce = toBase64Url(randomBytes(12));
  const signed = `${expires}.${nonce}`;
  const mac = toBase64Url(await hmac(env.CHALLENGE_SECRET, signed)).slice(0, 22);
  return { challenge: `${signed}.${mac}`, expires };
}

/** The challenge's nonce when it is ours and still fresh, otherwise null. */
async function openChallenge(env, challenge, now) {
  if (typeof challenge !== 'string' || challenge.length > 120) return null;
  const parts = challenge.split('.');
  if (parts.length !== 3) return null;
  const [expires, nonce, mac] = parts;
  if (!/^\d{1,12}$/.test(expires) || !/^[A-Za-z0-9_-]{16}$/.test(nonce)) return null;
  if (Number(expires) < now) return null;
  const expected = toBase64Url(await hmac(env.CHALLENGE_SECRET, `${expires}.${nonce}`)).slice(0, 22);
  if (!(await safeEqual(expected, mac))) return null;
  return { nonce, expires: Number(expires) };
}

export async function powHolds(challenge, install, counter, bits) {
  const digest = await sha256Bytes(`${challenge}:${install}:${counter}`);
  return leadingZeroBits(digest) >= bits;
}

// ---------------------------------------------------------------- parsing ---

const TOKEN = /^[A-Za-z0-9_-]{43}$/;

function bearer(request) {
  const header = request.headers.get('Authorization') ?? '';
  return header.startsWith('Bearer ') ? header.slice(7).trim() : '';
}

/**
 * The body as text, or null as soon as it passes `max` bytes. It stops reading
 * there, so a body streamed without a length cannot be made to fill memory.
 */
async function readCapped(request, max) {
  if (!request.body) return '';
  const reader = request.body.getReader();
  const chunks = [];
  let size = 0;
  for (;;) {
    const { done, value } = await reader.read();
    if (done) break;
    size += value.byteLength;
    if (size > max) {
      await reader.cancel().catch(() => {});
      return null;
    }
    chunks.push(value);
  }
  const all = new Uint8Array(size);
  let at = 0;
  for (const chunk of chunks) {
    all.set(chunk, at);
    at += chunk.byteLength;
  }
  return new TextDecoder().decode(all);
}

async function readJson(request) {
  const type = request.headers.get('Content-Type') ?? '';
  if (!type.toLowerCase().startsWith('application/json')) return { error: fail(415, 'bad_request') };
  const declared = Number(request.headers.get('Content-Length') ?? '0');
  if (!Number.isFinite(declared) || declared > LIMITS.bodyMax) {
    return { error: fail(413, 'too_large') };
  }
  const raw = await readCapped(request, LIMITS.bodyMax);
  if (raw === null) return { error: fail(413, 'too_large') };
  try {
    const value = JSON.parse(raw);
    if (value === null || typeof value !== 'object' || Array.isArray(value)) throw new Error('shape');
    return { value };
  } catch {
    return { error: fail(400, 'bad_request') };
  }
}

const SUBMIT_FIELDS = new Set([
  'text', 'source', 'challenge', 'counter', 'locale', 'platform', 'appVersion', 'website',
]);

function shortString(value, max) {
  return typeof value === 'string' && value.length <= max;
}

// -------------------------------------------------------------- handlers ----

async function handleChallenge(request, deps) {
  const { env, now, randomBytes } = deps;
  const t = now();
  // A puzzle costs the server nothing to make and is remembered nowhere, so
  // counting them needs no database write.
  const gate = cheapOf(deps).hit(
    'challenge',
    await ipKey(request, env, t),
    HOUR,
    LIMITS.challengePerIpPerHour,
    t,
  );
  if (!gate.ok) return tooMany(gate.retryAfter);
  const { challenge, expires } = await issueChallenge(env, t, randomBytes);
  return json(200, { challenge, bits: powBits(env), expiresAt: expires });
}

function publicRow(r) {
  return {
    status: r.status,
    reason: r.reason ?? null,
    libraryId: r.library_id ?? null,
    shippedIn: r.shipped_in ?? null,
    votes: r.votes,
  };
}

async function handleSubmit(request, deps) {
  const { db, env, now, randomBytes } = deps;
  const t = now();

  const install = bearer(request);
  if (!TOKEN.test(install)) return fail(401, 'unauthorized');

  const read = await readJson(request);
  if (read.error) return read.error;
  const body = read.value;
  for (const key of Object.keys(body)) {
    if (!SUBMIT_FIELDS.has(key)) return fail(400, 'bad_request');
  }
  if (
    typeof body.text !== 'string' ||
    !shortString(body.challenge, 120) ||
    !Number.isInteger(body.counter) ||
    body.counter < 0 ||
    body.counter > 2 ** 40 ||
    (body.source !== undefined && body.source !== null && !shortString(body.source, 400)) ||
    (body.locale !== undefined && !shortString(body.locale, 12)) ||
    (body.platform !== undefined && !shortString(body.platform, 16)) ||
    (body.appVersion !== undefined && !shortString(body.appVersion, 24)) ||
    (body.website !== undefined && typeof body.website !== 'string')
  ) {
    return fail(400, 'bad_request');
  }
  if (body.text.length > LIMITS.textMax * 4) return fail(400, 'invalid_text', { reason: 'too_long' });

  // A bot that fills in every field gets a believable answer and nothing else.
  if (body.website) {
    return json(201, { id: toBase64Url(randomBytes(12)), status: 'pending', duplicate: false });
  }

  // The cheapest checks that need no database go first: the puzzle.
  const opened = await openChallenge(env, body.challenge, t);
  if (!opened) return fail(400, 'challenge_expired');
  if (!(await powHolds(body.challenge, install, body.counter, powBits(env)))) {
    return fail(400, 'pow_failed');
  }

  const installHash = await sha256Hex(install);
  const ip = await ipKey(request, env, t);
  // Every attempt that solved a puzzle counts against the address and the whole
  // service. An install's own daily quota only counts requests that were
  // accepted, so an honest person who mistyped is not locked out for a day.
  const blocked = await limited(
    db,
    [
      ['submit-ip', ip, DAY, LIMITS.submitPerIpPerDay],
      ['submit-global', 'all', DAY, LIMITS.submitGlobalPerDay],
    ],
    t,
  );
  if (blocked) return blocked;
  const sentToday = await db.get(
    'SELECT COUNT(*) AS c, MIN(at) AS oldest FROM rate_events WHERE bucket = ? AND key = ? AND at > ?',
    ['submit-install', installHash, t - DAY],
  );
  if ((sentToday?.c ?? 0) >= LIMITS.submitPerInstallPerDay) {
    const retryAfter = Math.max(1, (sentToday.oldest ?? t) + DAY - t);
    return fail(429, 'rate_limited', { retryAfter }, { 'Retry-After': String(retryAfter) });
  }

  // The puzzle can be solved once. It is recorded before anything is written.
  const fresh = await db.run(
    'INSERT OR IGNORE INTO used_challenges (nonce, expires_at) VALUES (?, ?)',
    [opened.nonce, opened.expires],
  );
  if (fresh.changes !== 1) return fail(400, 'challenge_expired');

  const text = cleanText(body.text);
  const problem = textProblem(text);
  if (problem) return fail(400, 'invalid_text', { reason: problem });
  const source = body.source
    ? cleanText(body.source).replace(/\n+/g, ' ').slice(0, LIMITS.sourceMax)
    : null;
  if (source && /[<>`]|https?:|www\./iu.test(source)) {
    return fail(400, 'invalid_text', { reason: 'has_link' });
  }

  const open = await db.get(
    `SELECT COUNT(*) AS c FROM request_owners o
       JOIN requests r ON r.id = o.request_id
      WHERE o.install_hash = ? AND r.status IN ('pending', 'in_progress')`,
    [installHash],
  );
  if ((open?.c ?? 0) >= LIMITS.openPerInstall) return fail(429, 'too_many_open');

  const textHash = await sha256Hex(normalizeArabic(text));
  const id = toBase64Url(randomBytes(12));
  const created = await db.run(
    `INSERT OR IGNORE INTO requests
       (id, text, source, text_hash, status, votes, locale, platform, app_version, created_at, updated_at)
     VALUES (?, ?, ?, ?, 'pending', 1, ?, ?, ?, ?, ?)`,
    [
      id, text, source, textHash,
      body.locale ?? null, body.platform ?? null, body.appVersion ?? null, t, t,
    ],
  );

  let requestId = id;
  let duplicate = false;
  if (created.changes !== 1) {
    duplicate = true;
    const existing = await db.get('SELECT id FROM requests WHERE text_hash = ?', [textHash]);
    requestId = existing.id;
    const joined = await db.run(
      'INSERT OR IGNORE INTO request_owners (request_id, install_hash, created_at) VALUES (?, ?, ?)',
      [requestId, installHash, t],
    );
    if (joined.changes === 1) {
      await db.run('UPDATE requests SET votes = votes + 1 WHERE id = ?', [requestId]);
    }
  } else {
    await db.run(
      'INSERT INTO request_owners (request_id, install_hash, created_at) VALUES (?, ?, ?)',
      [requestId, installHash, t],
    );
  }

  await db.run('INSERT INTO rate_events (bucket, key, at) VALUES (?, ?, ?)', [
    'submit-install', installHash, t,
  ]);
  await pruneOccasionally(db, t, randomBytes);
  const row = await db.get(
    'SELECT status, reason, library_id, shipped_in, votes FROM requests WHERE id = ?',
    [requestId],
  );
  return json(duplicate ? 200 : 201, { id: requestId, ...publicRow(row), duplicate });
}

async function handleList(request, deps) {
  const { db, env, now } = deps;
  const t = now();
  const install = bearer(request);
  if (!TOKEN.test(install)) return fail(401, 'unauthorized');
  const installHash = await sha256Hex(install);

  // Looking at one's own requests changes nothing, so its limits live in memory.
  const cheap = cheapOf(deps);
  const own = cheap.hit('status-install', installHash, HOUR, LIMITS.statusPerInstallPerHour, t);
  if (!own.ok) return tooMany(own.retryAfter);
  const shared = cheap.hit('status-ip', await ipKey(request, env, t), HOUR, LIMITS.statusPerIpPerHour, t);
  if (!shared.ok) return tooMany(shared.retryAfter);

  const rows = await db.all(
    `SELECT r.id, r.status, r.reason, r.library_id, r.shipped_in, r.votes, r.created_at, r.updated_at
       FROM request_owners o JOIN requests r ON r.id = o.request_id
      WHERE o.install_hash = ?
      ORDER BY o.created_at DESC
      LIMIT ?`,
    [installHash, LIMITS.listMax],
  );
  return json(200, {
    requests: rows.map((r) => ({
      id: r.id,
      ...publicRow(r),
      createdAt: r.created_at,
      updatedAt: r.updated_at,
    })),
  });
}

// ------------------------------------------------------------------ admin ---

async function adminAllowed(request, deps) {
  const { env, now } = deps;
  const t = now();
  const ip = await ipKey(request, env, t);
  const cheap = cheapOf(deps);
  if (cheap.count('admin-fail', ip, HOUR, t) >= LIMITS.adminFailuresPerIpPerHour) {
    return { response: fail(429, 'rate_limited', {}, { 'Retry-After': '600' }) };
  }
  const token = bearer(request);
  const configured = typeof env.ADMIN_TOKEN === 'string' && env.ADMIN_TOKEN.length >= 24;
  if (!configured || !token || !(await safeEqual(token, env.ADMIN_TOKEN))) {
    cheap.add('admin-fail', ip, HOUR, t);
    return { response: fail(401, 'unauthorized') };
  }
  return { ok: true };
}

function sameOrigin(request) {
  const origin = request.headers.get('Origin');
  return !origin || origin === new URL(request.url).origin;
}

async function handleAdminList(request, deps) {
  const gate = await adminAllowed(request, deps);
  if (gate.response) return gate.response;
  const url = new URL(request.url);
  const status = url.searchParams.get('status') ?? 'pending';
  if (status !== 'all' && !STATUSES.includes(status)) return fail(400, 'bad_request');
  const limit = Math.min(
    LIMITS.adminListMax,
    Math.max(1, Number.parseInt(url.searchParams.get('limit') ?? '100', 10) || 100),
  );
  const offset = Math.max(0, Number.parseInt(url.searchParams.get('offset') ?? '0', 10) || 0);
  const rows = await deps.db.all(
    `SELECT id, text, source, status, reason, library_id, shipped_in, votes, locale, platform,
            app_version, created_at, updated_at
       FROM requests
      WHERE (? = 'all' OR status = ?)
      ORDER BY votes DESC, created_at ASC
      LIMIT ? OFFSET ?`,
    [status, status, limit, offset],
  );
  return json(200, {
    requests: rows.map((r) => ({
      id: r.id,
      text: r.text,
      source: r.source ?? null,
      ...publicRow(r),
      locale: r.locale ?? null,
      platform: r.platform ?? null,
      appVersion: r.app_version ?? null,
      createdAt: r.created_at,
      updatedAt: r.updated_at,
    })),
  });
}

async function handleAdminUpdate(request, deps, id) {
  const gate = await adminAllowed(request, deps);
  if (gate.response) return gate.response;
  if (!sameOrigin(request)) return fail(403, 'forbidden');
  const read = await readJson(request);
  if (read.error) return read.error;
  const b = read.value;
  const allowed = new Set(['status', 'reason', 'libraryId', 'shippedIn']);
  if (Object.keys(b).some((k) => !allowed.has(k))) return fail(400, 'bad_request');
  if (!STATUSES.includes(b.status)) return fail(400, 'bad_request');
  if (b.reason != null && !REASONS.includes(b.reason)) return fail(400, 'bad_request');
  if (b.libraryId != null && !/^[A-Za-z0-9_-]{1,40}$/.test(b.libraryId)) return fail(400, 'bad_request');
  if (b.shippedIn != null && !/^\d{1,3}\.\d{1,3}\.\d{1,3}$/.test(b.shippedIn)) {
    return fail(400, 'bad_request');
  }
  const done = await deps.db.run(
    'UPDATE requests SET status = ?, reason = ?, library_id = ?, shipped_in = ?, updated_at = ? WHERE id = ?',
    [
      b.status,
      b.status === 'declined' ? (b.reason ?? 'other') : null,
      b.libraryId ?? null,
      b.shippedIn ?? null,
      deps.now(),
      id,
    ],
  );
  return done.changes === 1 ? json(200, { ok: true }) : fail(404, 'not_found');
}

async function handleAdminDelete(request, deps, id) {
  const gate = await adminAllowed(request, deps);
  if (gate.response) return gate.response;
  if (!sameOrigin(request)) return fail(403, 'forbidden');
  await deps.db.run('DELETE FROM request_owners WHERE request_id = ?', [id]);
  const done = await deps.db.run('DELETE FROM requests WHERE id = ?', [id]);
  return done.changes === 1 ? json(200, { ok: true }) : fail(404, 'not_found');
}

// ---------------------------------------------------------------- router ----

export async function handle(request, deps) {
  const url = new URL(request.url);
  const path = url.pathname.replace(/\/+$/, '') || '/';
  const method = request.method;

  try {
    if (path === '/' || path === '/health') {
      return method === 'GET' || method === 'HEAD'
        ? json(200, { ok: true })
        : fail(405, 'method_not_allowed');
    }

    if (path === '/admin') {
      if (method !== 'GET') return fail(405, 'method_not_allowed');
      const { adminPage } = await import('./admin_page.mjs');
      return adminPage(toBase64Url(deps.randomBytes(16)));
    }

    if (path.startsWith('/admin/api/')) {
      if (path === '/admin/api/requests' && method === 'GET') return await handleAdminList(request, deps);
      const match = /^\/admin\/api\/requests\/([A-Za-z0-9_-]{8,32})$/.exec(path);
      if (match && method === 'POST') return await handleAdminUpdate(request, deps, match[1]);
      if (match && method === 'DELETE') return await handleAdminDelete(request, deps, match[1]);
      return fail(404, 'not_found');
    }

    if (path.startsWith('/v1/')) {
      // The app is not a web page. Anything that looks like one is turned away.
      if (request.headers.get('Origin')) return fail(403, 'forbidden');
      if (path === '/v1/challenge') {
        return method === 'GET'
          ? await handleChallenge(request, deps)
          : fail(405, 'method_not_allowed', {}, { Allow: 'GET' });
      }
      if (path === '/v1/requests') {
        if (method === 'POST') return await handleSubmit(request, deps);
        if (method === 'GET') return await handleList(request, deps);
        return fail(405, 'method_not_allowed', {}, { Allow: 'GET, POST' });
      }
    }

    return fail(404, 'not_found');
  } catch (error) {
    // Never echo internals to the caller.
    console.error('request failed', error);
    return fail(500, 'server_error');
  }
}
