import test from "node:test";
import assert from "node:assert/strict";
import { createRequire } from "node:module";
const E = createRequire(import.meta.url)("../js/engine.js");

test("ladder", () => {
  assert.deepEqual(E.ladder(100), [10,30,50,70,100]);
  assert.deepEqual(E.ladder(33), [5,10,15,25,33]);
  assert.deepEqual(E.ladder(15), [5,10,15]);
  assert.deepEqual(E.ladder(10), [10]);
  assert.deepEqual(E.ladder(3), [3]);
  assert.deepEqual(E.ladder(null), [10,20,33,50,70,100]);
});

test("clock", () => {
  assert.equal(E.min("06:30"), 390);
  const day = {freq:"hour", wake:"06:00", sleep:"23:00"};
  assert.equal(E.slots(day).length, 16);
  assert.equal(E.slots(day)[0], 420); assert.equal(E.slots(day).at(-1), 1320);
  assert.equal(E.dayStartMin(day), 150);
  const late = {freq:"few", wake:"09:00", sleep:"01:00"};
  assert.deepEqual(E.slots(late), [720,900,1080,1260,1440]);
  assert.equal(E.dayStartMin(late), 300);
  assert.equal(E.dayKey(new Date(2026,10,17,1,0).getTime(), late), "2026-11-16");
  assert.equal(E.dayKey(new Date(2026,10,17,5,30).getTime(), late), "2026-11-17");
  assert.deepEqual(E.momentTimes(late).sleep, {start:1480, end:1560});
  assert.deepEqual(E.momentTimes(day), {
    waking:{start:360,end:420}, morning:{start:375,end:720},
    evening:{start:1020,end:1360}, sleep:{start:1360,end:1440} });
});

test("newState", () => {
  const lib = ["a","b","c","d","e","f","g","h"].map((id,i) => ({id, words:3, sunnah:100, starter:i}));
  const s = (level,freq) => E.newState({level,freq,wake:"06:00",sleep:"23:00",cardSize:"small"}, lib);
  assert.deepEqual(s("new","often").adhkar.map(a => a.target), [30,30,30]);
  assert.deepEqual(s("new","hour").adhkar.map(a => a.target), [10,10,10]);
  assert.deepEqual(s("new","few").adhkar.map(a => a.target), [10,10,10]);
  assert.equal(s("some","often").adhkar.length, 5);
  assert.equal(s("daily","often").adhkar.length, 8);
  assert.equal(s("daily","often").comfort[9], 33);
  const st = s("new","often");
  assert.equal(st.comfort.length, 24);
  assert.equal(st.hours.length, 24);
  assert.deepEqual(st.adhkar[0], {id:"a",target:30,auto:true,rung:1,resting:false,factor:1,closeRun:0,finishRun:0});
  assert.equal(st.day.key, null);
});

const at = (h, m) => new Date(2026, 10, 16, h, m).getTime();
const lib5 = ["a","b","c","d","e","f","g","h"].map((id,i) => ({id, words:3, sunnah:100, starter:i}));
const fresh = () => E.newState({level:"some",freq:"hour",wake:"06:00",sleep:"23:00",cardSize:"small"}, lib5);
const normal = E.rollDay(fresh(), at(8,0));
const edit = (s, f) => { const c = structuredClone(s); f(c); return c; };
const showLeave = (s, ts, taps, how) => {
  let r = E.show(s, ts).state;
  if (taps) r = E.tap(r, ts, r.day.showing.id, taps);
  return E.leave(r, ts, how);
};
const finishOne = (s, ts) => {
  const r = E.show(s, ts);
  return E.leave(E.tap(r.state, ts, r.card.id, r.card.piece), ts, "close");
};
const tapAll = (s, ts) => E.active(s).reduce((r, a) => E.tap(r, ts, a.id, E.left(r, a.id)), s);
const showFor = (o) => E.show(edit(normal, s => {
  s.adhkar[0].target = o.target;
  if (o.words) s.words.a = o.words;
  if (o.comfort) s.comfort.fill(o.comfort);
}), at(22,0)).card;

