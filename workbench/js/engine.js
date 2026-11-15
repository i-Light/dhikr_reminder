(function () {
  "use strict";

  var CFG = {
    intervals: { few: 180, hour: 60, often: 20 },
    laterMin: 10,
    ladderPct: [10, 30, 50, 70, 100],
    freeLadder: [10, 20, 33, 50, 70, 100],
    start: {
      new: { pct: 30, count: 3, comfort: 5 },
      some: { pct: 50, count: 5, comfort: 10 },
      daily: { pct: 100, count: 8, comfort: 33 }
    },
    comfortMax: 100,
    growAfter: 3, growBy: 1.25,
    closeRun: 2, closeBy: 0.75,
    ignoreRun: 3, ignoreBy: 0.5,
    factorMin: 0.25, factorStep: 0.75,
    longWords: 6,
    goodRate: 0.7, goodMinShows: 3, stretch: 1.5,
    weekUp: 5, weekDown: 2,
    heavyMinShows: 5, heavyRate: 0.6, heavyOthers: 0.3,
    extrasTimes: 2,
    momentQuietMin: 20,
    morningAfterWake: 15, morningEnd: 720,
    eveningStart: 1020,
    sleepBefore: 20, sleepAfter: 60,
    wakingWindow: 60
  };

  function min(hhmm) {
    var p = String(hhmm).split(":");
    return (+p[0]) * 60 + (+p[1]);
  }

  function ladder(sunnah) {
    if (sunnah == null) return CFG.freeLadder.slice();
    if (sunnah <= 10) return [sunnah];
    var out = [];
    CFG.ladderPct.forEach(function (p) {
      var v = p === 100 ? sunnah : Math.round(sunnah * p / 100 / 5) * 5 || 5;
      if (v < sunnah && out.indexOf(v) < 0 && (!out.length || v > out[out.length - 1])) out.push(v);
    });
    out.push(sunnah);
    return out;
  }

  function sleepMin(prefs) {
    var w = min(prefs.wake), s = min(prefs.sleep);
    return s <= w ? s + 1440 : s;
  }

  function slots(prefs) {
    var step = CFG.intervals[prefs.freq], w = min(prefs.wake), s = sleepMin(prefs), out = [];
    for (var t = w + step; t < s; t += step) out.push(t);
    return out;
  }

  function dayStartMin(prefs) {
    var s = sleepMin(prefs), w = min(prefs.wake) + 1440;
    return Math.round(s + (w - s) / 2) % 1440;
  }

  function keyOf(d) {
    var p = function (n) { return (n < 10 ? "0" : "") + n; };
    return d.getFullYear() + "-" + p(d.getMonth() + 1) + "-" + p(d.getDate());
  }

  function dayKey(ts, prefs) {
    var d = new Date(ts);
    if (d.getHours() * 60 + d.getMinutes() < dayStartMin(prefs)) d = new Date(d.getFullYear(), d.getMonth(), d.getDate() - 1);
    return keyOf(d);
  }

  function nextKey(key) {
    var p = key.split("-");
    return keyOf(new Date(+p[0], +p[1] - 1, +p[2] + 1));
  }

  function momentTimes(prefs) {
    var w = min(prefs.wake), s = sleepMin(prefs), sb = s - CFG.sleepBefore;
    return {
      waking: { start: w, end: w + CFG.wakingWindow },
      morning: { start: w + CFG.morningAfterWake, end: CFG.morningEnd },
      evening: { start: CFG.eveningStart, end: sb },
      sleep: { start: sb, end: s + CFG.sleepAfter }
    };
  }

  function startRung(rungs, pct) {
    var top = rungs[rungs.length - 1], want = top * pct / 100, best = 0;
    rungs.forEach(function (v, i) {
      if (Math.abs(v - want) < Math.abs(rungs[best] - want)) best = i;
    });
    return best;
  }

  function newState(answers, library) {
    var st = CFG.start[answers.level];
    var picked = library.map(function (x, i) { return { x: x, i: i }; })
      .sort(function (a, b) {
        var sa = a.x.starter == null ? Infinity : a.x.starter, sb = b.x.starter == null ? Infinity : b.x.starter;
        return sa - sb || a.i - b.i;
      }).slice(0, st.count).map(function (o) { return o.x; });
    var adhkar = picked.map(function (x) {
      var r = ladder(x.sunnah), i = startRung(r, st.pct);
      return { id: x.id, target: r[i], auto: true, rung: i, resting: false, factor: 1, closeRun: 0, finishRun: 0, _r: r };
    });
    var cap = slots(answers).length * st.comfort;
    function sum() { return adhkar.reduce(function (a, d) { return a + d.target; }, 0); }
    while (sum() > cap && adhkar.some(function (d) { return d.rung > 0; })) {
      adhkar.forEach(function (d) { if (d.rung > 0) { d.rung--; d.target = d._r[d.rung]; } });
    }
    adhkar.forEach(function (d) { delete d._r; });
    var comfort = [], hours = [];
    for (var h = 0; h < 24; h++) {
      comfort.push(st.comfort);
      hours.push({ finishRun: 0, closeRun: 0, ignoreRun: 0, shown: 0, finished: 0 });
    }
    var words = {};
    library.forEach(function (x) { words[x.id] = x.words; });
    return {
      prefs: { level: answers.level, freq: answers.freq, wake: answers.wake, sleep: answers.sleep, cardSize: answers.cardSize },
      adhkar: adhkar, comfort: comfort, hours: hours, words: words,
      day: emptyDay(null),
      week: { start: null, days: [] }, review: null, pausedUntil: 0
    };
  }

  function emptyDay(key) {
    return { key: key, done: {}, extra: {}, carry: {}, showing: null, lastShown: null, moments: {}, complete: false,
      shows: {}, skips: {}, laterAt: 0 };
  }

  function copy(state) { return structuredClone(state); }

  function find(state, id) {
    for (var i = 0; i < state.adhkar.length; i++) if (state.adhkar[i].id === id) return state.adhkar[i];
    return null;
  }

  function active(state) {
    return state.adhkar.filter(function (a) { return !a.resting; });
  }

  function left(state, id) {
    var a = find(state, id);
    return a ? Math.max(0, a.target - (state.day.done[id] || 0)) : 0;
  }

  function intervalMin(state) {
    return CFG.intervals[state.prefs.freq] * (state.day.complete ? CFG.extrasTimes : 1);
  }

  // Minutes from the day's midnight; after midnight but before the day boundary counts past 1440.
  function nowMin(ts, prefs) {
    var d = new Date(ts), m = d.getHours() * 60 + d.getMinutes();
    return m < dayStartMin(prefs) ? m + 1440 : m;
  }

  // True inside the first momentQuietMin minutes of any moment's window.
  function inQuiet(prefs, m) {
    var t = momentTimes(prefs);
    return Object.keys(t).some(function (k) { return m >= t[k].start && m < t[k].start + CFG.momentQuietMin; });
  }

  function fileDay(state, day) {
    var finished = {};
    state.adhkar.forEach(function (a) { finished[a.id] = (day.done[a.id] || 0) >= a.target; });
    return { key: day.key, finished: finished, shows: day.shows || {}, skips: day.skips || {} };
  }

  function rollDay(state, ts) {
    var s = copy(state), key = dayKey(ts, s.prefs), old = s.day.key;
    if (old === key) return s;
    if (old !== null) {
      s.week.days.push(fileDay(s, s.day));
      for (var k = nextKey(old); k < key; k = nextKey(k)) s.week.days.push(fileDay(s, emptyDay(k)));
    }
    s.day = emptyDay(key);
    return s;
  }

  function pieceLimit(s, a, h) {
    var long = Math.max(1, Math.ceil((s.words && s.words[a.id] || 0) / CFG.longWords));
    var limit = Math.max(1, Math.floor(s.comfort[h] * a.factor / long)), hr = s.hours[h];
    if (hr.shown >= CFG.goodMinShows && hr.finished / hr.shown >= CFG.goodRate) limit = Math.floor(limit * CFG.stretch);
    return limit;
  }

  function show(state, ts) {
    var s = rollDay(state, ts), day = s.day;
    if (day.showing) return { state: s, card: day.showing };
    var card = pick(s, ts);
    if (card) { delete day.carry[card.id]; day.lastShown = card.id; }
    day.showing = card;
    return { state: s, card: card };
  }

  function pick(s, ts) {
    var day = s.day, act = active(s), m = nowMin(ts, s.prefs), h = new Date(ts).getHours();
    if (ts < s.pausedUntil || !act.length || inQuiet(s.prefs, m)) return null;
    for (var i = 0; i < act.length; i++) {
      var c = day.carry[act[i].id];
      if (c && (day.complete || left(s, act[i].id) > 0)) return { id: act[i].id, piece: c.piece, done: c.done, extra: day.complete };
    }
    if (day.complete) {
      var at = -1;
      act.forEach(function (a, j) { if (a.id === day.lastShown) at = j; });
      var next = act[(at + 1) % act.length];
      return { id: next.id, piece: pieceLimit(s, next, h), done: 0, extra: true };
    }
    var open = act.filter(function (a) { return left(s, a.id) > 0; });
    if (!open.length) return null;
    var sl = slots(s.prefs);
    var expected = sl.filter(function (t) { return t <= m; }).length / Math.max(1, sl.length);
    var slotsLeft = Math.max(1, sl.filter(function (t) { return t >= m; }).length);
    var cands = open.length > 1 ? open.filter(function (a) { return a.id !== day.lastShown; }) : open;
    var behind = function (x) { return expected - (day.done[x.id] || 0) / x.target; };
    var best = cands[0];
    cands.forEach(function (a) { if (behind(a) > behind(best)) best = a; });
    var rest = left(s, best.id);
    var need = Math.ceil(rest / Math.max(1, Math.floor(slotsLeft / open.length)));
    var piece = Math.min(Math.max(Math.min(need, pieceLimit(s, best, h)), 1), rest);
    return { id: best.id, piece: piece, done: 0, extra: false };
  }

  function tap(state, ts, id, n) {
    var s = rollDay(state, ts), day = s.day, a = find(s, id);
    if (!a) return s;
    n = n == null ? 1 : n;
    var had = day.done[id] || 0, toDone = Math.max(0, Math.min(n, a.target - had));
    day.done[id] = had + toDone;
    if (n > toDone) day.extra[id] = (day.extra[id] || 0) + n - toDone;
    if (had < a.target && day.done[id] >= a.target) delete day.carry[id];
    if (day.showing && day.showing.id === id) day.showing.done = Math.min(day.showing.piece, day.showing.done + n);
    var act = active(s);
    if (act.length && act.every(function (x) { return left(s, x.id) === 0; })) day.complete = true;
    return s;
  }

  function leave(state, ts, how) {
    var s = rollDay(state, ts), day = s.day, card = day.showing;
    if (!card) return s;
    day.showing = null;
    var a = find(s, card.id), h = new Date(ts).getHours(), hr = s.hours[h], c = s.comfort[h];
    var finish = card.done === card.piece;
    if (!finish && card.done > 0) day.carry[card.id] = { piece: card.piece, done: card.done };
    if (how === "later" && !finish) {
      day.laterAt = ts + CFG.laterMin * 60000;
      return s;
    }
    if (!a) return s;
    hr.shown++;
    day.shows[a.id] = (day.shows[a.id] || 0) + 1;
    if (finish) {
      hr.finished++;
      hr.closeRun = 0; hr.ignoreRun = 0;
      if (++hr.finishRun >= CFG.growAfter) { s.comfort[h] = Math.min(CFG.comfortMax, Math.ceil(c * CFG.growBy)); hr.finishRun = 0; }
      a.closeRun = 0;
      if (++a.finishRun >= CFG.growAfter) { a.factor = Math.min(1, a.factor / CFG.factorStep); a.finishRun = 0; }
    } else if (card.done > 0) {
      hr.finishRun = 0; hr.closeRun = 0; hr.ignoreRun = 0;
      s.comfort[h] = Math.max(1, Math.round((c + card.done) / 2));
      a.finishRun = 0; a.closeRun = 0;
    } else {
      day.skips[a.id] = (day.skips[a.id] || 0) + 1;
      hr.finishRun = 0;
      if (how === "ignore") {
        if (++hr.ignoreRun >= CFG.ignoreRun) { s.comfort[h] = Math.max(1, Math.round(c * CFG.ignoreBy)); hr.ignoreRun = 0; }
      } else {
        if (++hr.closeRun >= CFG.closeRun) { s.comfort[h] = Math.max(1, Math.round(c * CFG.closeBy)); hr.closeRun = 0; }
        a.finishRun = 0;
        if (++a.closeRun >= CFG.closeRun) { a.factor = Math.max(CFG.factorMin, a.factor * CFG.factorStep); a.closeRun = 0; }
      }
    }
    return s;
  }

  var E = { CFG: CFG, min: min, ladder: ladder, slots: slots, dayStartMin: dayStartMin,
    dayKey: dayKey, momentTimes: momentTimes, newState: newState,
    rollDay: rollDay, show: show, tap: tap, leave: leave, intervalMin: intervalMin, left: left, active: active };

  if (typeof module === "object" && module.exports) module.exports = E;
  else (window.W = window.W || {}).E = E;
})();
