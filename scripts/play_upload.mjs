#!/usr/bin/env node
// Uploads an Android App Bundle to a Google Play track through the Google Play
// Developer API. No dependencies: Node 18+ only (fetch and node:crypto).
//
// Normally run through scripts\publish_android.ps1 (which builds and bumps the
// version code first). Direct use:
//
//   node scripts/play_upload.mjs --check
//   node scripts/play_upload.mjs --track internal --notes-en "Fixed the lock screen card"
//
// Options:
//   --aab <file>        default build/app/outputs/bundle/release/app-release.aab
//   --key <file>        service account JSON, default android/play-service-account.json
//                       (or the PLAY_SERVICE_ACCOUNT environment variable)
//   --package <id>      default com.gratovo.dhikr_reminder
//   --track <name>      internal (default), alpha (closed testing), beta, production
//   --status <s>        completed (default), draft, inProgress (staged rollout)
//   --fraction <0-1>    share of users for inProgress, default 0.2
//   --notes-en <text>   release notes, English (en-US)
//   --notes-ar <text>   release notes, Arabic (ar)
//   --check             only prove the key, package and permissions work; uploads nothing
//
// The API can only change an app that already has one upload made by hand in
// Play Console, so the very first bundle goes through the website.

import { createSign } from 'node:crypto';
import { existsSync, readFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

// Print the message, not a stack trace, for every failure.
for (const event of ['uncaughtException', 'unhandledRejection']) {
  process.on(event, (e) => { console.error(`\nERROR: ${e?.message ?? e}`); process.exitCode = 1; });
}

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');

function parseArgs(argv) {
  const out = {};
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (!a.startsWith('--')) throw new Error(`Unexpected argument: ${a}`);
    const name = a.slice(2);
    if (name === 'check') { out.check = true; continue; }
    out[name] = argv[++i];
    if (out[name] === undefined) throw new Error(`--${name} needs a value`);
  }
  return out;
}

const opts = parseArgs(process.argv.slice(2));
const pkg = opts.package ?? 'com.gratovo.dhikr_reminder';
const track = opts.track ?? 'internal';
const status = opts.status ?? 'completed';
const fraction = Number(opts.fraction ?? 0.2);
const keyPath = resolve(root, opts.key ?? process.env.PLAY_SERVICE_ACCOUNT ?? 'android/play-service-account.json');
const aabPath = resolve(root, opts.aab ?? 'build/app/outputs/bundle/release/app-release.aab');
const mappingPath = resolve(root, 'build/app/outputs/mapping/release/mapping.txt');

if (!['completed', 'draft', 'inProgress'].includes(status)) {
  throw new Error(`--status must be completed, draft or inProgress (got ${status})`);
}
if (status === 'inProgress' && !(fraction > 0 && fraction < 1)) {
  throw new Error('--fraction must be between 0 and 1 (exclusive) for inProgress');
}
if (!existsSync(keyPath)) {
  throw new Error(`Service account key not found: ${keyPath}\nSee docs/publishing-guide.md, Phase 5.`);
}
if (!opts.check && !existsSync(aabPath)) {
  throw new Error(`Bundle not found: ${aabPath}\nBuild it first (scripts\\build_android.ps1).`);
}

const account = JSON.parse(readFileSync(keyPath, 'utf8'));
if (!account.client_email || !account.private_key) {
  throw new Error('That JSON is not a service account key (no client_email / private_key).');
}

const b64url = (buf) => Buffer.from(buf).toString('base64url');

async function accessToken() {
  const now = Math.floor(Date.now() / 1000);
  const header = b64url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const claims = b64url(JSON.stringify({
    iss: account.client_email,
    scope: 'https://www.googleapis.com/auth/androidpublisher',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3000,
  }));
  const signature = createSign('RSA-SHA256').update(`${header}.${claims}`).sign(account.private_key);
  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: `${header}.${claims}.${b64url(signature)}`,
    }),
  });
  const json = await res.json();
  if (!res.ok) throw new Error(`Could not sign in with the service account: ${json.error_description ?? json.error}`);
  return json.access_token;
}

const api = 'https://androidpublisher.googleapis.com/androidpublisher/v3/applications';
const upload = 'https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications';
let token;

