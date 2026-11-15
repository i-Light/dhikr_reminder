# Dhikr Workbench Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A clickable web prototype of the reimagined dhikr app inside a workbench with a pin-a-comment tool, tracked in `workbench/`.

**Architecture:** Plain script files loaded by `index.html` from disk (no modules, no build). React 18 and htm from `vendor/`, everything hung on one global `W`. The adapting rules live in `js/engine.js` as pure functions that also load in Node, so they are unit tested; screens are checked by driving headless Edge at a URL and reading the DOM.

**Tech Stack:** HTML, CSS custom properties, React 18 UMD, htm, Node 24 (`node --test`, `node:http`), Edge or Chrome headless for smoke tests.

**Spec:** `docs/superpowers/specs/2026-11-16-dhikr-workbench-design.md` (read it first; section numbers below point into it).

## Global Constraints

- Everything lives in `workbench/`. No file outside it changes except this plan and the spec.
- Opens by double-clicking `workbench/index.html`. No install, no build, no network request of any kind. Scripts are classic `<script src>` tags; no `type="module"`, no `import`.
- No `package.json`, no `node_modules`. Tests use only Node built-ins.
- Egyptian Arabic first, natural, not word for word. English second. `dir="rtl"` is the primary layout.
- No em dashes, en dashes, curly quotes, arrows, ellipsis characters or emojis anywhere in `workbench/` (text, comments, docs).
- No emojis and no stock icon pack. One hand-drawn SVG icon family.
- Body text at least 18 px, dhikr text at least 28 px, touch targets at least 56 px inside the phone frame.
- No hidden gestures: no press-and-hold, no swipe-only action.
- Western digits.
- Git: work on branch `workbench-prototype`. The main checkout has unrelated uncommitted changes: stage only named paths under `workbench/` and `docs/superpowers/`, never `git add -A` or `git add .`. Commit only if the owner has said to commit.
- Python is not installed on this PC. Use Node for any scripting.

## Review Focus

1. **Sleep time after midnight** (wake 09:00, sleep 01:00): slots, the day boundary and the moment windows must still be right. Pinned in Task 2.
2. **Tiny and long adhkar** (target 1, a 40-word dhikr, target smaller than comfort): a piece is never below 1 and never above what is left. Pinned in Task 3.
3. **Broken saved data** (`comments.json` missing, empty or not JSON; browser storage holding junk or unavailable): the workbench still opens with defaults. Pinned in Tasks 1 and 8.
4. **Nothing to remind about** (every dhikr rested or removed, or the day complete): `E.show` answers `null` or an extra, Today shows an empty state with "Add a dhikr", nothing throws. Pinned in Tasks 3 and 11.
5. **Long Arabic with tashkeel at the largest text size** in the small card and in list rows: no clipped or overlapping text. Pinned in Task 17.

## Conventions every task uses

- **Global:** `window.W`. Files add to it inside an IIFE with `"use strict"`.
- **Dual-load files** (`engine.js`, `sim.js`, `strings.js`, `data.js`): end with
  `if (typeof module === "object" && module.exports) module.exports = X; else window.W.<name> = X;`
- **URL contract** (read once at start, then kept in state): `?day=first|noon|complete|missed|weekup|weekdown|weekheavy&lang=ar|en&frame=phone|windows&look=a|b&theme=light|dark&size=1|2|3&route=<route>&popup=small|full|moment|lock`. Missing keys fall back to saved state, then to `day=first, lang=ar, frame=phone, look=a, theme=light, size=1, route=today`.
- **Test hooks** (URL keys read by `app.js` only, each added by the task that first uses it): `junk=1`, `seedComment=<data-id>`, `restAll=1`, `long=1`, `sim=<person>`, `simTo=HH:MM`, `simBack=HH:MM`.
- **Routes:** `onboarding/1` to `onboarding/6`, `today`, `adhkar`, `adhkar/<id>`, `add`, `add/<group>`, `moments`, `moments/<key>`, `session/<key>`, `count/<id>`, `weekly`, `more`, `more/<row>`, `days`, `gallery`.
- **Anchors:** every screen root has `data-screen="<route>"`; every part a person can act on or that a test reads has a stable `data-id` (examples: `now-card`, `now-button`, `today-row-<id>`, `tab-today`, `card`, `card-count`, `card-later`, `card-close`).
- **Ready and error marks:** after the first render `document.documentElement.dataset.ready = "1"`. `window.onerror` and `unhandledrejection` set `dataset.error` to the message.
- **Words:** all visible text comes from `W.t(key, vars)`. No literal UI text in screen files.
- **Storage keys:** `dhikr-wb-state`, `dhikr-wb-ui`, `dhikr-wb-comments`.

## File structure

```
workbench/
  README.md  index.html  serve.mjs  comments.json
  vendor/  react.production.min.js  react-dom.production.min.js  htm.umd.js
  fonts/
  css/  tokens.css  app.css  workbench.css  motion.css
  js/   core.js strings.js data.js engine.js sim.js icons.js ui.js card.js
        onboarding.js today.js adhkar.js add.js moments.js weekly.js more.js
        frames.js gallery.js wb.js comments.js app.js
  test/ helpers.mjs engine.test.mjs sim.test.mjs text.test.mjs serve.test.mjs smoke.test.mjs
```

Script order in `index.html`: vendor (react, react-dom, htm), then `core strings data engine sim icons ui card onboarding today adhkar add moments weekly more frames gallery wb comments app`.

---

### Task 1: Shell, server and test harness