test("learning", () => {
  const after3Finishes = finishOne(finishOne(finishOne(normal, at(9,0)), at(9,5)), at(9,10));
  assert.equal(after3Finishes.comfort[9], 13);
  const afterPartial = showLeave(normal, at(9,0), 4, "close");
  assert.equal(afterPartial.comfort[9], 7);
  assert.deepEqual(afterPartial.day.carry.a, {piece:10, done:4});
  assert.equal(afterPartial.day.done.a, 4);
  assert.deepEqual(E.show(afterPartial, at(14,0)).card, {id:"a", piece:10, done:4, extra:false});
  const afterOneClose = showLeave(normal, at(9,0), 0, "close");
  const afterTwoCloses = showLeave(afterOneClose, at(9,1), 0, "close");
  assert.equal(afterOneClose.comfort[9], 10); assert.equal(afterTwoCloses.comfort[9], 8);
  const afterThreeIgnores = [0,1,2].reduce((s, m) => showLeave(s, at(9,m), 0, "ignore"), normal);
  assert.equal(afterThreeIgnores.comfort[9], 5); assert.equal(afterThreeIgnores.adhkar[0].factor, 1);
  const before = normal;
  const afterLater = showLeave(before, at(9,0), 0, "later");
  assert.deepEqual(afterLater.comfort, before.comfort);
  assert.equal(afterLater.day.laterAt, at(9,10));
  const onlyA = edit(normal, s => s.adhkar.slice(1).forEach(a => { a.resting = true; }));
  const afterTwoClosesOfA = showLeave(showLeave(onlyA, at(9,0), 0, "close"), at(9,1), 0, "close");
  assert.equal(afterTwoClosesOfA.adhkar[0].factor, 0.75);
});

test("a carried card left again with no new taps is a plain skip", () => {
  const afterPartial = showLeave(normal, at(9,0), 4, "close");
  const closedAgain = showLeave(afterPartial, at(14,0), 0, "close");
  assert.equal(closedAgain.comfort[14], 10);
  assert.deepEqual(closedAgain.day.carry.a, {piece:10, done:4});
  assert.equal(closedAgain.day.skips.a, 1);
  assert.equal(closedAgain.hours[14].closeRun, 1);
  assert.equal(closedAgain.adhkar[0].closeRun, 1);
  const ignoredAgain = showLeave(afterPartial, at(14,0), 0, "ignore");
  assert.equal(ignoredAgain.hours[14].ignoreRun, 1);
  assert.deepEqual(ignoredAgain.day.carry.a, {piece:10, done:4});
  const tappedAgain = showLeave(afterPartial, at(14,0), 2, "close");
  assert.deepEqual(tappedAgain.day.carry.a, {piece:10, done:6});
  assert.equal(tappedAgain.comfort[14], 8);
});

test("piece size", () => {
  assert.equal(showFor({target:1}).piece, 1);
  assert.equal(showFor({target:100, words:40, comfort:10}).piece, 1);
  assert.equal(showFor({target:3, comfort:33}).piece, 3);
});

test("which dhikr, completion and nothing to show", () => {
  const aFinishedBNot = E.tap(normal, at(9,0), "a", 30);
  assert.notEqual(E.show(aFinishedBNot, at(10,0)).card.id, "a");
  const allDone = tapAll(normal, at(15,0));
  assert.equal(allDone.day.complete, true);
  assert.equal(E.intervalMin(allDone), 120);
  assert.equal(E.show(allDone, at(16,0)).card.extra, true);
  const allResting = edit(normal, s => s.adhkar.forEach(a => { a.resting = true; }));
  assert.equal(E.show(allResting, at(10,0)).card, null);
  const paused = edit(normal, s => { s.pausedUntil = at(11,0); });
  assert.equal(E.show(paused, at(10,0)).card, null);
  assert.equal(E.show(normal, at(17,5)).card, null);
});

test("rollDay", () => {
  assert.equal(E.rollDay(normal, at(10,0) + 8*86400000).week.days.length >= 7, true);
  const done = E.rollDay(E.tap(normal, at(9,0), "a", 30), at(10,0) + 86400000);
  assert.deepEqual(done.week.days[0], {key:"2026-11-16", finished:{a:true,b:false,c:false,d:false,e:false}, shows:{}, skips:{}});
  assert.deepEqual(done.day.done, {});
});

// Seven filed days before 2026-11-16; fin[id] is how many of them the dhikr finished.
const weekOf = (ids, o, dayFor) => edit(normal, s => {
  s.adhkar = s.adhkar.filter(a => ids.includes(a.id));
  s.adhkar.forEach(a => Object.assign(a, o));
  s.week.days = [9,10,11,12,13,14,15].map((d, i) => ({key:"2026-11-" + d, ...dayFor(i)}));
});
const weekWith = (fin, o = {}) => weekOf(Object.keys(fin), o, i => ({
  finished: Object.fromEntries(Object.keys(fin).map(id => [id, i < fin[id]])), shows:{}, skips:{} }));
