/* sim.js: plays a pretend person through days with the real engine, so every example day is one the engine can produce. */
(function () {
  "use strict";
  var node = typeof module === "object" && module.exports;
  var E = node ? require("./engine.js") : window.W.E;
  var D = node ? require("./data.js") : { LIB: window.W.LIB, SETS: window.W.SETS };

  var PEOPLE = ["responsive", "busyNoon", "ignoresOne", "away"];
  var MOMENTS = {
    responsive: ["waking", "morning", "evening", "sleep"],
    busyNoon: ["waking", "morning", "sleep"],
    ignoresOne: ["waking", "morning", "evening", "sleep"],
    away: []
  };
  var IGNORED = D.LIB.filter(function (x) { return x.starter === 1; })[0].id;

  function mulberry32(a) {
    return function () {
      a = a + 0x6D2B79F5 | 0;
      var t = Math.imul(a ^ a >>> 15, 1 | a);
      t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t;
      return ((t ^ t >>> 14) >>> 0) / 4294967296;
    };
  }

  // What the person does with a card: taps toward it and how they leave it.
  function act(person, card, ts, rnd, opts) {
    var rest = card.piece - card.done, h = new Date(ts).getHours();
    if (person === "away" || person === "busyNoon" && h >= 11 && h < 15) return { taps: 0, how: "ignore" };
    if (person === "ignoresOne" && card.id === IGNORED) return { taps: 0, how: "close" };
    // internal: the person is there but can only manage part of each piece
    if (opts.part) return { taps: Math.max(1, Math.floor(rest * opts.part)), how: "close" };
    if (person === "responsive" && rnd() >= 0.9) {
      return rest > 1 ? { taps: 1 + Math.floor(rnd() * (rest - 1)), how: "close" } : { taps: 0, how: "close" };
    }
    return { taps: rest, how: "close" };
  }

  // Moment starts the person keeps and every ordinary slot of one day, as [ts, kind, key].
  function dayEvents(state, key, person, opts) {
    var p = key.split("-"), pr = state.prefs, w = E.min(pr.wake), s = E.min(pr.sleep), step = E.CFG.intervals[pr.freq];
    if (s <= w) s += 1440;
    var at = function (m) { return new Date(+p[0], +p[1] - 1, +p[2], 0, m).getTime(); };
    var times = E.momentTimes(pr), out = [];
    MOMENTS[person].forEach(function (k) {
      if (opts && opts.part && k === "sleep") return;
      if (!pr.moments || !pr.moments[k] || pr.moments[k].on !== false) out.push([at(times[k].start), 0, k]);
    });
    for (var t = w + step; t < s; t += step) out.push([at(t), 1, t - w]);
    return out.sort(function (a, b) { return a[0] - b[0] || a[1] - b[1]; });
  }

  function session(state, ts, key) {
    var items = D.SETS[key], guard = 100000;
    state = E.rollDay(state, ts);
    while (!(state.day.moments[key] && state.day.moments[key].done) && guard--) state = E.sessionTap(state, ts, key, items);
    return state;
  }

  function slot(state, ts, person, rnd, opts, log) {
    var r = E.show(state, ts), card = r.card;
    state = r.state;
    if (!card) return state;
    var h = new Date(ts).getHours(), before = state.comfort[h], a = act(person, card, ts, rnd, opts);
    if (a.taps) state = E.tap(state, ts, card.id, a.taps);
    state = E.leave(state, ts, a.how);
    var rest = card.piece - card.done;
    log.push({ ts: ts, id: card.id, piece: card.piece, did: card.done + a.taps,
      how: a.taps === rest ? "finish" : a.taps ? "partial" : a.how, comfortBefore: before, comfortAfter: state.comfort[h] });
    return state;
  }

  // opts is internal: {part: 0..1} makes a person who is there but only manages that share of each piece.
  function run(state, fromTs, toTs, person, seed, opts) {
    opts = opts || {};
    var rnd = mulberry32(seed >>> 0), log = [];
    var key = E.dayKey(fromTs, state.prefs), last = E.dayKey(toTs, state.prefs);
    for (; key <= last; key = nextKey(key)) {
      dayEvents(state, key, person, opts).forEach(function (ev) {
        var ts = ev[0];
        if (ts < fromTs || ts >= toTs) return;
        if (ev[1] === 0) { state = session(state, ts, ev[2]); return; }
        state = E.rollDay(state, ts);
        if (ev[2] % E.intervalMin(state) === 0) state = slot(state, ts, person, rnd, opts, log);
      });
    }
    return { state: E.rollDay(state, toTs), log: log };
  }

  function nextKey(key) {
    var p = key.split("-"), d = new Date(+p[0], +p[1] - 1, +p[2] + 1), z = function (n) { return (n < 10 ? "0" : "") + n; };
    return d.getFullYear() + "-" + z(d.getMonth() + 1) + "-" + z(d.getDate());
  }

  var ANSWERS = { level: "some", freq: "hour", wake: "06:00", sleep: "23:00", cardSize: "small" };
  var SEED = 1;
  // [person, days after Monday 2026-11-09, hour, minute, opts]
  var DAYS = {
    noon: ["responsive", 3, 12, 10],
    friday: ["responsive", 4, 12, 10],
    complete: ["responsive", 2, 22, 10],
    missed: ["away", 8, 9, 0],
    weekup: ["responsive", 7, 7, 30],
    weekdown: ["responsive", 7, 7, 30, { part: 0.5 }],
    weekheavy: ["ignoresOne", 7, 7, 30]
  };

  function day(name) {
    var t0 = new Date(2026, 10, 9, 6, 0).getTime(), d = DAYS[name];
    if (!d) return { state: null, now: t0 };
    var now = new Date(2026, 10, 9 + d[1], d[2], d[3]).getTime();
    return { state: run(E.newState(ANSWERS, D.LIB), t0, now, d[0], SEED, d[4]).state, now: now };
  }

  var Sim = { PEOPLE: PEOPLE, IGNORED: IGNORED, run: run, day: day };
  if (node) module.exports = Sim; else window.W.Sim = Sim;
})();
