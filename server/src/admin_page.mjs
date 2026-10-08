// The page the dev team uses to go through the requests: open /admin on the
// service, paste the admin token, and set each request's status.
//
// It holds the token in memory only, talks to /admin/api/* with a Bearer
// header, and builds every row with textContent, never innerHTML, so nothing a
// stranger typed into a request can run here. The Content-Security-Policy
// allows only this page's own nonce-marked script and style.

const STYLE = `
  :root { color-scheme: light dark; --b: #8a6d2f; }
  body { font: 15px/1.5 system-ui, sans-serif; margin: 0; padding: 16px; max-width: 880px; margin-inline: auto; }
  h1 { font-size: 20px; margin: 0 0 12px; }
  .bar { display: flex; flex-wrap: wrap; gap: 8px; align-items: center; margin-bottom: 16px; }
  input, select, button { font: inherit; padding: 6px 10px; border-radius: 8px; border: 1px solid #8884; background: transparent; color: inherit; }
  button { cursor: pointer; }
  button.main { background: var(--b); color: #fff; border-color: var(--b); }
  button.danger { color: #c0392b; border-color: #c0392b66; }
  .card { border: 1px solid #8884; border-radius: 12px; padding: 12px 14px; margin-bottom: 12px; }
  .text { font-size: 19px; line-height: 1.9; white-space: pre-wrap; unicode-bidi: plaintext; }
  .meta { color: #888; font-size: 13px; margin: 6px 0; }
  .row { display: flex; flex-wrap: wrap; gap: 6px; margin-top: 8px; align-items: center; }
  .tag { display: inline-block; padding: 1px 8px; border-radius: 999px; background: #8883; font-size: 12px; }
  #msg { min-height: 1.4em; color: #c0392b; }
`;

const SCRIPT = `
const $ = (id) => document.getElementById(id);
let token = '';
const msg = (text) => { $('msg').textContent = text || ''; };

async function api(path, method = 'GET', body) {
  const res = await fetch(path, {
    method,
    headers: { Authorization: 'Bearer ' + token, ...(body ? { 'Content-Type': 'application/json' } : {}) },
    body: body ? JSON.stringify(body) : undefined,
    credentials: 'omit',
  });
  if (!res.ok) throw new Error(res.status + ' ' + ((await res.json().catch(() => ({}))).error || ''));
  return res.json();
}

function el(tag, text, cls) {
  const node = document.createElement(tag);
  if (text !== undefined) node.textContent = text;
  if (cls) node.className = cls;
  return node;
}

function button(label, cls, onClick) {
  const b = el('button', label, cls);
  b.addEventListener('click', onClick);
  return b;
}

async function setStatus(r, status, extra = {}) {
  try {
    await api('/admin/api/requests/' + r.id, 'POST', { status, ...extra });
    await load();
  } catch (e) { msg(e.message); }
}

function card(r) {
  const c = el('div', undefined, 'card');
  c.append(el('div', r.text, 'text'));
  if (r.source) c.append(el('div', 'Source: ' + r.source, 'meta'));
  const meta = [r.votes + (r.votes === 1 ? ' vote' : ' votes'), r.platform, r.appVersion, r.locale,
    new Date(r.createdAt * 1000).toISOString().slice(0, 16).replace('T', ' ')].filter(Boolean).join('  |  ');
  c.append(el('div', meta, 'meta'));
  const state = el('div', undefined, 'meta');
  state.append(el('span', r.status, 'tag'));
  if (r.reason) state.append(' ', el('span', r.reason, 'tag'));
  if (r.libraryId) state.append(' ', el('span', 'library ' + r.libraryId, 'tag'));
  if (r.shippedIn) state.append(' ', el('span', 'in ' + r.shippedIn, 'tag'));
  c.append(state);

  const row = el('div', undefined, 'row');
  row.append(button('In progress', '', () => setStatus(r, 'in_progress')));

  const lib = el('input'); lib.placeholder = 'library id'; lib.size = 14;
  const ver = el('input'); ver.placeholder = 'version 0.1.3'; ver.size = 10;
  row.append(lib, ver, button('Done', 'main', () => setStatus(r, 'done', {
    libraryId: lib.value.trim() || null, shippedIn: ver.value.trim() || null })));

  const why = el('select');
  for (const [v, t] of [['duplicate', 'already exists'], ['unclear', 'unclear text'], ['not_suitable', 'not suitable'], ['other', 'other']]) {
    const o = el('option', t); o.value = v; why.append(o);
  }
  row.append(why, button('Decline', 'danger', () => setStatus(r, 'declined', { reason: why.value })));
  row.append(button('Delete', 'danger', async () => {
    if (!confirm('Delete this request for good?')) return;
    try { await api('/admin/api/requests/' + r.id, 'DELETE'); await load(); } catch (e) { msg(e.message); }
  }));
  c.append(row);
  return c;
}

async function load() {
  msg('');
  try {
    const { requests } = await api('/admin/api/requests?status=' + encodeURIComponent($('status').value));
    const list = $('list');
    list.replaceChildren();
    if (requests.length === 0) list.append(el('p', 'Nothing here.', 'meta'));
    for (const r of requests) list.append(card(r));
  } catch (e) { msg(e.message); }
}

$('go').addEventListener('click', () => { token = $('token').value.trim(); load(); });
$('status').addEventListener('change', () => { if (token) load(); });
`;

export function adminPage(nonce) {
  const html = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex, nofollow">
<title>Dhikr requests</title>
<style nonce="${nonce}">${STYLE}</style>
</head>
<body>
<h1>Dhikr requests</h1>
<div class="bar">
  <input id="token" type="password" placeholder="Admin token" autocomplete="off" size="28">
  <select id="status">
    <option value="pending">Pending</option>
    <option value="in_progress">In progress</option>
    <option value="done">Done</option>
    <option value="declined">Declined</option>
    <option value="all">All</option>
  </select>
  <button id="go" class="main">Load</button>
</div>
<div id="msg" role="alert"></div>
<div id="list"></div>
<script nonce="${nonce}">${SCRIPT}</script>
</body>
</html>`;
  return new Response(html, {
    status: 200,
    headers: {
      'Content-Type': 'text/html; charset=utf-8',
      'Cache-Control': 'no-store',
      'X-Content-Type-Options': 'nosniff',
      'Referrer-Policy': 'no-referrer',
      'X-Frame-Options': 'DENY',
      'Content-Security-Policy':
        `default-src 'none'; script-src 'nonce-${nonce}'; style-src 'nonce-${nonce}'; ` +
        `connect-src 'self'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'`,
    },
  });
}
