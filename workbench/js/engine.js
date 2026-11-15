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

  function dayKey(ts, prefs) {
    var d = new Date(ts);
    if (d.getHours() * 60 + d.getMinutes() < dayStartMin(prefs)) d = new Date(d.getFullYear(), d.getMonth(), d.getDate() - 1);
    var p = function (n) { return (n < 10 ? "0" : "") + n; };
    return d.getFullYear() + "-" + p(d.getMonth() + 1) + "-" + p(d.getDate());
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
    return {
      prefs: { level: answers.level, freq: answers.freq, wake: answers.wake, sleep: answers.sleep, cardSize: answers.cardSize },
      adhkar: adhkar, comfort: comfort, hours: hours,
      day: { key: null, done: {}, extra: {}, carry: {}, showing: null, lastShown: null, moments: {}, complete: false },
      week: { start: null, days: [] }, review: null, pausedUntil: 0
    };
  }

  var E = { CFG: CFG, min: min, ladder: ladder, slots: slots, dayStartMin: dayStartMin,
    dayKey: dayKey, momentTimes: momentTimes, newState: newState };

  if (typeof module === "object" && module.exports) module.exports = E;
  else (window.W = window.W || {}).E = E;
})();