const weekShows = (t) => weekOf(Object.keys(t), {}, i => ({
  finished: Object.fromEntries(Object.keys(t).map(id => [id, i < 4])),
  shows: i ? {} : Object.fromEntries(Object.keys(t).map(id => [id, t[id].shows])),
  skips: i ? {} : Object.fromEntries(Object.keys(t).map(id => [id, t[id].skips])) }));
const reviewOf = (s) => E.review(s);
// The seventh day gets filed by rollDay: drop the last filed day, then roll from 2026-11-16 to 11-17.
const filedBy = (s) => E.rollDay(edit(s, x => x.week.days.pop()), at(10,0) + 86400000);
const s = normal, lib = lib5;
const withReview = edit(normal, x => { x.review = {changes:[], heavy:[], suggest:[]}; });
const withCarry = showLeave(normal, at(9,0), 4, "close");
const allDone = tapAll(normal, at(15,0));
const allResting = edit(normal, x => x.adhkar.forEach(a => { a.resting = true; }));

test("weekly review", () => {
  assert.equal(E.review(normal), null);
  assert.deepEqual(reviewOf(weekWith({a:5})).changes, [{id:"a", from:30, to:50}]);
  assert.deepEqual(reviewOf(weekWith({a:2})).changes, [{id:"a", from:30, to:10}]);
  assert.deepEqual(reviewOf(weekWith({a:4})).changes, []);
  assert.deepEqual(reviewOf(weekWith({a:7}, {target:100})).changes, []);              // never past the sunnah number
  assert.deepEqual(reviewOf(weekWith({a:7}, {auto:false})).changes, []);              // hand-set is never changed
  assert.equal(reviewOf(weekWith({a:7}, {auto:false})).suggest.length, 1);
  assert.deepEqual(reviewOf(weekWith({a:7, b:7}, {auto:false})).suggest, [{id:"a", to:50}]);
  assert.deepEqual(reviewOf(weekShows({a:{shows:5, skips:3}, b:{shows:10, skips:2}})).heavy, ["a"]);
  assert.deepEqual(reviewOf(weekShows({a:{shows:4, skips:4}, b:{shows:10, skips:0}})).heavy, []);   // under 5 appearances
  assert.deepEqual(reviewOf(weekShows({a:{shows:5, skips:3}, b:{shows:10, skips:4}})).heavy, []);   // the others skip too
  const heavyDown = edit(weekShows({a:{shows:5, skips:3}, b:{shows:10, skips:2}}), x => x.week.days.forEach(d => { d.finished.a = false; }));
  assert.deepEqual(reviewOf(heavyDown).changes, []);                                    // heavy gets no automatic change

  const up = filedBy(weekWith({a:5}));
  assert.deepEqual(up.review.changes, [{id:"a", from:30, to:50}]);
  assert.equal(up.adhkar[0].target, 50); assert.equal(up.adhkar[0].rung, 2);
  assert.equal(up.week.days.length, 7);
  assert.equal(E.answerReview(up, {refuse:["a"]}).adhkar[0].target, 30);
  const answered = E.answerReview(up, {});
  assert.equal(answered.review, null); assert.deepEqual(answered.week, {start:"2026-11-17", days:[]});
  assert.equal(answered.adhkar[0].target, 50);
  const later = E.rollDay(up, at(10,0) + 2*86400000);                                  // days pile up while it waits
  assert.deepEqual(later.review, up.review); assert.equal(later.week.days.length, 8); assert.equal(later.adhkar[0].target, 50);

  const heavy = filedBy(weekShows({a:{shows:5, skips:3}, b:{shows:10, skips:2}}));
  assert.deepEqual(heavy.review.heavy, ["a"]);
  assert.equal(E.answerReview(heavy, {heavy:{a:"rest"}}).adhkar[0].resting, true);
  assert.equal(E.answerReview(heavy, {heavy:{a:"lighter"}}).adhkar[0].target, 10);
  assert.equal(E.answerReview(heavy, {heavy:{a:"keep"}}).adhkar[0].target, 30);

  const suggested = filedBy(edit(weekWith({a:7}, {auto:false}), x => { x.day.done.a = 30; }));
  assert.equal(suggested.adhkar[0].target, 30);
  const accepted = E.answerReview(suggested, {accept:["a"]}).adhkar[0];
  assert.equal(accepted.target, 50); assert.equal(accepted.auto, false);
});

