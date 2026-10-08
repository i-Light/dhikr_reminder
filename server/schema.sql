-- The dhikr request service's database (Cloudflare D1, which is SQLite).
-- Safe to run again: every statement is IF NOT EXISTS.

-- One row per dhikr somebody asked for. The same dhikr asked for twice is one
-- row with two votes, see text_hash.
CREATE TABLE IF NOT EXISTS requests (
  id          TEXT PRIMARY KEY,                 -- random, public to its owners
  text        TEXT NOT NULL,
  source      TEXT,                             -- where the person found it
  text_hash   TEXT NOT NULL UNIQUE,             -- SHA-256 of the normalised text
  status      TEXT NOT NULL DEFAULT 'pending'
              CHECK (status IN ('pending', 'in_progress', 'done', 'declined')),
  reason      TEXT
              CHECK (reason IS NULL OR reason IN ('duplicate', 'unclear', 'not_suitable', 'other')),
  library_id  TEXT,                             -- the entry id in the app once added
  shipped_in  TEXT,                             -- the app version that carries it
  votes       INTEGER NOT NULL DEFAULT 1,
  locale      TEXT,
  platform    TEXT,
  app_version TEXT,
  created_at  INTEGER NOT NULL,
  updated_at  INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS requests_by_status ON requests (status, votes DESC, created_at);

-- Who may read which request. Only the SHA-256 of an install token is kept, so
-- a copy of this table is not a set of keys.
CREATE TABLE IF NOT EXISTS request_owners (
  request_id   TEXT NOT NULL,
  install_hash TEXT NOT NULL,
  created_at   INTEGER NOT NULL,
  PRIMARY KEY (request_id, install_hash)
);
CREATE INDEX IF NOT EXISTS owners_by_install ON request_owners (install_hash, created_at DESC);

-- Proof-of-work puzzles that were already used, so each works once.
CREATE TABLE IF NOT EXISTS used_challenges (
  nonce      TEXT PRIMARY KEY,
  expires_at INTEGER NOT NULL
);

-- Sliding-window counters for the rate limits. Keys are hashes, never raw
-- addresses or tokens.
CREATE TABLE IF NOT EXISTS rate_events (
  bucket TEXT NOT NULL,
  key    TEXT NOT NULL,
  at     INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS rate_by_key ON rate_events (bucket, key, at);
