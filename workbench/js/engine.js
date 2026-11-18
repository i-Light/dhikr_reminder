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
    wakingWindow: 60, lateWindow: 60
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

  var MOMENTS = ["waking", "morning", "evening", "sleep"];

  function momentPrefs(prefs) {
    var out = {};
    MOMENTS.forEach(function (k) {
      var m = prefs.moments && prefs.moments[k] || {};
      out[k] = { on: m.on !== false, at: m.at == null ? null : m.at };
    });
    return out;
  }

  // An edited time ("at", minutes from the day's midnight) moves the start; the end rules stay.
  function momentTimes(prefs) {
    var w = min(prefs.wake), s = sleepMin(prefs), mp = momentPrefs(prefs);
    var start = function (k, def) { return mp[k].at == null ? def : mp[k].at; };
    var sb = start("sleep", s - CFG.sleepBefore), wk = start("waking", w);
    var defMorn = w + CFG.morningAfterWake, mornEnd = CFG.morningEnd;
    var defEve = CFG.eveningStart, eveEnd = sb;
    if (w >= 720) {
      defEve = w <= 1200 ? Math.max(CFG.eveningStart, w + 15) : Math.min(sb - 60, w + 15);
      eveEnd = Math.max(defEve + 180, Math.min(sb, 1440));
      var fajrNext = 300 + 1440;
      defMorn = (fajrNext > w && fajrNext < sb) ? fajrNext : Math.max(w + 60, sb - 120);
      mornEnd = Math.max(defMorn + 180, sb);
    }
    var out = {
      waking: { start: wk, end: wk + CFG.wakingWindow },
      morning: { start: start("morning", defMorn), end: mornEnd },
      evening: { start: start("evening", defEve), end: eveEnd },
      sleep: { start: sb, end: s + CFG.sleepAfter }
    };
    // A start edited to its end or past it still gets a window.
    MOMENTS.forEach(function (k) { if (out[k].end <= out[k].start) out[k].end = out[k].start + CFG.lateWindow; });
    return out;
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
    var words = {}, sunnah = {};
    library.forEach(function (x) { words[x.id] = x.words; sunnah[x.id] = x.sunnah == null ? null : x.sunnah; });
    return {
      prefs: Object.assign({ level: answers.level, freq: answers.freq, wake: answers.wake, sleep: answers.sleep, cardSize: answers.cardSize,
        recite: answers.recite !== false, moments: momentPrefs({}) }, answers.goal ? { goal: answers.goal } : null),
      adhkar: adhkar, comfort: comfort, hours: hours, words: words, sunnah: sunnah,
      day: emptyDay(null),
      week: { start: null, days: [] }, history: {}, lifetime: 0, review: null, pausedUntil: 0
    };
  }

  function emptyDay(key) {
    return { key: key, done: {}, extra: {}, carry: {}, showing: null, lastShown: null, moments: {}, complete: false,
      shows: {}, skips: {}, laterAt: 0, fresh: 0 };
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
    var t = momentTimes(prefs), mp = momentPrefs(prefs);
    return MOMENTS.some(function (k) { return mp[k].on && m >= t[k].start && m < t[k].start + CFG.momentQuietMin; });
  }

  function fileDay(state, day) {
    var finished = {};
    state.adhkar.forEach(function (a) { finished[a.id] = (day.done[a.id] || 0) >= a.target; });
    return { key: day.key, finished: finished, shows: day.shows || {}, skips: day.skips || {} };
  }

  function syncHistory(s, day) {
    if (!day || !day.key) return;
    s.history = s.history || {};
    var act = active(s), goal = 0, got = 0, said = 0;
    act.forEach(function (a) {
      var d = (day.done && day.done[a.id]) || 0, ex = (day.extra && day.extra[a.id]) || 0;
      goal += a.target;
      got += Math.min(a.target, d);
      said += d + ex;
    });
    var otherIds = {};
    Object.keys(day.done || {}).forEach(function (id) { otherIds[id] = true; });
    Object.keys(day.extra || {}).forEach(function (id) { otherIds[id] = true; });
    Object.keys(otherIds).forEach(function (id) {
      if (!act.some(function (a) { return a.id === id; })) {
        said += ((day.done && day.done[id]) || 0) + ((day.extra && day.extra[id]) || 0);
      }
    });
    if (day.friday && day.friday.salawat) said += day.friday.salawat;
    var mDone = {};
    MOMENTS.forEach(function (k) {
      if (day.moments && day.moments[k] && day.moments[k].done) mDone[k] = true;
    });
    if (said > 0 || Object.keys(mDone).length > 0 || s.history[day.key]) {
      s.history[day.key] = { said: said, got: got, goal: goal, complete: !!day.complete, moments: mDone };
    }
  }

  function rollDay(state, ts) {
    var s = copy(state), key = dayKey(ts, s.prefs), old = s.day.key;
    if (old === key) return s;
    if (old !== null) {
      syncHistory(s, s.day);
      s.week.days.push(fileDay(s, s.day));
      for (var k = nextKey(old); k < key; k = nextKey(k)) s.week.days.push(fileDay(s, emptyDay(k)));
    }
    s.day = emptyDay(key);
    if (!s.review && s.week.days.length >= 7) {
      s.review = review(s);
      s.review.changes.forEach(function (c) { setTo(s, find(s, c.id), c.to); });
    }
    return s;
  }

  function sunnahOf(s, id) { return s.sunnah && s.sunnah[id] != null ? s.sunnah[id] : null; }

  function setTo(s, a, target) {
    var r = ladder(sunnahOf(s, a.id)), rung = 0;
    r.forEach(function (v, i) { if (v <= target) rung = i; });
    a.target = target; a.rung = rung;
  }

  function rungAbove(s, a) {
    return ladder(sunnahOf(s, a.id)).filter(function (v) { return v > a.target; })[0];
  }

  function rungBelow(s, a) {
    return ladder(sunnahOf(s, a.id)).filter(function (v) { return v < a.target; }).pop();
  }

  // Over the 7 latest filed days. Heavy adhkar get no automatic change; hand-set ones only a suggestion.
  function review(state) {
    var days = state.week.days;
    if (days.length < 7) return null;
    days = days.slice(-7);
    var act = active(state), out = { changes: [], heavy: [], suggest: [] };
    var sum = function (f, id) { return days.reduce(function (n, d) { return n + (d[f] && d[f][id] || 0); }, 0); };
    var rate = function (id) { var sh = sum("shows", id); return sh ? sum("skips", id) / sh : 0; };
    act.forEach(function (a) {
      if (sum("shows", a.id) < CFG.heavyMinShows || rate(a.id) < CFG.heavyRate) return;
      if (act.every(function (b) { return b === a || rate(b.id) <= CFG.heavyOthers; })) out.heavy.push(a.id);
    });
    act.forEach(function (a) {
      if (out.heavy.indexOf(a.id) >= 0) return;
      var fin = days.filter(function (d) { return d.finished[a.id] === true; }).length;
      if (!a.auto) {
        var sn = sunnahOf(state, a.id);
        if (!out.suggest.length && fin >= CFG.weekUp && sn != null && a.target < sn) out.suggest.push({ id: a.id, to: rungAbove(state, a) });
        return;
      }
      var to = fin >= CFG.weekUp ? rungAbove(state, a) : fin <= CFG.weekDown ? rungBelow(state, a) : undefined;
      if (to != null) out.changes.push({ id: a.id, from: a.target, to: to });
    });
    return out;
  }

  function answerReview(state, answer) {
    var s = copy(state), rv = s.review;
    if (!rv) return s;
    answer = answer || {};
    rv.changes.forEach(function (c) {
      var a = find(s, c.id);
      if (a && (answer.refuse || []).indexOf(c.id) >= 0) setTo(s, a, c.from);
    });
    Object.keys(answer.heavy || {}).forEach(function (id) {
      var a = find(s, id), how = answer.heavy[id];
      if (!a) return;
      if (how === "rest") a.resting = true;
      if (how === "lighter" && rungBelow(s, a) != null) setTo(s, a, rungBelow(s, a));
    });
    rv.suggest.forEach(function (g) {
      var a = find(s, g.id);
      if (a && (answer.accept || []).indexOf(g.id) >= 0) setTo(s, a, g.to);
    });
    s.review = null;
    s.week = { start: s.day.key, days: [] };
    markComplete(s);
    return s;
  }

  // "Complete" means every active target is reached; the moments are not part of it.
  function markComplete(s) {
    var act = active(s);
    s.day.complete = act.length > 0 && act.every(function (x) { return left(s, x.id) === 0; });
  }

  function setTarget(state, id, n) {
    var s = copy(state), a = find(s, id);
    if (!a) return s;
    setTo(s, a, Math.min(100000, Math.max(1, Math.round(+n) || 1)));
    a.auto = false;
    markComplete(s);
    return s;
  }

  function setAuto(state, id, on) {
    var s = copy(state), a = find(s, id);
    if (!a) return s;
    a.auto = !!on;
    return s;
  }

  function setLevel(state, level) {
    var s = copy(state), st = CFG.start[level];
    if (!st) return s;
    s.prefs = Object.assign({}, s.prefs, { level: level });
    s.comfort = (s.comfort || []).map(function () { return st.comfort; });
    var autoItems = s.adhkar.filter(function (d) { return d.auto; });
    autoItems.forEach(function (d) {
      var r = ladder(sunnahOf(s, d.id)), idx = startRung(r, st.pct);
      d.rung = idx; d.target = r[idx]; d._r = r;
    });
    var cap = slots(s.prefs).length * st.comfort;
    function sum() { return s.adhkar.reduce(function (acc, d) { return acc + d.target; }, 0); }
    while (sum() > cap && autoItems.some(function (d) { return d.rung > 0; })) {
      autoItems.forEach(function (d) { if (d.rung > 0) { d.rung--; d.target = d._r[d.rung]; } });
    }
    autoItems.forEach(function (d) { delete d._r; });
    markComplete(s);
    return s;
  }

  function addCustom(state, item, target) {
    var s = copy(state);
    s.custom = (s.custom || []).filter(function (x) { return x.id !== item.id; }).concat([item]);
    s = add(s, item);
    if (target != null && target > 0) {
      var a = find(s, item.id);
      if (a) { setTo(s, a, Math.min(100000, Math.max(1, Math.round(+target) || 10))); a.auto = true; }
    }
    markComplete(s);
    return s;
  }

  function remove(state, id) {
    var s = copy(state);
    s.adhkar = s.adhkar.filter(function (a) { return a.id !== id; });
    if (s.custom) s.custom = s.custom.filter(function (x) { return x.id !== id; });
    delete s.day.carry[id];
    if (s.day.showing && s.day.showing.id === id) s.day.showing = null;
    markComplete(s);
    return s;
  }

  function add(state, item) {
    var s = copy(state);
    if (find(s, item.id)) return s;
    var sn = item.sunnah == null ? null : item.sunnah, r = ladder(sn), i = startRung(r, CFG.start[s.prefs.level].pct);
    s.adhkar.push({ id: item.id, target: r[i], auto: true, rung: i, resting: false, factor: 1, closeRun: 0, finishRun: 0 });
    s.words = s.words || {}; s.words[item.id] = item.words;
    s.sunnah = s.sunnah || {}; s.sunnah[item.id] = sn;
    markComplete(s);
    return s;
  }



  function rest(state, id, on) {
    var s = copy(state), a = find(s, id);
    if (a) a.resting = !!on;
    markComplete(s);
    return s;
  }

  function pause(state, ts, minutes) {
    var s = copy(state);
    s.pausedUntil = minutes > 0 ? ts + minutes * 60000 : 0;
    return s;
  }

  // How many of the latest filed days in a row had nothing finished.
  function awayDays(state) {
    var n = 0, days = state.week.days;
    for (var i = days.length - 1; i >= 0; i--) {
      var f = days[i].finished;
      if (Object.keys(f).some(function (id) { return f[id]; })) break;
      n++;
    }
    return n;
  }

  function setMoment(state, key, change) {
    var s = copy(state), mp = momentPrefs(s.prefs);
    if (change.on != null) mp[key].on = !!change.on;
    if (change.at !== undefined) mp[key].at = change.at;
    s.prefs.moments = mp;
    return s;
  }

  function momentState(state, ts) {
    var t = momentTimes(state.prefs), mp = momentPrefs(state.prefs), m = nowMin(ts, state.prefs);
    var moments = state.day.key === dayKey(ts, state.prefs) ? state.day.moments : {}, out = {};
    MOMENTS.forEach(function (k) {
      var pos = moments[k];
      out[k] = !mp[k].on ? "off" : pos && pos.done ? "done" : m < t[k].start ? "later"
        : m >= t[k].end ? "missed" : pos ? "running" : "waiting";
    });
    return out;
  }

  function sessionTap(state, ts, key, items) {
    var s = rollDay(state, ts), pos = s.day.moments[key] || { i: 0, n: 0, done: false }, item = items[pos.i];
    if (pos.done || !item) return s;
    s = tap(s, ts, item.id, 1);
    pos = { i: pos.i, n: pos.n + 1, done: false };
    if (pos.n >= item.count) {
      if (pos.i + 1 < items.length) pos = { i: pos.i + 1, n: 0, done: false };
      else pos.done = true;
    }
    s.day.moments[key] = pos;
    return s;
  }

  // items is optional; when given, the position stays inside the set.
  function sessionMove(state, key, dir, items) {
    var s = copy(state), pos = s.day.moments[key] || { i: 0, n: 0, done: false };
    var i = Math.max(0, pos.i + dir);
    if (items) i = Math.min(i, items.length - 1);
    s.day.moments[key] = { i: i, n: i === pos.i ? pos.n : 0, done: pos.done };
    return s;
  }

  // Timestamp of the next ordinary slot after ts, or null when none is left today.
  function nextSlot(s, ts) {
    var step = intervalMin(s), m = nowMin(ts, s.prefs), p = s.day.key.split("-");
    for (var t = min(s.prefs.wake) + step; t < sleepMin(s.prefs); t += step) {
      var at = new Date(+p[0], +p[1] - 1, +p[2], 0, t).getTime();
      if (t > m && at >= s.pausedUntil && !inQuiet(s.prefs, t)) return at;
    }
    return null;
  }

  function nowCard(state, ts, env) {
    var s = rollDay(state, ts), day = s.day, act = active(s);
    if (env && env.permissionMissing) return { kind: "fix" };
    if (s.review) return { kind: "weekly" };
    var t = momentTimes(s.prefs), ms = momentState(s, ts);
    var open = MOMENTS.filter(function (k) { return ms[k] === "waiting" || ms[k] === "running"; })
      .sort(function (a, b) { return t[a].start - t[b].start; });
    if (open.length) return { kind: "moment", key: open[0], running: ms[open[0]] === "running" };
    for (var i = 0; i < act.length; i++) {
      if (day.carry[act[i].id] && (day.complete || left(s, act[i].id) > 0)) return { kind: "continue", id: act[i].id };
    }
    if (!act.length) return { kind: "empty" };
    if (!day.complete) return { kind: "say", id: pick(s, ts, true).id, nextAt: nextSlot(s, ts) };
    return { kind: "complete" };
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
    day.fresh = 0;
    return { state: s, card: card };
  }

  // manual: the person asked for one now, so a pause or a moment's quiet start does not hold it back.
  function pick(s, ts, manual) {
    var day = s.day, act = active(s), m = nowMin(ts, s.prefs), h = new Date(ts).getHours();
    if (!act.length || !manual && (ts < s.pausedUntil || inQuiet(s.prefs, m))) return null;
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
    n = n == null ? 1 : n;
    if (!a) {
      day.extra[id] = (day.extra[id] || 0) + n;
      s.lifetime = (s.lifetime || 0) + n;
      syncHistory(s, day);
      return s;
    }
    var had = day.done[id] || 0, toDone = Math.max(0, Math.min(n, a.target - had));
    day.done[id] = had + toDone;
    if (n > toDone) day.extra[id] = (day.extra[id] || 0) + n - toDone;
    if (had < a.target && day.done[id] >= a.target) delete day.carry[id];
    if (day.showing && day.showing.id === id) {
      day.showing.done = Math.min(day.showing.piece, day.showing.done + n);
      day.fresh = (day.fresh || 0) + n;
    }
    markComplete(s);
    s.lifetime = (s.lifetime || 0) + n;
    syncHistory(s, day);
    return s;
  }

  function leave(state, ts, how) {
    var s = rollDay(state, ts), day = s.day, card = day.showing;
    if (!card) return s;
    day.showing = null;
    var a = find(s, card.id), h = new Date(ts).getHours(), hr = s.hours[h], c = s.comfort[h];
    var finish = card.done === card.piece, partial = !finish && card.done > 0 && day.fresh > 0;
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
    } else if (partial) {
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
    rollDay: rollDay, show: show, tap: tap, leave: leave, intervalMin: intervalMin, left: left, active: active,
    review: review, answerReview: answerReview, setTarget: setTarget, setAuto: setAuto, setLevel: setLevel,
    add: add, addCustom: addCustom, remove: remove, rest: rest, pick: pick,
    pause: pause, awayDays: awayDays, setMoment: setMoment, momentState: momentState,
    sessionTap: sessionTap, sessionMove: sessionMove, nowCard: nowCard };

  if (typeof module === "object" && module.exports) module.exports = E;
  else (window.W = window.W || {}).E = E;
})();
