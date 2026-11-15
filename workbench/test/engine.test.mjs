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
