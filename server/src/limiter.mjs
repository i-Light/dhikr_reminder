// A sliding-window counter that lives in memory and nowhere else.
//
// It exists so that the cheap, high-volume checks (how many puzzles, how many
// status polls, how many wrong admin tokens) never cost a database write. The
// database's free plan allows only 100,000 written rows a day, and a flood of
// harmless-looking requests could use that up. Memory belongs to one Worker
// instance, so these counts are per instance and per place: good enough to
// stop a flood, not an exact ledger. Anything that must be exact for the whole
// service (the daily caps on accepted requests) stays in the database.
//
// Times are unix seconds and are passed in, so tests can move the clock.

const SWEEP_EVERY = 500;
const MAX_KEYS = 20000;
const KEEP_SECONDS = 86400;
const MAX_EVENTS = 200;

export function createLimiter() {
  const events = new Map();
  let operations = 0;

  const idOf = (bucket, key) => `${bucket}\u0000${key}`;

  /** The events of one counter that are still inside its window. */
  function live(id, window, t) {
    const list = events.get(id);
    if (!list) return null;
    const since = t - window;
    let stale = 0;
    while (stale < list.length && list[stale] <= since) stale++;
    if (stale > 0) list.splice(0, stale);
    return list;
  }

  /** Forgets idle counters, and the oldest ones if there are far too many. */
  function housekeeping(t) {
    operations++;
    if (operations % SWEEP_EVERY !== 0 && events.size <= MAX_KEYS) return;
    for (const [id, list] of events) {
      if (list.length === 0 || list[list.length - 1] <= t - KEEP_SECONDS) events.delete(id);
    }
    if (events.size > MAX_KEYS) {
      let drop = Math.ceil(events.size / 10);
      for (const id of events.keys()) {
        if (drop-- <= 0) break;
        events.delete(id);
      }
    }
  }

  return {
    /**
     * Counts one event unless `max` have already happened in the last `window`
     * seconds. Answers `{ ok: true }`, or `{ ok: false, retryAfter }`.
     */
    hit(bucket, key, window, max, t) {
      const id = idOf(bucket, key);
      let list = live(id, window, t);
      if (list && list.length >= max) {
        return { ok: false, retryAfter: Math.max(1, list[0] + window - t) };
      }
      if (!list) {
        list = [];
        events.set(id, list);
      }
      list.push(t);
      housekeeping(t);
      return { ok: true };
    },

    /** How many events are inside the window, without counting a new one. */
    count(bucket, key, window, t) {
      const list = live(idOf(bucket, key), window, t);
      return list ? list.length : 0;
    },

    /** Records an event whatever the count is; returns the count afterwards. */
    add(bucket, key, window, t) {
      const id = idOf(bucket, key);
      let list = live(id, window, t);
      if (!list) {
        list = [];
        events.set(id, list);
      }
      list.push(t);
      if (list.length > MAX_EVENTS) list.splice(0, list.length - MAX_EVENTS);
      housekeeping(t);
      return list.length;
    },

    /** For tests: how many counters are being kept. */
    get size() {
      return events.size;
    },
  };
}
