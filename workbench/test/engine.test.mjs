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

test("functions never change their input", () => {
  const s = E.show(normal, at(9,0)).state, snap = structuredClone(s);
  E.tap(s, at(9,0), "a", 3); E.leave(s, at(9,0), "close"); E.show(s, at(10,0)); E.rollDay(s, at(10,0) + 86400000);
  assert.deepEqual(s, snap);
});