test("editing my adhkar and pause", () => {
  assert.equal(E.add(s, lib[0]).adhkar.length, s.adhkar.length);                       // already added
  const added = E.add(s, {id:"z", words:3, sunnah:33});
  assert.deepEqual(added.adhkar.at(-1), {id:"z",target:15,auto:true,rung:2,resting:false,factor:1,closeRun:0,finishRun:0});
  assert.equal(added.sunnah.z, 33); assert.equal(added.words.z, 3);
  assert.equal(E.add(s, {id:"y", words:3, sunnah:null}).adhkar.at(-1).target, 50);
  assert.equal(E.setTarget(s, "a", 0).adhkar[0].target, 1);
  assert.equal(E.setTarget(s, "a", 200000).adhkar[0].target, 100000);
  assert.equal(E.setTarget(s, "a", 70).adhkar[0].auto, false);
  assert.equal(E.remove(s, "a").adhkar.some(a => a.id === "a"), false);
  assert.equal(E.rest(s, "a", true).adhkar[0].resting, true);
  assert.equal(E.rest(E.rest(s, "a", true), "a", false).adhkar[0].resting, false);
  const doneButB = E.tap(s, at(9,0), "a", 30);
  assert.equal(E.rest(edit(doneButB, x => x.adhkar.slice(2).forEach(a => { a.resting = true; })), "b", true).day.complete, true);
  assert.equal(E.show(E.pause(s, at(10,0), 60), at(10,30)).card, null);
  assert.notEqual(E.show(E.pause(s, at(10,0), 60), at(11,1)).card, null);
  assert.equal(E.pause(E.pause(s, at(10,0), 60), at(10,5), 0).pausedUntil, 0);
  assert.equal(E.awayDays(E.rollDay(s, at(10,0) + 8*86400000)) >= 7, true);
  assert.equal(E.awayDays(weekWith({a:5})), 2);
});

test("moments and sessions", () => {
  assert.equal(E.momentState(s, at(13,0)).morning, "missed");
  assert.deepEqual(E.momentState(s, at(6,20)), {waking:"waiting", morning:"waiting", evening:"later", sleep:"later"});
  const items = [{id:"a", count:2}, {id:"zz", count:1}];
  let r = E.sessionTap(s, at(6,20), "morning", items);
  assert.deepEqual(r.day.moments.morning, {i:0, n:1, done:false});
  assert.equal(E.momentState(r, at(6,25)).morning, "running");
  assert.equal(r.day.done.a, 1);
  r = E.sessionTap(r, at(6,21), "morning", items);
  assert.deepEqual(r.day.moments.morning, {i:1, n:0, done:false});
  r = E.sessionTap(r, at(6,22), "morning", items);
  assert.equal(r.day.moments.morning.done, true);
  assert.equal(r.day.done.a, 2); assert.equal(r.day.done.zz, undefined);
  assert.equal(E.momentState(r, at(13,0)).morning, "done");
  assert.deepEqual(E.sessionMove(E.sessionTap(s, at(6,20), "morning", items), "morning", 1).day.moments.morning, {i:1, n:0, done:false});
  assert.deepEqual(E.sessionMove(s, "morning", -1).day.moments.morning, {i:0, n:0, done:false});
  const off = E.setMoment(s, "morning", {on:false});
  assert.equal(E.momentState(off, at(10,0)).morning, "off");
  assert.equal(off.prefs.moments.morning.at, null);
  const moved = E.setMoment(s, "morning", {at:420});
  assert.deepEqual(E.momentTimes(moved.prefs).morning, {start:420, end:720});
  assert.deepEqual(E.momentTimes(s.prefs).morning, {start:375, end:720});
  assert.deepEqual(E.momentTimes(E.setMoment(s, "morning", {at:780}).prefs).morning, {start:780, end:840}); // start past its end
  assert.notEqual(E.show(normal, at(7,5)).card, null);
  assert.equal(E.show(moved, at(7,5)).card, null);                                     // quiet start of a moved moment
  assert.notEqual(E.show(E.setMoment(E.setMoment(s, "morning", {on:false}), "waking", {on:false}), at(6,0)).card, null);
});

