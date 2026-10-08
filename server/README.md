# Dhikr request service

The small service behind "Request a dhikr" in the app. A person asks for a
dhikr that is not in the library, the dev team sees the request on a private
admin page, and the app shows that person how their request is going:
waiting, being worked on, added (with thanks), or declined (with a kind
reason).

It is one Cloudflare Worker plus one D1 (SQLite) database. Both fit in
Cloudflare's free plan at this scale. The same code also runs on your own
computer with plain Node, which is how the tests and `node dev.mjs` work.

```
app  --HTTPS-->  Worker (src/worker.mjs -> src/core.mjs)  -->  D1 database
dev team  --browser-->  /admin  (token protected)
```

## One-time setup

You need a free Cloudflare account and Node 22.13 or newer.

```sh
cd server
npx wrangler login

# 1. The database. Copy the database_id it prints into wrangler.toml.
npx wrangler d1 create dhikr-requests
npx wrangler d1 execute dhikr-requests --remote --file=schema.sql

# 2. The three secrets. Use long random values, for example:
#      node -e "console.log(require('crypto').randomBytes(32).toString('base64url'))"
npx wrangler secret put ADMIN_TOKEN       # opens the admin page, keep it private
npx wrangler secret put CHALLENGE_SECRET  # signs the proof-of-work puzzles
npx wrangler secret put IP_SALT           # salts the stored address hashes

# 3. Deploy. It prints the address, like https://dhikr-requests.<you>.workers.dev
npx wrangler deploy
```

Then put that address in `defaultRequestsUrl` in
`lib/features/requests/data/requests_config.dart` and commit it. The address is
public (every installed app has to know it), so it belongs in the code and not
in a secret. Normal builds, including `scripts/build_android.ps1` and
`scripts/build_windows.ps1`, then use it with nothing extra to set.

A single build can still point somewhere else with
`--dart-define=DHIKR_REQUESTS_URL=<address>` (the scripts pass the environment
variable of that name on when it is set). An empty value builds an app that
hides the request feature entirely.

Do not move the service to another address once apps are out: installed copies
keep calling the old one. If you ever must, keep the old Worker running and let
it answer until old versions are gone.