async function call(method, url, { body, contentType = 'application/json' } = {}) {
  const res = await fetch(url, {
    method,
    headers: { Authorization: `Bearer ${token}`, ...(body ? { 'Content-Type': contentType } : {}) },
    body: body === undefined ? undefined : (contentType === 'application/json' ? JSON.stringify(body) : body),
  });
  const text = await res.text();
  let json = {};
  try { json = text ? JSON.parse(text) : {}; } catch { /* leave empty */ }
  if (!res.ok) {
    const message = json.error?.message ?? text.slice(0, 300);
    const hint = res.status === 403
      ? '\nThe service account has no access to this app. In Play Console > Users and permissions, invite its email and give it release permissions for the app.'
      : res.status === 404
        ? '\nPlay does not know this package or edit. Check the package name, and that the first bundle was uploaded by hand.'
        : '';
    throw new Error(`${method} ${url.replace(/\?.*/, '')} -> ${res.status}: ${message}${hint}`);
  }
  return json;
}

token = await accessToken();
console.log(`Signed in as ${account.client_email}`);


// One attempt: open an edit, upload, assign to the track, commit. An edit that
// is never committed changes nothing, so a failure just deletes it.
async function release(releaseStatus) {
  const edit = await call('POST', `${api}/${pkg}/edits`, { body: {} });
  console.log(`Opened edit ${edit.id} for ${pkg}`);
  try {
    if (opts.check) {
      console.log('Play connection works: key accepted, app found, edit allowed. Nothing was uploaded.');
      await call('DELETE', `${api}/${pkg}/edits/${edit.id}`);
      return;
    }
    const bytes = readFileSync(aabPath);
    console.log(`Uploading ${(bytes.length / 1048576).toFixed(1)} MB bundle...`);
    const bundle = await call('POST', `${upload}/${pkg}/edits/${edit.id}/bundles?uploadType=media`, {
      body: bytes,
      contentType: 'application/octet-stream',
    });
    const code = String(bundle.versionCode);
    console.log(`Bundle accepted as version code ${code}`);

    if (existsSync(mappingPath)) {
      try {
        await call('POST', `${upload}/${pkg}/edits/${edit.id}/apks/${code}/deobfuscationFiles/proguard?uploadType=media`, {
          body: readFileSync(mappingPath),
          contentType: 'application/octet-stream',
        });
        console.log('R8 mapping file uploaded (crash reports will be readable)');
      } catch (e) {
        console.warn(`Mapping file not uploaded (the release is unaffected): ${e.message}`);
      }
    }

    const releaseNotes = [];
    if (opts['notes-en']) releaseNotes.push({ language: 'en-US', text: opts['notes-en'] });
    if (opts['notes-ar']) releaseNotes.push({ language: 'ar', text: opts['notes-ar'] });

    const rel = { name: opts.name ?? `${code}`, versionCodes: [code], status: releaseStatus };
    if (releaseStatus === 'inProgress') rel.userFraction = fraction;
    if (releaseNotes.length > 0) rel.releaseNotes = releaseNotes;

    await call('PUT', `${api}/${pkg}/edits/${edit.id}/tracks/${track}`, { body: { track, releases: [rel] } });
    await call('POST', `${api}/${pkg}/edits/${edit.id}:commit`);
    console.log(`Done: version code ${code} is on the "${track}" track (${releaseStatus}).`);
    if (releaseStatus === 'draft') {
      console.log('It is a DRAFT: open Play Console > Testing/Production > the track, check it, and press Review release / Roll out.');
    }
  } catch (e) {
    try { await call('DELETE', `${api}/${pkg}/edits/${edit.id}`); } catch { /* already gone */ }
    throw e;
  }
}

try {
  await release(status);
} catch (e) {
  // Play only accepts draft releases through the API while the app itself is
  // still a draft (before its first release has gone through review). Fall
  // back automatically; the person finishes it with one click in Play Console.
  if (!opts.check && status !== 'draft' && /draft app/i.test(e.message)) {
    console.warn('Play says the app is still a draft, so only draft releases are allowed yet. Retrying as a draft...');
    await release('draft');
  } else {
    throw e;
  }
}