test("now card", () => {
  assert.equal(E.nowCard(s, at(10,0), {permissionMissing:true}).kind, "fix");
  assert.equal(E.nowCard(withReview, at(10,0), {}).kind, "weekly");
  assert.equal(E.nowCard(s, at(6,20), {}).kind, "moment");
  assert.equal(E.nowCard(withCarry, at(14,0), {}).kind, "continue");
  assert.equal(E.nowCard(s, at(14,0), {}).kind, "say");
  assert.equal(E.nowCard(allDone, at(16,0), {}).kind, "complete");
  assert.equal(E.nowCard(allResting, at(14,0), {}).kind, "empty");
  assert.equal(E.nowCard(s, at(10,0), {}).kind, "moment");                             // morning waits until noon
  assert.deepEqual(E.nowCard(s, at(6,20), {}), {kind:"moment", key:"waking", running:false});
  const morningRunning = E.sessionTap(s, at(6,20), "morning", [{id:"a", count:5}]);
  assert.deepEqual(E.nowCard(morningRunning, at(6,30), {}), {kind:"moment", key:"waking", running:false}); // earlier unfinished wins
  assert.deepEqual(E.nowCard(morningRunning, at(7,0), {}), {kind:"moment", key:"morning", running:true});
  assert.equal(E.nowCard(E.setMoment(s, "waking", {on:false}), at(6,10), {}).kind, "say");
});

test("functions never change their input", () => {
  const s = E.show(normal, at(9,0)).state, snap = structuredClone(s);
  E.tap(s, at(9,0), "a", 3); E.leave(s, at(9,0), "close"); E.show(s, at(10,0)); E.rollDay(s, at(10,0) + 86400000);
  E.pause(s, at(9,0), 60); E.add(s, {id:"z", words:1, sunnah:3}); E.remove(s, "a"); E.rest(s, "a", true);
  E.setTarget(s, "a", 5); E.setMoment(s, "waking", {on:false}); E.sessionTap(s, at(9,0), "morning", [{id:"a", count:3}]);
  E.sessionMove(s, "morning", 1); E.nowCard(s, at(9,0), {}); E.momentState(s, at(9,0)); E.awayDays(s);
  assert.deepEqual(s, snap);
  const up = filedBy(weekWith({a:5})), upSnap = structuredClone(up);
  E.answerReview(up, {refuse:["a"], heavy:{a:"rest"}, accept:["a"]}); E.review(up);
  assert.deepEqual(up, upSnap);
});

test("non-list adhkar credit, setAuto, setLevel, and addCustom", () => {
  const r = E.sessionTap(s, at(6, 20), "waking", [{ id: "non_list_1", count: 1 }]);
  assert.equal(r.day.done.non_list_1, undefined);
  assert.equal(r.day.extra.non_list_1, 1);
  assert.equal(r.lifetime, 1);
  assert.equal(r.history["2026-11-16"].said, 1);

  const manual = E.setTarget(s, "a", 50);
  assert.equal(manual.adhkar[0].auto, false);
  assert.equal(E.setAuto(manual, "a", true).adhkar[0].auto, true);

  const eased = E.setLevel(manual, "new");
  assert.equal(eased.prefs.level, "new");
  assert.equal(eased.adhkar[0].target, 50); // manual auto=false stays untouched
  assert.equal(eased.adhkar[1].target, 10); // auto=true rescales gently

  const withCustom = E.addCustom(s, { id: "cust_1", ar: "دعاء", words: 2, sunnah: null, custom: true }, 12);
  assert.equal(withCustom.custom.length, 1);
  assert.equal(withCustom.adhkar.find(x => x.id === "cust_1").target, 12);
  assert.equal(E.remove(withCustom, "cust_1").custom.length, 0);

  // Night-shift schedule: wakes at 18:00 (6 PM), sleeps at 09:00 (9 AM)
  const shiftTimes = E.momentTimes({ freq: "hour", wake: "18:00", sleep: "09:00" });
  assert.equal(shiftTimes.waking.start, 1080);   // 18:00
  assert.equal(shiftTimes.evening.start, 1095);  // 18:15 (evening, not while asleep)
  assert.equal(shiftTimes.morning.start, 1740);  // 05:00 AM next morning (before 09:00 sleep)
  assert.equal(shiftTimes.sleep.start, 1960);    // 08:40 AM (20 min before 09:00 sleep)
});