**Files:**
- Create: `workbench/index.html`, `workbench/js/core.js`, `workbench/js/app.js`, `workbench/serve.mjs`, `workbench/comments.json` (content `[]`), `workbench/vendor/*` (copy the three files from `E:\IMA work\Code\gratovo_toolbox\design\workbench-v7\vendor\`), `workbench/css/workbench.css`, `workbench/README.md`
- Test: `workbench/test/helpers.mjs`, `workbench/test/serve.test.mjs`, `workbench/test/smoke.test.mjs`, `workbench/test/text.test.mjs`

**Interfaces:**
- Produces (`core.js`): `W.R` (React), `W.html`, `W.useState/useEffect/useRef/useMemo`, `W.cx(...)`, `W.clamp`, `W.uid(prefix)`, `W.LS.get(key, fallback)`, `W.LS.set(key, value)` (both swallow storage errors and bad JSON), `W.S.state = {eng, ui}`, `W.useApp()`, `W.emit()`, `W.act(label, fn)` (snapshots for undo, runs `fn(state)`, saves, emits), `W.undo()`, `W.go(route)`, `W.U()` (the ui object), `W.readUrl()`, `W.served` (boolean, set after `GET /api/ping` answers).
- Produces (`ui` state): `{day, lang, frame, look, theme, size, route, popup, commenting, panel}`.
- Produces (`serve.mjs`): listens on `127.0.0.1:4173` (port from `PORT` env), serves files under `workbench/` only, `GET /api/ping` gives `{"ok":true}`, `GET /api/comments` gives the file's array (`[]` when missing, empty or not JSON), `PUT /api/comments` with a JSON array writes it through a temp file then rename, anything else 404, bodies over 2 MB refused with 413. Exports `start(port, dir)` returning the server, and runs it when called directly.
- Produces (`helpers.mjs`): `browserPath()` (Edge at `C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe`, then Chrome at `C:\Program Files\Google\Chrome\Application\chrome.exe`, else `null`), `dumpDom(query)` (runs the browser with `--headless=new --disable-gpu --virtual-time-budget=4000 --dump-dom` on `file:///.../workbench/index.html?<query>` and returns the HTML), `shot(query, outPath, width, height)`.

- [ ] **Step 1: Write the failing tests**

`serve.test.mjs`, using a temp copy of the folder:
```js
test("ping", async () => { assert.deepEqual(await getJson("/api/ping"), {ok:true}); });
test("comments round trip", async () => {
  await put("/api/comments", [{id:"c1", text:"x"}]);
  assert.deepEqual(await getJson("/api/comments"), [{id:"c1", text:"x"}]);
});
test("broken comments file reads as empty", async () => {
  writeFileSync(join(dir, "comments.json"), "{not json");
  assert.deepEqual(await getJson("/api/comments"), []);
});
test("cannot read outside the folder", async () => {
  assert.equal((await fetch(base + "/..%2f..%2fpubspec.yaml")).status, 404);
});
```
`smoke.test.mjs` (skips with a clear message when `browserPath()` is null):
```js
test("opens with no error", () => {
  const dom = dumpDom("day=first&lang=ar");
  assert.match(dom, /data-ready="1"/);
  assert.doesNotMatch(dom, /data-error=/);
  assert.match(dom, /dir="rtl"/);
});
test("junk in storage does not stop it", () => { /* dumpDom("junk=1") : app.js writes "{" into all three keys before start when junk=1 */ });
```
`text.test.mjs`: walks every `.js`, `.css`, `.html`, `.md`, `.mjs` under `workbench/` except `vendor/` and fails on any of: U+2014, U+2013, U+2018, U+2019, U+201C, U+201D, U+2026, U+2190 to U+21FF, U+1F000 to U+1FAFF, U+2600 to U+27BF.

- [ ] **Step 2: Run them, expect failure**

Run: `node --test workbench/test/`. Expected: fails, files missing.

- [ ] **Step 3: Build the shell**

`index.html` (`<html lang="ar" dir="rtl">`), the script tags in the order above (missing later files are added by their tasks), `core.js`, `app.js` rendering a top bar titled from `W.t` and an empty stage `data-id="stage"`, `serve.mjs`, `README.md` (how to open, how to run the server, how to run tests).

- [ ] **Step 4: Run tests, expect pass**

Run: `node --test workbench/test/`. Expected: all pass.

- [ ] **Step 5: Commit** `workbench: shell, comment server and test harness` (paths: `workbench/`).

---

### Task 2: Engine, the fixed rules (ladder, start, clock)

**Files:**
- Create: `workbench/js/engine.js`
- Test: `workbench/test/engine.test.mjs`

**Interfaces:**
- Produces: `E.CFG` (one object at the top holding every number in spec section 9: `intervals {few:180, hour:60, often:20}`, `laterMin 10`, `ladderPct [10,30,50,70,100]`, `freeLadder [10,20,33,50,70,100]`, `start {new:{pct:30,count:3,comfort:5}, some:{pct:50,count:5,comfort:10}, daily:{pct:100,count:8,comfort:33}}`, `comfortMax 100`, `growAfter 3`, `growBy 1.25`, `closeRun 2`, `closeBy 0.75`, `ignoreRun 3`, `ignoreBy 0.5`, `factorMin 0.25`, `factorStep 0.75`, `longWords 6`, `goodRate 0.7`, `goodMinShows 3`, `stretch 1.5`, `weekUp 5`, `weekDown 2`, `heavyMinShows 5`, `heavyRate 0.6`, `heavyOthers 0.3`, `extrasTimes 2`, `momentQuietMin 20`, `morningAfterWake 15`, `morningEnd 720`, `eveningStart 1020`, `sleepBefore 20`, `sleepAfter 60`, `wakingWindow 60`).
- Produces: `E.min("06:30")` gives 390. `E.ladder(sunnah)` gives an ascending array. `E.slots(prefs)` gives minutes from the day's midnight (may pass 1440). `E.dayStartMin(prefs)`. `E.dayKey(ts, prefs)` gives `"YYYY-MM-DD"`. `E.momentTimes(prefs)` gives `{waking, morning, evening, sleep}` each `{start, end}` in minutes. `E.newState(answers, library)` where `answers = {level:"new"|"some"|"daily", freq:"few"|"hour"|"often", wake, sleep, cardSize:"small"|"full"}` and `library` items are `{id, words, sunnah|null, starter:number|undefined}` (starter is the order among the well-known ones).
- Produces the state shape used by every later task:
```js
{ prefs:{level,freq,wake,sleep,cardSize},
  adhkar:[{id,target,auto:true,rung:0,resting:false,factor:1,closeRun:0,finishRun:0}],
  comfort:[/*24*/], hours:[/*24 x*/{finishRun:0,closeRun:0,ignoreRun:0,shown:0,finished:0}],
  day:{key,done:{},extra:{},carry:{},showing:null,lastShown:null,moments:{},complete:false},
  week:{start:null,days:[]}, review:null, pausedUntil:0 }
```

Ladder rule, refined from the spec: each percent of the sunnah number is rounded to the nearest 5, a result of 0 becomes 5, the top rung is the sunnah number itself, duplicates and anything not below the top are dropped. A sunnah number of 10 or less gives one rung.

- [ ] **Step 1: Write the failing tests**
```js
assert.deepEqual(E.ladder(100), [10,30,50,70,100]);
assert.deepEqual(E.ladder(33), [5,10,15,25,33]);
assert.deepEqual(E.ladder(15), [5,10,15]);
assert.deepEqual(E.ladder(10), [10]);
assert.deepEqual(E.ladder(3), [3]);
assert.deepEqual(E.ladder(null), [10,20,33,50,70,100]);

const day = {freq:"hour", wake:"06:00", sleep:"23:00"};
assert.equal(E.slots(day).length, 16);
assert.equal(E.slots(day)[0], 420); assert.equal(E.slots(day).at(-1), 1320);
assert.equal(E.dayStartMin(day), 150);

const late = {freq:"few", wake:"09:00", sleep:"01:00"};          // Review Focus 1
assert.deepEqual(E.slots(late), [720,900,1080,1260,1440]);
assert.equal(E.dayStartMin(late), 300);
assert.equal(E.dayKey(new Date(2026,10,17,1,0).getTime(), late), "2026-11-16");
assert.equal(E.dayKey(new Date(2026,10,17,5,30).getTime(), late), "2026-11-17");
assert.deepEqual(E.momentTimes(late).sleep, {start:1480, end:1560});
assert.deepEqual(E.momentTimes(day), {
  waking:{start:360,end:420}, morning:{start:375,end:720},
  evening:{start:1020,end:1360}, sleep:{start:1360,end:1440} });

const lib = ["a","b","c","d","e","f","g","h"].map((id,i) => ({id, words:3, sunnah:100, starter:i}));
const s = (level,freq) => E.newState({level,freq,wake:"06:00",sleep:"23:00",cardSize:"small"}, lib);
assert.deepEqual(s("new","often").adhkar.map(a => a.target), [30,30,30]);
assert.deepEqual(s("new","hour").adhkar.map(a => a.target), [10,10,10]);   // 90 > 16*5, one rung down fits
assert.deepEqual(s("new","few").adhkar.map(a => a.target), [10,10,10]);    // lowest rung even if it does not fit
assert.equal(s("some","often").adhkar.length, 5);
assert.equal(s("daily","often").adhkar.length, 8);
assert.equal(s("daily","often").comfort[9], 33);
```

- [ ] **Step 2: Run, expect fail.** `node --test workbench/test/engine.test.mjs`
- [ ] **Step 3: Implement the functions above.** Fit rule: while the sum of targets is above `slots.length * startComfort` and a lower rung exists, move every dhikr down one rung.
- [ ] **Step 4: Run, expect pass.**
- [ ] **Step 5: Commit** `workbench: engine ladder, start and clock rules`.

---

### Task 3: Engine, showing and learning

**Files:**
- Modify: `workbench/js/engine.js`
- Test: `workbench/test/engine.test.mjs`

**Interfaces:**
- Consumes: the state shape and `E.CFG` from Task 2.
- Produces (every function returns a new state and never changes its input):
  - `E.rollDay(state, ts)`: when `E.dayKey` differs from `state.day.key`, files the old day into `state.week.days` as `{key, finished:{id:bool}, shows:{id:n}, skips:{id:n}}` and starts an empty day. Carries over nothing except `carry` is cleared. Works across a gap of many days (each missing day is filed as nothing finished).
  - `E.show(state, ts)` gives `{state, card}` where `card` is `null` or `{id, piece, done, extra}` and is also stored as `state.day.showing`. `null` when paused, when no active dhikr exists, or inside the first `momentQuietMin` of a moment window.
  - `E.tap(state, ts, id, n)`: adds to `day.done` (or `day.extra` once the dhikr's target is reached), and to `showing.done` when it is the card on show. Sets `day.complete` when every active target is reached.
  - `E.leave(state, ts, how)` with `how` in `"close" | "ignore" | "later"`: ends the card on show and applies the learning rule. A card whose `done` equals its `piece` is a finish whatever `how` says; `done` above 0 is a partial and is stored in `day.carry[id] = {piece, done}`.
  - `E.intervalMin(state)`: the chosen interval, times `extrasTimes` once `day.complete`.
  - `E.left(state, id)`, `E.active(state)` (adhkar not resting).

Rules to implement, in this order inside `E.show`: carry first (a dhikr with a `carry` entry is shown again with its old `piece` and `done`); else among active adhkar with something left, the one with the largest `expectedFraction - done/target` (expected is the share of today's slots already passed), ties by list order, never `lastShown` when another candidate exists; in extras mode the active adhkar take turns after `lastShown`.

Piece: `slotsFor = max(1, floor(slotsLeftToday / unfinishedCount))`, `need = ceil(left / slotsFor)`, `limit = max(1, floor(comfort[hour] * factor / max(1, ceil(words / longWords))))`, in a good hour (`shown >= goodMinShows` and `finished / shown >= goodRate`) `limit = floor(limit * stretch)`, `piece = clamp(min(need, limit), 1, left)`. In extras mode `piece = limit`.

Rounding: growth rounds up (`Math.ceil`); every other change uses `Math.round`; nothing goes below 1.

- [ ] **Step 1: Write the failing tests** (build states with a small helper `at(h, m)` giving a timestamp on 2026-11-16)
```js
// growth: three finishes in hour 9
assert.equal(after3Finishes.comfort[9], 13);            // ceil(10 * 1.25)
// partial: 4 of a piece of 10, comfort 10
assert.equal(afterPartial.comfort[9], 7);
assert.deepEqual(afterPartial.day.carry.a, {piece:10, done:4});
assert.equal(afterPartial.day.done.a, 4);               // taps are never lost
// the same piece continues next time, in any hour
assert.deepEqual(E.show(afterPartial, at(14,0)).card, {id:"a", piece:10, done:4, extra:false});
// one close changes nothing, the second in the same hour shrinks it
assert.equal(afterOneClose.comfort[9], 10); assert.equal(afterTwoCloses.comfort[9], 8);
// untouched three times halves the hour and does not touch the dhikr
assert.equal(afterThreeIgnores.comfort[9], 5); assert.equal(afterThreeIgnores.adhkar[0].factor, 1);
// later is neutral
assert.deepEqual(afterLater.comfort, before.comfort);
// two closes running for one dhikr
assert.equal(afterTwoClosesOfA.adhkar[0].factor, 0.75);
// Review Focus 2
assert.equal(showFor({target:1}).piece, 1);
assert.equal(showFor({target:100, words:40, comfort:10}).piece, 1);     // floor(10 / 7) = 1
assert.equal(showFor({target:3, comfort:33}).piece, 3);                 // never above what is left
// a finished dhikr steps aside until the rest are finished
assert.notEqual(E.show(aFinishedBNot, at(10,0)).card.id, "a");
// the day completes, then extras at half the pace
assert.equal(allDone.day.complete, true);
assert.equal(E.intervalMin(allDone), 120);
assert.equal(E.show(allDone, at(16,0)).card.extra, true);
// Review Focus 4
assert.equal(E.show(allResting, at(10,0)).card, null);
assert.equal(E.show(paused, at(10,0)).card, null);
assert.equal(E.show(normal, at(17,5)).card, null);      // first 20 minutes of the evening window
// rollDay across a week away keeps the state usable
assert.equal(E.rollDay(normal, at(10,0) + 8*86400000).week.days.length >= 7, true);
```
- [ ] **Step 2: Run, expect fail.**
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run, expect pass.**
- [ ] **Step 5: Commit** `workbench: engine showing, counting and learning`.

---

### Task 4: Engine, the week, the moments and the Now card

**Files:**
- Modify: `workbench/js/engine.js`
- Test: `workbench/test/engine.test.mjs`

**Interfaces:**
- Produces:
  - `E.review(state)` gives `{changes:[{id, from, to}], heavy:[id], suggest:[{id, to}]}` or `null` when fewer than 7 days are filed. `E.rollDay` stores it in `state.review` when the seventh day is filed and applies the automatic changes at once.
  - `E.answerReview(state, {refuse:[id], heavy:{id:"keep"|"lighter"|"rest"}, accept:[id]})`: `refuse` puts a target back, `lighter` moves one rung down, `rest` sets `resting`, `accept` applies a suggestion. Clears `state.review` and starts a new week.
  - `E.setTarget(state, id, n)` (sets `auto:false`, clamps to 1 to 100000), `E.add(state, libItem)` (target from the current start percent's rung; adding one already there changes nothing), `E.remove(state, id)`, `E.rest(state, id, on)`.
  - `E.pause(state, ts, minutes)` sets `pausedUntil` (0 minutes lifts it). `E.awayDays(state)` gives how many of the latest filed days in a row had nothing finished.
  - `E.momentState(state, ts)` gives for each of the four keys `"later" | "waiting" | "running" | "done" | "missed" | "off"`.
  - `E.sessionTap(state, ts, key, items)` where `items = [{id, count}]`: counts one on the current item, moves to the next when its count is reached, marks the moment done after the last. Also calls the same counting as `E.tap` when the id is in My adhkar. `E.sessionMove(state, key, +1 | -1)`. Position is kept in `state.day.moments[key] = {i, n, done}`.
  - `E.nowCard(state, ts, env)` with `env = {permissionMissing}` gives `{kind, ...}`, first match wins: `fix`, `weekly`, `moment` (with `key`, `running`), `continue` (with `id`), `say` (with `id`, `nextAt`), `complete`, and `empty` when there is no active dhikr.

- [ ] **Step 1: Write the failing tests**
```js
assert.deepEqual(reviewOf(weekWith({a:5})).changes, [{id:"a", from:30, to:50}]);
assert.deepEqual(reviewOf(weekWith({a:2})).changes, [{id:"a", from:30, to:10}]);
assert.deepEqual(reviewOf(weekWith({a:4})).changes, []);
assert.deepEqual(reviewOf(weekWith({a:7}, {target:100})).changes, []);              // never past the sunnah number
assert.deepEqual(reviewOf(weekWith({a:7}, {auto:false})).changes, []);              // hand-set is never changed
assert.equal(reviewOf(weekWith({a:7}, {auto:false})).suggest.length, 1);
assert.deepEqual(reviewOf(weekShows({a:{shows:5, skips:3}, b:{shows:10, skips:2}})).heavy, ["a"]);
assert.deepEqual(reviewOf(weekShows({a:{shows:4, skips:4}, b:{shows:10, skips:0}})).heavy, []);   // under 5 appearances
assert.equal(E.answerReview(up, {refuse:["a"]}).adhkar[0].target, 30);
assert.equal(E.answerReview(heavy, {heavy:{a:"rest"}}).adhkar[0].resting, true);
assert.equal(E.nowCard(s, at(10,0), {permissionMissing:true}).kind, "fix");
assert.equal(E.nowCard(withReview, at(10,0), {}).kind, "weekly");
assert.equal(E.nowCard(s, at(6,20), {}).kind, "moment");
assert.equal(E.nowCard(withCarry, at(10,0), {}).kind, "continue");
assert.equal(E.nowCard(s, at(10,0), {}).kind, "say");
assert.equal(E.nowCard(allDone, at(16,0), {}).kind, "complete");
assert.equal(E.nowCard(allResting, at(10,0), {}).kind, "empty");
assert.equal(E.momentState(s, at(13,0)).morning, "missed");
assert.equal(E.add(s, lib[0]).adhkar.length, s.adhkar.length);                       // already added
assert.equal(E.show(E.pause(s, at(10,0), 60), at(10,30)).card, null);
assert.notEqual(E.show(E.pause(s, at(10,0), 60), at(11,1)).card, null);
assert.equal(E.awayDays(E.rollDay(s, at(10,0) + 8*86400000)) >= 7, true);
```
- [ ] **Step 2: Run, expect fail.**
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run, expect pass.**
- [ ] **Step 5: Commit** `workbench: engine weekly review, moments and Now card`.

---

### Task 5: Words, example data and the simulator

**Files:**
- Create: `workbench/js/strings.js`, `workbench/js/data.js`, `workbench/js/sim.js`
- Modify: `workbench/js/core.js` (add `W.t`)
- Test: `workbench/test/sim.test.mjs`, extend `workbench/test/text.test.mjs`

**Interfaces:**
- Consumes: `E.*` from Tasks 2 to 4.
- Produces: `W.STR = {ar:{...}, en:{...}}` and `W.t(key, vars)` (`{name}` placeholders; a missing key returns the key in square brackets so it shows up in a screenshot).
- Produces (`data.js`): `W.LIB` an array of `{id, ar, translit, en, words, sunnah|null, source, groups:[...], starter}` with at least 24 entries, 8 of them with `starter` 0 to 7; `W.SETS = {waking:[{id,count}], morning:[...], evening:[...], sleep:[...]}`; `W.GROUPS` (morning, evening, sleep, afterPrayer, tasabih, duas). Texts and counts are taken from the app's library (`lib/features/library/data/`); each entry copies its text exactly, with tashkeel where the library has it.
- Produces (`sim.js`): `Sim.PEOPLE = ["responsive","busyNoon","ignoresOne","away"]`; `Sim.run(state, fromTs, toTs, person, seed)` gives `{state, log:[{ts, id, piece, did, how, comfortBefore, comfortAfter}]}`, stepping slot by slot with a seeded generator (mulberry32) so the same inputs always give the same log; `Sim.day(key)` gives `{state, now}` for each example day in the URL contract, built by running `Sim.run` from a fixed start (Monday 2026-11-09 06:00) so every example day is something the engine can really produce. `first` gives `{state:null}`.

- [ ] **Step 1: Write the failing tests**
```js
assert.deepEqual(Sim.run(s, t0, t1, "responsive", 7).log, Sim.run(s, t0, t1, "responsive", 7).log);
assert.equal(Sim.run(s, t0, t0 + 86400000, "away", 1).log.every(x => x.how === "ignore"), true);
assert.equal(Sim.day("complete").state.day.complete, true);
assert.equal(E.nowCard(Sim.day("weekup").state, Sim.day("weekup").now, {}).kind, "weekly");
assert.equal(Sim.day("weekheavy").state.review.heavy.length, 1);
assert.equal(Sim.day("first").state, null);
// text.test.mjs: every key in STR.ar is in STR.en and the other way round; no value is empty
```
- [ ] **Step 2: Run, expect fail.**
- [ ] **Step 3: Implement.** People: `responsive` finishes 90 percent; `busyNoon` ignores everything from 11:00 to 15:00 and finishes otherwise; `ignoresOne` closes one named dhikr every time; `away` ignores everything.
- [ ] **Step 4: Run, expect pass.**
- [ ] **Step 5: Commit** `workbench: words, example adhkar and the simulator`.

---

### Task 6: Looks, icons, motion and the gallery

Load the `frontend-design`, `arabic-design` and `animate` skills before starting this task.

**Files:**
- Create: `workbench/css/tokens.css`, `workbench/css/app.css`, `workbench/css/motion.css`, `workbench/fonts/*`, `workbench/js/icons.js`, `workbench/js/ui.js`, `workbench/js/gallery.js`
- Test: extend `workbench/test/smoke.test.mjs`

**Interfaces:**
- Produces (`tokens.css`): custom properties set on `[data-look="a"]` and `[data-look="b"]`, each with `[data-theme="dark"]` values and three text sizes on `[data-size="1|2|3"]`: `--bg --surface --surface-2 --ink --ink-2 --line --accent --accent-ink --good --warn --font-ui --font-dhikr --radius --radius-lg --shadow --text --text-lg --text-dhikr --tap` (`--tap` at least 56px, `--text` at least 18px, `--text-dhikr` at least 28px at every size).
- Produces (`icons.js`): `W.Icon({name, size})` drawing from `W.ICONS`, one family on a 24 grid with one stroke width and round caps. Names at least: `today adhkar more add check close later back forward pause play sun moon bed sunrise bell card-small card-full language text-size sound history backup help comment wrench sparkle pin undo search rest return`.
- Produces (`ui.js`): `W.Btn({kind:"main"|"soft"|"text", icon, onClick, id})`, `W.Ring({done, total, size})`, `W.Sheet`, `W.TabBar`, `W.Row`, `W.Stepper({value, onChange, mark})`, `W.Toast` with undo, `W.Choice({options, value, onChange})` (large choice buttons).
- Produces (`motion.css`): named classes `m-count m-piece-done m-ring m-day-done m-enter m-leave m-screen`, all switched off under `prefers-reduced-motion`.
- Produces: route `gallery` listing every icon with its name and every motion with a replay button.

Fonts: copy `IBMPlexSansArabic-*.ttf` and `NotoSansArabic-Variable.ttf` from `assets/fonts/`. A second look may use another open-licence face only if its files are already on this PC under `E:\fonts`; otherwise both looks use these two with different weights and sizes. Record each font's licence in `workbench/README.md`.

- [ ] **Step 1: Write the failing test**
```js
test("gallery shows the whole icon family", () => {
  const dom = dumpDom("route=gallery");
  for (const n of ["today","adhkar","more","add","check","later","sun","moon","bed","sunrise"])
    assert.match(dom, new RegExp('data-icon="' + n + '"'));
  assert.doesNotMatch(dom, /data-error=/);
});
```
- [ ] **Step 2: Run, expect fail.**
- [ ] **Step 3: Build the tokens for two looks, the icon family, the shared parts, the motion classes and the gallery.** Two looks must differ in more than colour (type treatment, corners, ornament). Neither copies the current app's mandala card.
- [ ] **Step 4: Run tests, then take `shot("route=gallery&look=a", ...)` and `look=b`, `theme=dark`, and read the four images.** Expected: every icon legible at 24 px, same stroke weight, Arabic joined correctly.
- [ ] **Step 5: Commit** `workbench: two looks, icon family, motion and gallery`.

---

### Task 7: Frames and the Workbench menu

**Files:**
- Create: `workbench/js/frames.js`, `workbench/js/wb.js`
- Modify: `workbench/js/app.js`, `workbench/css/workbench.css`
- Test: extend `workbench/test/smoke.test.mjs`

**Interfaces:**
- Consumes: `W.U()`, `W.act`, `Sim.day`, `W.Icon`, `W.Btn`.
- Produces: `W.PhoneFrame({children})` (390 by 844 stage made of plain elements, `data-id="phone"`, with layers `data-id="phone-app"` and `data-id="phone-over"` for popups) and `W.WindowsFrame({children})` (`data-id="desktop"`, with `desktop-window`, `desktop-corner`, `desktop-tray`). `W.Screen()` picks the screen for `ui.route` (a plain placeholder naming the route until its task lands).
- Produces: `W.setDay(key)` (loads `Sim.day(key)` into `W.S.state.eng`, clears undo), `W.setLang`, `W.setTheme`, `W.setSize`, `W.setLook`, `W.setFrame`, `W.resetAll()`.
- The menu is English only, sits outside the frames, and every control in it carries `data-cmt-ui="1"` so the comment tool ignores it.

- [ ] **Step 1: Write the failing test**
```js
test("frame, language and look follow the URL", () => {
  const dom = dumpDom("day=noon&lang=en&frame=windows&look=b&theme=dark&size=3");
  assert.match(dom, /data-id="desktop"/); assert.match(dom, /data-look="b"/);
  assert.match(dom, /data-theme="dark"/); assert.match(dom, /data-size="3"/); assert.match(dom, /dir="ltr"/);
});
```
- [ ] **Step 2: Run, expect fail.**
- [ ] **Step 3: Implement.** Language sets `dir` and `lang` on the frame, not on the workbench chrome.
- [ ] **Step 4: Run, expect pass.**
- [ ] **Step 5: Commit** `workbench: phone and Windows frames, Workbench menu`.

---

### Task 8: The comment tool

**Files:**
- Create: `workbench/js/comments.js`
- Modify: `workbench/js/core.js` (comment store), `workbench/css/workbench.css`
- Reference to port from: `E:\IMA work\Code\gratovo_toolbox\design\workbench-prototype\js\comments.js` (the tool) and `js\proto.js` lines 145 to 199 (the store)
- Test: extend `workbench/test/smoke.test.mjs`, `workbench/test/serve.test.mjs`

**Interfaces:**
- Consumes: `W.served`, `W.LS`, `W.U()`, `W.go`, `W.setDay`, `W.setLang`, `W.setFrame`.
- Produces: `W.CM = {list}`; `W.commentAdd({kind, text, place, anchor})`, `W.commentPatch(id, patch)`, `W.commentDelete(id)`, `W.commentRestore(c)`, `W.toggleCommentMode(force)`, `W.commentVisit(c)`, `W.commentsForClaude()`, `W.CommentLayer`.
- A comment: `{id, at, status:"open"|"done", doneAt, kind:"fix"|"idea"|"question", text, place:{frame, day, lang, route, popup}, anchor:{label, dataId, path, text, fx, fy}}`. `dataId` is the nearest `data-id`; `path` is the CSS path used when there is none; `fx, fy` are the click's position inside the element as fractions.
- Storage: every change saves to `dhikr-wb-comments`; when `W.served`, also `PUT /api/comments` with the whole list, at most once per 300 ms. At start: the file's list and the browser's list are joined by `id` (the one with the later `at` or `doneAt` wins).

Keep from the original: C toggles the mode, a box follows the pointer, click opens the composer, Alt-click picks the larger area, numbered pins that re-measure on scroll, resize and every 450 ms, dashed pin when only the section is found, side list with go to, done, delete with undo, show done, show pins, Copy for Claude. Change: the pickable selector becomes `[data-id], button, a, input, [role=tab], h1, h2, h3, p, li, svg[data-icon]`, the larger-area selector becomes `[data-screen], [data-id="phone"], [data-id="desktop"], section`, labels come from `data-id` and the element's text, and a pin shows only when `place` matches the current frame, day, language, route and popup.

- [ ] **Step 1: Write the failing tests**
```js
// smoke: a comment saved in storage comes back as a pin on its element
test("a saved comment shows its pin", () => {
  const dom = dumpDom("day=noon&route=today&seedComment=now-card");   // app.js seeds one comment anchored to data-id=now-card when asked
  assert.match(dom, /class="[^"]*cmt-pin/);
});
test("a comment made on another route shows no pin here", () => {
  assert.doesNotMatch(dumpDom("day=noon&route=more&seedComment=now-card"), /cmt-pin/);
});
// serve: PUT then GET keeps place and anchor intact (extend the round trip test with a full comment object)
```
- [ ] **Step 2: Run, expect fail.**
- [ ] **Step 3: Port and adapt.**
- [ ] **Step 4: Run, expect pass. Then by hand through `node workbench/serve.mjs`: pin a comment inside the phone frame, reload, switch example day and back; confirm it is in `workbench/comments.json`.**
- [ ] **Step 5: Commit** `workbench: comment tool with file sync`.

---

### Task 9: The dhikr card and the reminder on the phone

**Files:**
- Create: `workbench/js/card.js`
- Modify: `workbench/js/frames.js` (pretend home screen and lock screen under `phone-over`), `workbench/css/app.css`
- Test: extend `workbench/test/smoke.test.mjs`

**Interfaces:**
- Consumes: `E.show`, `E.tap`, `E.leave`, `W.LIB`, motion classes, `W.Icon`.
- Produces: `W.Card({size:"small"|"full"|"page", id, piece, done, dayDone, dayTarget, extra, title, onTap, onLater, onClose, onBack, onForward})`. `small` counts on a tap of the card itself; `full` and `page` count on a tap anywhere. A dhikr whose text does not fit the small card renders as `full`. Shows the piece (`data-id="card-count"`, "7 of 10") and the day line smaller; an extra shows the word for extra and no target.
- Produces: `W.showReminder()` (asks `E.show`, sets `ui.popup` to the person's card size), `W.cardTap()`, `W.cardLeave(how)`. Finishing a piece plays `m-piece-done`, holds 900 ms, then leaves by itself.
- The Workbench menu gains "Show a reminder now".

- [ ] **Step 1: Write the failing test**
```js
test("small reminder over the home screen", () => {
  const dom = dumpDom("day=noon&popup=small");
  assert.match(dom, /data-id="card"[^>]*data-size="small"/);
  assert.match(dom, /data-id="card-later"/); assert.match(dom, /data-id="card-close"/);
});
test("full reminder", () => { assert.match(dumpDom("day=noon&popup=full"), /data-size="full"/); });
test("lock screen", () => { assert.match(dumpDom("day=noon&popup=lock"), /data-id="lock"/); });
```
- [ ] **Step 2: Run, expect fail.**
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run, expect pass. Screenshot small, full and lock in Arabic and English and read them.**
- [ ] **Step 5: Commit** `workbench: dhikr card in three sizes and the phone reminder`.

---

### Task 10: Onboarding

**Files:**
- Create: `workbench/js/onboarding.js`
- Test: extend `workbench/test/smoke.test.mjs`

**Interfaces:**
- Consumes: `E.newState`, `W.Choice`, `W.Card`, `W.go`.
- Produces: routes `onboarding/1` to `onboarding/6` following spec 7.2 exactly. Answers are held in `ui.answers`; "Choose for me" (`data-id="choose-for-me"`) takes the middle option (`some`, `hour`, wake `06:00`, sleep `23:00`, `small`). Step 1 offers `اللغة العربية` and `English`. Step 5 shows a real `W.Card` that must be tapped 3 times before the two sizes are offered. Step 6 shows only when `frame=phone` and has a "Not now" that leaves `ui.permissionMissing = true`. The last step calls `E.newState(answers, W.LIB)` and goes to `today`. `day=first` starts at `onboarding/1`.

- [ ] **Step 1: Write the failing test**
```js
for (let i = 1; i <= 6; i++) test("onboarding step " + i, () => {
  const dom = dumpDom("day=first&route=onboarding/" + i);
  assert.match(dom, new RegExp('data-screen="onboarding/' + i + '"'));
  if (i < 6) assert.match(dom, /data-id="choose-for-me"/);
});
```
- [ ] **Step 2: Run, expect fail.**
- [ ] **Step 3: Implement.** One question per screen, one main button, a quiet step marker, a back button with its word.
- [ ] **Step 4: Run, expect pass. Screenshot the six steps and read them.**
- [ ] **Step 5: Commit** `workbench: onboarding`.

---

### Task 11: Today

**Files:**
- Create: `workbench/js/today.js`
- Test: extend `workbench/test/smoke.test.mjs`

**Interfaces:**
- Consumes: `E.nowCard`, `E.momentState`, `E.left`, `W.Ring`, `W.TabBar`, `W.go`.
- Produces: route `today` per spec 8.1: the Now card (`data-id="now-card"` with `data-kind` set to the `nowCard` kind, and `now-button`), today's list (`today-row-<id>`, finished ones last with a check, a tap goes to `count/<id>`), the moments strip (`moment-<key>` with `data-state`), "Pause for an hour" (`pause`), the first-days hint line. Route `count/<id>` shows `W.Card` at size `page`. `data-kind="complete"` plays `m-day-done` once per day. `data-kind="empty"` shows the empty state with a main button to `add`. When `E.awayDays(state)` is 3 or more, a welcome-back line (`data-id="welcome-back"`) sits above the Now card, with no word about the days missed. "Pause for an hour" calls `E.pause` and turns into "Resume".

- [ ] **Step 1: Write the failing test**
```js
const kind = q => (dumpDom(q).match(/data-id="now-card"[^>]*data-kind="(\w+)"/) || [])[1];
test("noon asks to say one", () => assert.equal(kind("day=noon&route=today"), "say"));
test("complete day", () => assert.equal(kind("day=complete&route=today"), "complete"));
test("weekly card waits first", () => assert.equal(kind("day=weekup&route=today"), "weekly"));
test("back after a week away", () => assert.match(dumpDom("day=missed&route=today"), /data-id="welcome-back"/));
test("no adhkar shows the empty state", () => {                       // Review Focus 4
  const dom = dumpDom("day=noon&route=today&restAll=1");
  assert.match(dom, /data-kind="empty"/); assert.doesNotMatch(dom, /data-error=/);
});
```
- [ ] **Step 2: Run, expect fail.**
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run, expect pass. Screenshot each kind and read them.**
- [ ] **Step 5: Commit** `workbench: Today`.

---

### Task 12: My adhkar, a dhikr's page and adding

**Files:**
- Create: `workbench/js/adhkar.js`, `workbench/js/add.js`
- Test: extend `workbench/test/smoke.test.mjs`

**Interfaces:**
- Consumes: `E.setTarget`, `E.add`, `E.remove`, `E.rest`, `E.ladder`, `W.Stepper`, `W.Toast`, `W.LIB`, `W.GROUPS`.
- Produces: `adhkar` (main button `add-dhikr` first, rows `adhkar-row-<id>` with the day amount and the sunnah number when there is one, a "Resting" group last with `bring-back-<id>`, a row leading to `moments`); `adhkar/<id>` (full text, `W.Stepper` with the sunnah number marked, `count-now`, `rest`, `remove` with an undo toast and no dialog; an amount above the sunnah number is allowed and labelled as more than the sunnah); `add` (search, "Suggested for you" with six entries not yet added, each `add-<id>` adding in one tap and turning into an added state, then group tiles) and `add/<group>`.

- [ ] **Step 1: Write the failing test**
```js
test("my adhkar", () => { const d = dumpDom("day=noon&route=adhkar"); assert.match(d, /data-id="add-dhikr"/); assert.match(d, /data-id="adhkar-row-/); });
test("add shows six suggestions", () => { assert.equal((dumpDom("day=noon&route=add").match(/data-suggest="1"/g) || []).length, 6); });
test("a dhikr page", () => { assert.match(dumpDom("day=noon&route=adhkar/" + firstId), /data-id="stepper"/); });
```
- [ ] **Step 2: Run, expect fail.**
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run, expect pass. Screenshot and read.**
- [ ] **Step 5: Commit** `workbench: My adhkar, dhikr page and adding`.

---

### Task 13: Moments, sessions and the weekly card

**Files:**
- Create: `workbench/js/moments.js`, `workbench/js/weekly.js`
- Test: extend `workbench/test/smoke.test.mjs`

**Interfaces:**
- Consumes: `E.momentState`, `E.momentTimes`, `E.sessionTap`, `E.sessionMove`, `E.review`, `E.answerReview`, `W.Card`, `W.SETS`.
- Produces: `moments` (the four sets with time, count of adhkar, on or off switch) and `moments/<key>` (its contents and its time, editable); the moment card as `popup=moment` (name, about how many minutes, Start, Later); `session/<key>` running `W.Card` at `page` size with "3 of 12", back and forward buttons with words, leaving at any time keeps the place; `weekly` showing `state.review`: one line per change in words ("from 30 to 50 a day, the sunnah is 100"), one refuse button per change, the heavy dhikr block with Keep it, Make it lighter, Rest it for now, and one main button to accept. A week that only went down uses neutral words and no praise or blame.

- [ ] **Step 1: Write the failing test**
```js
test("weekly up", () => { const d = dumpDom("day=weekup&route=weekly"); assert.match(d, /data-id="weekly-change-/); assert.match(d, /data-id="weekly-refuse-/); });
test("weekly heavy", () => { const d = dumpDom("day=weekheavy&route=weekly"); for (const k of ["keep","lighter","rest"]) assert.match(d, new RegExp('data-id="heavy-' + k)); });
test("session", () => assert.match(dumpDom("day=noon&route=session/morning"), /data-id="session-progress"/));
test("moment card", () => assert.match(dumpDom("day=noon&popup=moment"), /data-id="moment-start"/));
```
- [ ] **Step 2: Run, expect fail.**
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run, expect pass. Screenshot and read.**
- [ ] **Step 5: Commit** `workbench: moments, sessions and the weekly card`.

---

### Task 14: More

**Files:**
- Create: `workbench/js/more.js`
- Test: extend `workbench/test/smoke.test.mjs`

**Interfaces:**
- Consumes: `W.Row`, `W.Choice`, state prefs, `state.week`.
- Produces: `more` with rows whose titles are the onboarding questions word for word (`more-row-freq`, `more-row-sleep`, `more-row-look`, `more-row-sound`, `more-row-lang`, `more-row-size`), each opening `more/<row>` with the same choices as onboarding; `more-row-days` to `days` (the last 7 and 30 days as simple bars, no streak wording, no missed-day wording); a folded "Other" (`more-other`) holding backup, request a dhikr, report a problem, updates and about as rows that open a plain page each.

- [ ] **Step 1: Write the failing test**
```js
test("more rows", () => { const d = dumpDom("day=noon&route=more"); for (const r of ["freq","sleep","look","sound","lang","size","days"]) assert.match(d, new RegExp('data-id="more-row-' + r)); });
```
- [ ] **Step 2: Run, expect fail.**
- [ ] **Step 3: Implement.** Changing frequency or wake and sleep calls `W.act` and takes effect in the engine state at once.
- [ ] **Step 4: Run, expect pass.**
- [ ] **Step 5: Commit** `workbench: More`.

---

### Task 15: Simulate a day

**Files:**
- Modify: `workbench/js/wb.js`, `workbench/css/workbench.css`
- Test: extend `workbench/test/smoke.test.mjs`

**Interfaces:**
- Consumes: `Sim.run`, `Sim.PEOPLE`, `E.rollDay`, `W.showReminder`.
- Produces: a panel (`data-id="sim"`, `data-cmt-ui="1"`) with a clock slider over the waking day, play and pause, a person chooser, "Next day" and "Next week" buttons, and a log (`sim-log`) with one line per appearance: time, dhikr, piece, what happened, and what changed ("09:00 comfort 10 to 13"). Dragging forward runs `Sim.run` from the old time to the new; dragging backward restores the snapshot taken at the start of the simulated day and replays to that time with the same seed. The frame shows the app at the simulated time, and a popup when the time lands on a slot.

- [ ] **Step 1: Write the failing test**
```js
test("simulator runs a day", () => {
  const d = dumpDom("day=noon&sim=responsive&simTo=21:00");
  assert.match(d, /data-id="sim-log"/); assert.ok((d.match(/data-sim-line/g) || []).length >= 5);
  assert.doesNotMatch(d, /data-error=/);
});
test("clock dragged backward does not break", () => assert.doesNotMatch(dumpDom("day=noon&sim=responsive&simTo=21:00&simBack=10:00"), /data-error=/));
```
- [ ] **Step 2: Run, expect fail.**
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run, expect pass.**
- [ ] **Step 5: Commit** `workbench: simulate a day`.

---

### Task 16: Windows frame content

**Files:**
- Modify: `workbench/js/frames.js`, `workbench/css/app.css`
- Test: extend `workbench/test/smoke.test.mjs`

**Interfaces:**
- Consumes: `W.Card`, `W.Screen`, `W.showReminder`.
- Produces: in `frame=windows`: the small card at the bottom corner on the taskbar side (`desktop-corner`), the full card centred over a dimmed desktop, a tray menu (`desktop-tray`: Open, Count one, Pause for an hour, Close), and the app in a window where the three places sit as a side bar with words and the content is at most 720 px wide. Space and Enter count on the card and Escape closes it.

- [ ] **Step 1: Write the failing test**
```js
test("windows small card", () => assert.match(dumpDom("day=noon&frame=windows&popup=small"), /data-id="desktop-corner"[\s\S]*data-id="card"/));
test("windows app window", () => assert.match(dumpDom("day=noon&frame=windows&route=today"), /data-id="desktop-window"[\s\S]*data-id="now-card"/));
```
- [ ] **Step 2: Run, expect fail.**
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run, expect pass. Screenshot and read.**
- [ ] **Step 5: Commit** `workbench: Windows frame`.

---

### Task 17: The full pass

Load the `break-ui` and `arabic-design` skills before starting this task.

**Files:**
- Modify: whatever the pass finds; `workbench/README.md`
- Test: extend `workbench/test/smoke.test.mjs`

- [ ] **Step 1: Write the sweep test**

For every route in the Conventions list, crossed with `lang=ar|en`, on `day=noon` (and `day=first` for onboarding): `data-ready="1"`, no `data-error`, and no `[` followed by a string key (a missing word). Add `long=1`, which makes `app.js` swap the first dhikr for the longest entry in `W.LIB` with tashkeel, crossed with `size=3` and `popup=small` (Review Focus 5): the card must carry `data-size="full"` and no error.

- [ ] **Step 2: Run it and fix what fails.**
- [ ] **Step 3: Walk every situation in spec 8.5** by URL and by hand, in Arabic and English, light and dark, both looks, size 1 and 3. Take a screenshot of each and read it. Fix clipped text, anything under 56 px that can be tapped, any icon without its word, any screen with two main buttons.
- [ ] **Step 4: Read every Arabic string once more as an Egyptian would say it.** List the strings in `workbench/README.md` under "Words to check" for the owner.
- [ ] **Step 5: Finish `workbench/README.md`**: open it, comment, the Workbench menu, example days, the URL contract, tests, fonts and licences, and what is pretend (permissions, notifications, sound).
- [ ] **Step 6: Run `node --test workbench/test/`.** Expected: all pass.
- [ ] **Step 7: Commit** `workbench: full pass over every situation`.