There is nothing to switch on in the Cloudflare dashboard. Its web application
firewall, rate limiting rules and Bot Fight Mode belong to a domain you own on
Cloudflare (and rate limiting rules are a paid add-on); a `workers.dev` address
has none of them. The service carries its own firewall instead, see
[The firewall](#the-firewall). If you later attach your own domain, you can add
Cloudflare's rules in front of it too, and nothing here needs to change.

## Working through requests

Open `https://<your-worker>/admin`, paste the admin token, and press Load.
Requests with the most votes come first. For each one:

* **In progress** tells the person you are working on it.
* **Done** says it was added. Fill in the library id (the `id:` of the entry in
  `lib/features/library/data/dhikr_library_data.dart`) and the app version that
  carries it, for example `0.1.4`. The person's phone then offers to open it in
  the library as soon as it has that version, and says "coming in the next
  update" until then.
* **Decline** takes a reason: already exists, unclear text, not suitable, other.
  Each has its own polite message in the app.
* **Delete** removes a request for everyone (spam).

To add a dhikr to the library, add it to `tool/data/zekrel_scraped.json` in the
same shape as the others, run `dart run tool/generate_library.dart`, ship the
update, then mark the request Done.

## API

All bodies are JSON. The app is the only intended client.

| Call | What it does |
| --- | --- |
| `GET /v1/challenge` | A signed proof-of-work puzzle: `{challenge, bits, expiresAt}`. |
| `POST /v1/requests` | Sends a request. `Authorization: Bearer <install token>`. Body: `text`, `source?`, `challenge`, `counter`, `locale?`, `platform?`, `appVersion?`. Answers `201` with `{id, status, ...}`, or `200` with `duplicate: true` when somebody already asked for the same dhikr. |
| `GET /v1/requests` | The caller's own requests and their status. Same bearer token. |
| `GET /admin` | The admin page. |
| `GET /admin/api/requests?status=` | Requests with their text (admin token). |
| `POST /admin/api/requests/:id` | Sets `status`, `reason?`, `libraryId?`, `shippedIn?` (admin token). |
| `DELETE /admin/api/requests/:id` | Deletes a request (admin token). |

Errors are `{error: "<code>"}`. Codes the app understands: `invalid_text`
(with `reason`: `too_short`, `too_long`, `not_arabic`, `has_link`,
`repeated`), `rate_limited` (with `retryAfter` seconds), `too_many_open`,
`challenge_expired`, `pow_failed`, `unauthorized`, `forbidden`, `too_large`.

The proof of work: find a number `counter` so that the SHA-256 of
`<challenge>:<install token>:<counter>` starts with `bits` zero bits. The app
does this in the background, it takes well under a second on a phone at the
default 16 bits.

## The firewall

`src/firewall.mjs` runs before everything else and answers bad traffic without
touching the database. Cloudflare's free plan allows 100,000 Worker requests and
100,000 database writes a day, so the aim is that a flood costs requests but not
writes:

| Layer | What it does |
| --- | --- |
| Ban | An address that sends 25 bad requests (400, 401, 403, 404, 405, 413, 414, 415) within 10 minutes is refused for 30 minutes. Being rate limited is not a strike, and a person who mistypes a few times is nowhere near it. |
| Shape | Addresses over 400 characters and methods other than GET, HEAD, POST and DELETE are refused. |
| Client | Under `/v1` the request must carry the app's own `User-Agent` (`dhikr_reminder-requests`). Browsers, curl and scanners are turned away at once. This is a speed bump only, anyone can copy a header; the puzzle and the limits behind it are what hold. |
| Volume | 60 calls a minute per address under `/v1`, 30 under `/admin`, 120 for anything else. Counted in memory, and again by Cloudflare's own Rate Limiting binding (`RL_V1`, `RL_ADMIN` in `wrangler.toml`). |
| No database writes for noise | Puzzles, status checks and wrong admin tokens are counted in memory (`src/limiter.mjs`), so none of them writes a row. Only the daily caps on real submissions, which must be exact, live in the database. |
| Bodies | A request body is read only up to 4 KB and then dropped, even if it is streamed with no length. |

Everything is keyed by the salted daily hash of the address, kept in memory
only, and forgotten when the Worker instance is.

Limits of this approach, said plainly: memory is per Worker instance and per
place, so the counts are approximate (a flood spread over many places gets more
room than one from a single place), and a request that is turned away still
counts as one of the 100,000 daily Worker requests. A flood big enough to use
those up makes the service unavailable until midnight UTC; the app then shows
its "try again later" message, and nothing else in the app is affected. Beyond
that, only a paid plan or Cloudflare's own rules on your own domain help.

If Cloudflare refuses the `[[ratelimits]]` blocks when you deploy (a plan
restriction), delete those two blocks from `wrangler.toml` and deploy again; the
firewall works without them. To try it without deploying:
`npx wrangler deploy --dry-run`.

## How it defends itself

| Attack | Defence |
| --- | --- |
| A website calling the service from a visitor's browser | Any `/v1` request with an `Origin` header is refused; the admin API only accepts same-origin writes; no CORS headers are ever sent. |
| Mass spam from a script | Every request needs a fresh, single-use, five-minute proof-of-work puzzle bound to the sender's install token. Raise `POW_BITS` (default 16) when under attack. |
| One person sending many | Sliding-window limits: 5 accepted requests a day and 3 open at a time per install, 20 a day per network address, 300 a day for everyone, 30 puzzles an hour per address. |
| Fake installs from one address | The per-address limit above, on a salted hash of the address that changes every day. |
| Garbage, links, markup, scripts | The text must be Arabic, 8 to 600 letters, no links, `<`, `>`, backticks, or runs of one letter; control and bidi-override characters are stripped before it is stored. |
| Oversized or malformed bodies | 4 KB cap checked before parsing, strict field list and types, unknown fields refused. |
| Duplicate floods | The same dhikr (compared after folding vowels, alef and heh spellings) is one row with a vote count. |
| Reading someone else's requests | The install token is a 256-bit random secret; requests are found by its hash, ids are random, and a caller only ever gets their own. |
| A leaked database | Only SHA-256 of install tokens and salted daily hashes of addresses are stored, never the tokens or the addresses. |
| Guessing the admin token | Constant-time comparison, a 24 character minimum, and ten wrong tries an hour per address locks that address out. |
| Script injection into the admin page | Every row is built with `textContent`, and the page's Content-Security-Policy allows only its own nonce-marked script. |
| SQL injection | Every query is parameterised. |
| Information leaks | Errors are short codes; server faults say only `server_error` and the details go to the Worker log. |

What it does not do: it cannot prove a request came from the real app. A
determined person can write their own client and pay the proof-of-work cost.
The limits above make that expensive and slow, which is the point. If it ever
becomes a real problem, the next step is Play Integrity attestation on Android.

## What the app sends

The text the person typed, the optional source they typed, a random install
token (not tied to the person or the device), the app version, the platform
(`android` or `windows`), and the app language. Cloudflare sees the IP address
of the connection like any web host; the service keeps only a salted hash of it
for a day. PRIVACY.md at the root of the repository says this to users.

## Running it on your computer

```sh
cd server
npm test            # runs all tests, no installs needed
node dev.mjs        # http://127.0.0.1:8787, admin token printed at start
```

`dev.mjs` turns the puzzle down to 12 bits. To try the Android app against it
over USB: `adb reverse tcp:8787 tcp:8787`, then build a debug app with
`--dart-define=DHIKR_REQUESTS_URL=http://127.0.0.1:8787` (debug builds allow
this one plain-HTTP address; release builds only talk HTTPS).
