import test from "node:test";
import assert from "node:assert/strict";
import { createRequire } from "node:module";
const req = createRequire(import.meta.url);
const E = req("../js/engine.js");
const D = req("../js/data.js");
const Sim = req("../js/sim.js");

const A = { level: "some", freq: "hour", wake: "06:00", sleep: "23:00", cardSize: "small" };
const t0 = new Date(2026, 10, 9, 6, 0).getTime();
const t1 = new Date(2026, 10, 10, 23, 0).getTime();
const fresh = () => E.newState(A, D.LIB);
const finished = (s) => s.adhkar.filter((a) => E.left(s, a.id) === 0).length;
const open = (s) => s.adhkar.filter((a) => E.left(s, a.id) > 0).length;

test("example data", () => {
  assert.ok(D.LIB.length >= 24);
  const ids = new Set(D.LIB.map((x) => x.id));
  assert.equal(ids.size, D.LIB.length);
  const st = D.LIB.filter((x) => x.starter != null).map((x) => x.starter).sort();
  assert.deepEqual(st, [0, 1, 2, 3, 4, 5, 6, 7]);
  assert.ok(D.LIB.filter((x) => x.starter != null && x.sunnah != null && x.sunnah > 1).length >= 5);
  assert.ok(D.LIB.some((x) => x.starter == null && x.words > 40));
  assert.ok(D.LIB.some((x) => x.starter == null && x.sunnah === 1));
  const groups = D.GROUPS.map((g) => g.id);
  assert.deepEqual(groups, ["morning", "evening", "sleep", "afterPrayer", "tasabih", "duas"]);
  D.LIB.forEach((x) => {
    assert.ok(x.ar && x.translit && x.words > 0 && x.groups.length, x.id);
    x.groups.forEach((g) => assert.ok(groups.includes(g), x.id + " " + g));
  });
  Object.keys(D.SETS).forEach((k) => {
    const set = D.SETS[k];
    assert.ok(set.length >= 3 && set.length <= 12, k);
    set.forEach((it) => assert.ok(ids.has(it.id) && it.count >= 1, k + " " + it.id));
  });
  assert.deepEqual(Object.keys(D.SETS), ["waking", "morning", "evening", "sleep"]);
});

test("a dua with no sunnah number uses the free ladder", () => {
  const free = D.LIB.filter((x) => x.sunnah === null);
  assert.ok(free.length >= 1);
  free.forEach((x) => assert.ok(x.groups.includes("duas"), x.id));
  const s = E.add(fresh(), free[0]);
  assert.ok(E.ladder(null).includes(s.adhkar.find((a) => a.id === free[0].id).target));
  assert.deepEqual(E.ladder(null), [10, 20, 33, 50, 70, 100]);
});

test("same inputs give the same log", () => {
  const s = fresh();
  assert.deepEqual(Sim.run(s, t0, t1, "responsive", 7).log, Sim.run(s, t0, t1, "responsive", 7).log);
  assert.notDeepEqual(Sim.run(s, t0, t1, "responsive", 7).log, Sim.run(s, t0, t1, "responsive", 8).log);
});

test("people", () => {
  assert.deepEqual(Sim.PEOPLE, ["responsive", "busyNoon", "ignoresOne", "away"]);
  const s = fresh();
  const away = Sim.run(s, t0, t0 + 86400000, "away", 1);
  assert.ok(away.log.length > 0);
  assert.equal(away.log.every((x) => x.how === "ignore"), true);
  const busy = Sim.run(s, t0, t0 + 86400000, "busyNoon", 1).log;
  busy.forEach((x) => {
    const h = new Date(x.ts).getHours();
    assert.equal(x.how === "ignore", h >= 11 && h < 15, String(h));
  });
  const one = Sim.run(s, t0, t0 + 86400000, "ignoresOne", 1).log;
  assert.ok(one.some((x) => x.id === Sim.IGNORED));
  one.forEach((x) => assert.equal(x.how === "close", x.id === Sim.IGNORED));
  const r = Sim.run(s, t0, t1, "responsive", 3).log;
  const fin = r.filter((x) => x.how === "finish").length;
  assert.ok(fin / r.length >= 0.8, fin + " of " + r.length);
  r.forEach((x) => {
    assert.ok(["ts", "id", "piece", "did", "how", "comfortBefore", "comfortAfter"].every((k) => k in x));
    assert.ok(x.did >= 0 && x.did <= x.piece);
  });
});

test("example days", () => {
  const first = Sim.day("first");
  assert.equal(first.state, null);
  assert.equal(typeof first.now, "number");

  const noon = Sim.day("noon");
  const nd = new Date(noon.now);
  assert.ok(nd.getDay() >= 1 && nd.getDay() <= 5 && nd.getHours() === 12);
  assert.equal(noon.state.review, null);
  assert.equal(E.nowCard(noon.state, noon.now, {}).kind, "say");
  assert.ok(finished(noon.state) >= 1 && open(noon.state) >= 2);

  const complete = Sim.day("complete");
  assert.equal(complete.state.day.complete, true);
  assert.equal(E.nowCard(complete.state, complete.now, {}).kind, "complete");

  const missed = Sim.day("missed");
  assert.ok(E.awayDays(missed.state) >= 7);
  assert.ok(missed.state.review);
  assert.equal(E.nowCard(missed.state, missed.now, {}).kind, "weekly");

  const up = Sim.day("weekup");
  assert.equal(E.nowCard(up.state, up.now, {}).kind, "weekly");
  assert.ok(up.state.review.changes.some((c) => c.to > c.from));

  const down = Sim.day("weekdown");
  assert.ok(down.state.review.changes.some((c) => c.to < c.from));
  assert.ok(E.awayDays(down.state) < 3);

  assert.equal(Sim.day("weekheavy").state.review.heavy.length, 1);
});
