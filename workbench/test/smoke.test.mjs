import { test } from "node:test";
import assert from "node:assert/strict";
import { createRequire } from "node:module";
import { browserPath, dumpDom, dumpDomAsync } from "./helpers.mjs";

const firstId = createRequire(import.meta.url)("../js/data.js").LIB.find(x => x.starter === 0).id;

const skip = browserPath() ? false : "no Edge or Chrome found, browser tests skipped";

test("opens with no error", { skip }, () => {
  const dom = dumpDom("day=first&lang=ar");
  assert.match(dom, /data-ready="1"/);
  assert.doesNotMatch(dom, /data-error=/);
  assert.match(dom, /dir="rtl"/);
});

test("gallery shows the whole icon family", { skip }, () => {
  const dom = dumpDom("route=gallery");
  for (const n of ["today","adhkar","more","add","check","later","sun","moon","bed","sunrise"])
    assert.match(dom, new RegExp('data-icon="' + n + '"'));
  assert.doesNotMatch(dom, /data-error=/);
});

test("gallery lists every icon, part and motion, and the root carries theme and size", { skip }, () => {
  const dom = dumpDom("route=gallery&theme=dark&size=3");
  assert.doesNotMatch(dom, /data-id="wb-look"/);
  assert.match(dom, /<html[^>]*data-theme="dark"/);
  assert.match(dom, /<html[^>]*data-size="3"/);
  const icons = "today adhkar more add check close later back forward pause play sun moon bed sunrise bell card-small card-full language text-size sound history backup help comment wrench sparkle pin undo search rest return".split(" ");
  for (const n of icons) assert.match(dom, new RegExp('data-id="g-icon-' + n + '"'), n);
  for (const m of ["m-count", "m-piece-done", "m-ring", "m-day-done", "m-enter", "m-leave", "m-screen"])
    assert.match(dom, new RegExp('data-id="g-motion-' + m + '-replay"'), m);
  for (const p of ["btn", "ring", "sheet", "tabbar", "row", "stepper", "toast", "choice"])
    assert.match(dom, new RegExp('data-id="g-part-' + p + '"'), p);
  assert.doesNotMatch(dom, /data-error=/);
});

test("junk in storage does not stop it", { skip }, () => {
  const dom = dumpDom("junk=1");
  assert.match(dom, /data-ready="1"/);
  assert.doesNotMatch(dom, /data-error=/);
});

test("frame, language and theme follow the URL without Look B switcher", { skip }, () => {
  const dom = dumpDom("day=noon&lang=en&frame=windows&theme=dark&size=3");
  assert.match(dom, /data-id="desktop"[^>]*dir="ltr"/);
  assert.match(dom, /data-id="desktop-window"/);
  assert.doesNotMatch(dom, /data-id="wb-look"/);
  assert.match(dom, /data-theme="dark"/);
  assert.match(dom, /data-size="3"/);
  assert.doesNotMatch(dom, /data-error=/);
});

test("phone frame shows the route's screen in Arabic by default", { skip }, () => {
  const dom = dumpDom("day=noon&route=today");
  assert.match(dom, /data-id="phone"[^>]*dir="rtl"/);
  assert.match(dom, /data-id="phone-app"/);
  assert.match(dom, /data-id="phone-over"/);
  assert.match(dom, /data-screen="today"/);
  assert.match(dom, /data-id="wb-menu"[^>]*data-cmt-ui="1"/);
  assert.doesNotMatch(dom, /data-error=/);
});

test("the first example day starts at onboarding", { skip }, () => {
  assert.match(dumpDom("day=first"), /data-screen="onboarding\/1"/);
});

test("a saved comment shows its pin on the element it was pinned to", { skip }, () => {
  const dom = dumpDom("day=noon&route=today&seedComment=tab-today");
  assert.match(dom, /class="cmt-pin"/);
  assert.doesNotMatch(dom, /cmt-pin approx/);
  assert.doesNotMatch(dom, /data-error=/);
});

test("a comment whose element is gone sits dashed on its screen", { skip }, () => {
  assert.match(dumpDom("day=noon&route=today&seedComment=no-such-part"), /class="cmt-pin approx"/);
});

test("a comment made on another route shows no pin here", { skip }, () => {
  const dom = dumpDom("day=noon&route=more&seedComment=tab-today");
  assert.doesNotMatch(dom, /cmt-pin/);
  assert.match(dom, /data-id="wb-comments"/);
});

test("clicking a part in comment mode saves a comment and pins it there", { skip }, () => {
  const dom = dumpDom("day=noon&route=today&autoComment=tab-adhkar");
  assert.match(dom, /class="cmt-pin"/);
  assert.match(dom, /Comments \(1\)/);
  assert.doesNotMatch(dom, /data-error=/);
});

test("small reminder over the home screen", { skip }, () => {
  const dom = dumpDom("day=noon&popup=small");
  assert.match(dom, /data-id="home"/);
  assert.match(dom, /data-id="card"[^>]*data-size="small"/);
  assert.match(dom, /data-id="card-count"/);
  assert.match(dom, /data-id="card-later"/);
  assert.match(dom, /data-id="card-close"/);
  assert.doesNotMatch(dom, /data-error=/);
});

test("full reminder", { skip }, () => {
  const dom = dumpDom("day=noon&popup=full");
  assert.match(dom, /data-id="card"[^>]*data-size="full"/);
  assert.doesNotMatch(dom, /data-error=/);
});

test("lock screen", { skip }, () => {
  const dom = dumpDom("day=noon&popup=lock");
  assert.match(dom, /data-id="lock"/);
  assert.match(dom, /data-id="card"/);
});

test("tapping the card counts, and a finished piece leaves by itself", { skip }, () => {
  const one = dumpDom("day=noon&popup=small&autoTap=1");
  assert.match(one, /data-id="card-count"[^>]*data-done="1"/);
  const all = dumpDom("day=noon&popup=small&autoTap=all");
  assert.doesNotMatch(all, /data-id="card"/);
  assert.match(all, /data-screen="today"/);
  assert.doesNotMatch(all, /data-error=/);
});

test("the menu can show a reminder now", { skip }, () => {
  assert.match(dumpDom("day=noon"), /data-id="wb-remind"/);
});

for (let i = 1; i <= 7; i++) test("onboarding step " + i, { skip }, () => {
  const dom = dumpDom("day=first&route=onboarding/" + i);
  assert.match(dom, new RegExp('data-screen="onboarding/' + i + '"'));
  assert.match(dom, /data-id="ob-question"/);
  if (i < 7) assert.match(dom, /data-id="choose-for-me"/);
  if (i > 1) assert.match(dom, /data-id="ob-back"/);
  assert.doesNotMatch(dom, /data-error=/);
  assert.doesNotMatch(dom, /\[[a-z]+\.[a-z.0-9]+\]/);
});

test("onboarding step 1 offers Arabic and English", { skip }, () => {
  const dom = dumpDom("day=first");
  assert.match(dom, /اللغة العربية/);
  assert.match(dom, /English/);
});

test("onboarding step 4 asks about hearing the dhikr recited before wake and sleep", { skip }, () => {
  const dom = dumpDom("day=first&route=onboarding/4");
  assert.match(dom, /data-id="ob-recite"/);
  assert.match(dom, /data-id="ob-recite-yes"/);
  assert.match(dom, /data-id="ob-recite-no"/);
});

test("Choose for me six times, then the permissions, lands on Today", { skip }, () => {
  const six = Array(6).fill("choose-for-me").join(",");
  const dom = dumpDom("day=first&autoClick=" + six + ",perm-allow,perm-notnow,perm-allow");
  assert.match(dom, /data-screen="today"/);
  assert.doesNotMatch(dom, /data-error=/);
});

test("on Windows onboarding has no permission step", { skip }, () => {
  const six = Array(6).fill("choose-for-me").join(",");
  assert.match(dumpDom("day=first&frame=windows&autoClick=" + six), /data-screen="today"/);
});

test("the try step offers the two sizes only after three taps", { skip }, () => {
  assert.doesNotMatch(dumpDom("day=first&route=onboarding/6"), /data-id="ob-size"/);
  assert.match(dumpDom("day=first&route=onboarding/6&autoClick=card,card,card"), /data-id="ob-size"/);
});

const kind = q => (dumpDom(q).match(/data-id="now-card"[^>]*data-kind="(\w+)"/) || [])[1];
test("noon asks to say one", { skip }, () => assert.equal(kind("day=noon&route=today"), "say"));
test("complete day", { skip }, () => assert.equal(kind("day=complete&route=today"), "complete"));
test("weekly card waits first", { skip }, () => assert.equal(kind("day=weekup&route=today"), "weekly"));
test("back after a week away", { skip }, () => assert.match(dumpDom("day=missed&route=today"), /data-id="welcome-back"/));
test("no adhkar shows the empty state", { skip }, () => {
  const dom = dumpDom("day=noon&route=today&restAll=1");
  assert.match(dom, /data-kind="empty"/); assert.doesNotMatch(dom, /data-error=/);
});

test("my adhkar has 6 top views, compact moment summary popup, and sticky bottom add button", { skip }, () => {
  const d = dumpDom("day=noon&route=adhkar");
  assert.match(d, /data-id="adhkar-views"/);
  assert.match(d, /data-id="adhkar-fab"[\s\S]*data-id="add-dhikr"/);
  assert.match(d, /data-id="adhkar-row-/);
  const m = dumpDom("day=noon&route=adhkar&autoClick=adhkar-moments");
  assert.match(m, /data-id="adhkar-moment-ctrl"/);
  assert.match(m, /data-id="moment-compact-open"/);
  assert.doesNotMatch(m, /data-id="moment-inline-time"/);
  const pop = dumpDom("day=noon&route=adhkar&autoClick=adhkar-moments,moment-compact-open");
  assert.match(pop, /data-id="moment-settings-sheet"/);
  assert.match(pop, /data-id="moment-switch-morning"/);
  assert.match(pop, /data-id="moment-inline-time"/);
});
test("add shows six suggestions and persistent breadcrumb bar on nested group", { skip }, () => {
  assert.equal((dumpDom("day=noon&route=add").match(/data-suggest="1"/g) || []).length, 6);
  const g = dumpDom("day=noon&route=add/morning");
  assert.match(g, /data-id="app-bar"/);
  assert.match(g, /data-id="app-back"/);
  assert.match(g, /data-id="app-here"[^>]*>أذكار الصبح</);
});
test("a dhikr page shows virtue benefits in Arabic and English", { skip }, () => {
  const ar = dumpDom("day=weekheavy&lang=ar&route=adhkar/d516bd15e8a");
  assert.match(ar, /data-id="stepper"/);
  assert.match(ar, /data-id="dhikr-fadl"/);
  assert.match(ar, /يمحو الذنوب/);
  const en = dumpDom("day=weekheavy&lang=en&route=adhkar/d516bd15e8a");
  assert.match(en, /data-id="dhikr-fadl"/);
  assert.match(en, /forgiveness/);
});

test("today normal say card omits extra title and embeds pause inside now-card", { skip }, () => {
  const d = dumpDom("day=noon&route=today");
  assert.match(d, /data-id="now-card"[^>]*data-kind="say"/);
  assert.doesNotMatch(d, /class="now-text title"/);
  assert.match(d, /data-id="now-card"[\s\S]*data-id="now-remind"[\s\S]*data-id="pause"/);
});

test("count completion shows celebration and next actions", { skip }, () => {
  const d = dumpDom("day=noon&route=count/d17424625ae&autoClick=card");
  assert.match(d, /data-id="card-cele"/);
  assert.match(d, /data-id="card-cele-actions"/);
});

test("weekly up, down and heavy include motivating stats, words, and sleep-dhikr improvement tip", { skip }, () => {
  const up = dumpDom("day=weekup&route=weekly");
  assert.match(up, /data-id="weekly-change-/);
  assert.match(up, /data-id="weekly-refuse-/);
  assert.match(up, /data-id="weekly-stats"/);
  assert.match(up, /data-id="weekly-motivate"/);
  const down = dumpDom("day=weekdown&lang=en&route=weekly");
  assert.match(down, /A gentle pace for the new week/);
  assert.match(down, /data-id="weekly-stats"/);
  assert.match(down, /data-id="weekly-motivate"/);
  assert.match(down, /data-id="weekly-tip"/);
  assert.match(down, /before you sleep/);
  const h = dumpDom("day=weekheavy&route=weekly");
  for (const k of ["keep","lighter","rest"]) assert.match(h, new RegExp('data-id="heavy-' + k));
});
test("session", { skip }, () => assert.match(dumpDom("day=noon&route=session/morning"), /data-id="session-progress"/));
test("moment card", { skip }, () => assert.match(dumpDom("day=noon&popup=moment"), /data-id="moment-start"/));

test("more rows, search, containered other, merged sound+recite, and days sections", { skip }, () => {
  const d = dumpDom("day=noon&route=more");
  for (const r of ["freq","sleep","look","sound","lang","size","days"]) assert.match(d, new RegExp('data-id="more-row-' + r));
  assert.doesNotMatch(d, /data-id="more-row-recite"/);
  assert.match(d, /data-id="more-search"/);
  assert.match(d, /data-id="more-other-box"/);
  const snd = dumpDom("day=noon&route=more/sound");
  assert.match(snd, /data-id="more-sound"/);
  assert.match(snd, /data-id="more-recite"/);
  const days = dumpDom("day=weekheavy&route=days");
  for (const sec of ["days-hero", "days-calendar", "days-grove", "days-all", "days-7", "days-oasis", "days-30", "days-year"]) {
    assert.match(days, new RegExp('data-id="' + sec + '"'), sec);
  }
});
test("workbench topbar exposes direct text edit mode", { skip }, () => {
  assert.match(dumpDom("day=noon"), /data-id="wb-edit-text"/);
});

test("simulator runs a day", { skip }, () => {
  const d = dumpDom("day=noon&sim=responsive&simTo=21:00");
  assert.match(d, /data-id="sim-log"/); assert.ok((d.match(/data-sim-line/g) || []).length >= 5);
  assert.doesNotMatch(d, /data-error=/);
});
test("clock dragged backward does not break", { skip }, () => {
  const d = dumpDom("day=noon&sim=responsive&simTo=21:00&simBack=10:00");
  assert.match(d, /data-id="sim-log"/); assert.match(d, /10:00/); assert.doesNotMatch(d, /data-error=/);
});

test("windows small card", { skip }, () => {
  const d = dumpDom("day=noon&frame=windows&popup=small");
  assert.match(d, /data-id="desktop-corner"[\s\S]*data-id="card"/);
  assert.doesNotMatch(d, /data-id="home"/);
  assert.doesNotMatch(d, /data-error=/);
});
test("windows full card and tray menu", { skip }, () => {
  const full = dumpDom("day=noon&frame=windows&popup=full");
  assert.match(full, /data-id="desktop-full"[\s\S]*data-id="card"/);
  const tray = dumpDom("day=noon&frame=windows&autoClick=tray-icon");
  for (const k of ["tray-open", "tray-count", "tray-pause", "tray-close"]) assert.match(tray, new RegExp('data-id="' + k + '"'));
  assert.doesNotMatch(tray, /data-error=/);
});
test("windows app window", { skip }, () => {
  const d = dumpDom("day=noon&frame=windows&route=today");
  assert.match(d, /data-id="desktop-window"[\s\S]*data-id="now-card"/);
  assert.doesNotMatch(d, /data-error=/);
});

test("sweep: every route in Arabic and English renders with no missing words", { skip }, async () => {
  const base = new URL("../index.html", import.meta.url).href;
  const routes = [
    ["first", "onboarding/1"], ["first", "onboarding/2"], ["first", "onboarding/3"],
    ["first", "onboarding/4"], ["first", "onboarding/5"], ["first", "onboarding/6"], ["first", "onboarding/7"],
    ["noon", "today"], ["noon", "adhkar"], ["noon", "adhkar/" + firstId],
    ["noon", "add"], ["noon", "add/morning"], ["noon", "moments"], ["noon", "moments/morning"],
    ["noon", "session/morning"], ["noon", "count/" + firstId], ["noon", "weekly"], ["weekup", "weekly"], ["weekdown", "weekly"],
    ["noon", "more"], ["noon", "more/freq"], ["noon", "more/recite"], ["noon", "more/sleep"], ["noon", "more/look"],
    ["noon", "more/sound"], ["noon", "more/lang"], ["noon", "more/size"], ["noon", "days"], ["noon", "gallery"]
  ];
  const queries = [];
  for (const [day, route] of routes) {
    for (const lang of ["ar", "en"]) queries.push(`day=${day}&lang=${lang}&route=${route}`);
  }
  for (let i = 0; i < queries.length; i += 26) {
    const batch = queries.slice(i, i + 6);
    const doms = await Promise.all(batch.map((q) => dumpDomAsync(q, base)));
    doms.forEach((d, j) => {
      assert.match(d, /data-ready="1"/, batch[j]);
      assert.doesNotMatch(d, /data-error=/, batch[j]);
      assert.doesNotMatch(d, /\[[a-z]+\.[a-z0-9.]+\]/, batch[j]);
    });
  }
});

test("long Arabic with tashkeel at size 3 opens full card without error", { skip }, () => {
  for (const frame of ["phone", "windows"]) {
    const d = dumpDom(`day=noon&frame=${frame}&long=1&size=3&popup=small`);
    assert.match(d, /data-id="card"[^>]*data-size="full"/, frame);
    assert.doesNotMatch(d, /data-error=/, frame);
  }
});

test("panel=sim in URL opens the simulator panel", { skip }, () => {
  const d = dumpDom("day=noon&panel=sim");
  assert.match(d, /data-id="sim"/);
  assert.doesNotMatch(d, /data-error=/);
});

test("settings edited while simulator is open survive backward replay", { skip }, () => {
  const d = dumpDom("day=noon&sim=responsive&simTo=23:00&route=more/freq&autoClick=more-freq-often,sim-play");
  assert.match(d, /data-id="more-freq-often"[^>]*aria-checked="true"|aria-checked="true"[^>]*data-id="more-freq-often"/);
  assert.doesNotMatch(d, /data-error=/);
});

test("today companion hub removes duplicate dhikr list and shows unified now-card, emotional doorways, hadith, progress, and parent preset", { skip }, () => {
  const noon = dumpDom("day=noon&lang=en&route=today");
  assert.doesNotMatch(noon, /data-id="today-list"/);
  assert.match(noon, /data-id="now-card"[\s\S]*data-id="moment-evening"[^>]*data-state="later"[\s\S]*data-id="pause"/);
  assert.match(noon, /data-id="today-progress"/);
  assert.match(noon, /data-id="today-doors"/);
  assert.match(noon, /data-id="today-hadith"/);
  assert.match(noon, /data-id="today-quick"[\s\S]*data-id="open-parent-preset"/);
  assert.match(noon, /data-id="today-guide"/);

  const missed = dumpDom("day=missed&lang=en&route=today");
  assert.match(missed, /data-id="moment-waking"[^>]*data-state="missed"/);
  assert.doesNotMatch(missed, /data-error=/);
});

test("SVG pocket misbaha, variable fadl unlock, emotional doorway sheet, and 30s parent preset work end-to-end", { skip }, () => {
  const cnt = dumpDom("day=noon&route=count/d17424625ae");
  assert.match(cnt, /data-id="misbaha-svg"/);
  const done = dumpDom("day=noon&route=count/d17424625ae&autoClick=card");
  assert.match(done, /data-id="cele-gem"/);

  const door = dumpDom("day=noon&route=today&autoClick=door-anxious");
  assert.match(door, /data-id="door-sheet"/);
  assert.match(door, /data-id="door-say-/);

  const parent = dumpDom("day=first&autoClick=ob-parent-preset,apply-parent-preset");
  assert.match(parent, /<html[^>]*data-size="7"/);
  assert.doesNotMatch(parent, /data-error=/);
});

test("7-stage text size slider, Your day with Dhikr trackers, Friday card, and 33-bead 3D misbaha work", { skip }, () => {
  const sz = dumpDom("day=noon&size=1&route=more/size");
  assert.match(sz, /<html[^>]*data-size="1"/);
  assert.match(sz, /data-id="more-size-slider"[^>]*max="7"|max="7"[^>]*data-id="more-size-slider"/);
  assert.match(sz, /data-id="more-size-7"/);

  const noon = dumpDom("day=noon&lang=en&route=today");
  assert.match(noon, /Your day with Dhikr/);
  assert.match(noon, /data-id="today-prog-details"/);
  assert.match(noon, /data-id="prog-stat-finished"/);
  assert.match(noon, /data-id="prog-stat-streak"/);
  assert.match(noon, /data-id="prog-stat-moments"/);
  assert.match(noon, /data-id="today-prog-insight"/);
  assert.doesNotMatch(noon, /data-id="today-friday"/);

  const fri = dumpDom("day=friday&lang=en&route=today&autoClick=friday-kahf,friday-kahf-yes,friday-salawat");
  assert.match(fri, /data-id="today-friday"/);
  assert.match(fri, /class="[^"]*is-finished[^"]*"[^>]*data-id="friday-kahf"|data-id="friday-kahf"[^>]*class="[^"]*is-finished/);
  assert.match(fri, />Read</);
  assert.match(fri, /data-id="friday-jumuah"/);

  const friJump = dumpDom("day=friday&lang=en&route=today&autoClick=friday-jumuah");
  assert.match(friJump, /data-id="adhkar-jumuah-section"/);

  const singleBeadCount = dumpDom("day=noon&route=count/d17424625ae");
  assert.equal((singleBeadCount.match(/class="misbaha-bead/g) || []).length, 32);
  assert.doesNotMatch(singleBeadCount, /data-error=/);
});

test("comments #21-#30: card-recite toggle, clickable parent-sheet items, sleep sky, linked heatmap, adaptive level, and living grove", { skip }, () => {
  const jum0 = dumpDom("day=friday&lang=ar&route=session/jumuah");
  assert.match(jum0, /<button[^>]*data-id="card-recite"[^>]*aria-pressed="true"|<button[^>]*aria-pressed="true"[^>]*data-id="card-recite"/);
  const jumMuted = dumpDom("day=friday&lang=ar&route=session/jumuah&autoClick=card-recite");
  assert.match(jumMuted, /data-id="card-recite"[^>]*aria-pressed="false"|aria-pressed="false"[^>]*data-id="card-recite"/);
  assert.match(jumMuted, /data-icon="sound-off"/);
  assert.match(jumMuted, /data-id="card-count"[^>]*data-done="0"/);
  assert.doesNotMatch(jumMuted, /data-error=/);

  const customParent = dumpDom("day=noon&route=more&autoClick=more-row-parent,parent-feat-size,parent-feat-recite,apply-parent-preset");
  assert.match(customParent, /<html[^>]*data-size="6"/);
  assert.doesNotMatch(customParent, /data-error=/);

  const slp0 = dumpDom("day=noon&route=more/sleep");
  assert.match(slp0, /data-id="sleep-sky"/);
  assert.match(slp0, /data-id="sleep-sun"/);
  assert.match(slp0, /data-id="sleep-moon"/);
  const slp1 = dumpDom("day=noon&route=more/sleep&autoClick=more-wake-earlier");
  assert.match(slp1, /data-id="sleep-sky"[^>]*data-focus="wake"|data-focus="wake"[^>]*data-id="sleep-sky"/);

  const friDays = dumpDom("day=friday&lang=ar&route=days");
  assert.match(friDays, /data-id="days-calendar"/);
  assert.ok((friDays.match(/data-id="cal-chain-link"/g) || []).length >= 4);
  assert.match(friDays, /class="cal-slot is-chain/);

  const friToday = dumpDom("day=friday&lang=ar&route=today");
  assert.match(friToday, /data-id="prog-stat-streak"[^>]*data-stage="tree"|data-stage="tree"[^>]*data-id="prog-stat-streak"/);
  assert.match(friToday, /data-id="living-grove"/);
  assert.match(friToday, /class="grove-sway/);
  assert.match(friToday, /data-id="prog-stat-moments"[^>]*data-level="\d+"|data-level="\d+"[^>]*data-id="prog-stat-moments"/);

  const lvSheet = dumpDom("day=friday&lang=ar&route=today&autoClick=prog-stat-moments");
  assert.match(lvSheet, /data-id="level-sheet"/);

  const fieldToday = dumpDom("day=weekup&lang=en&route=today");
  assert.match(fieldToday, /data-stage="field"/);

  const missedToday = dumpDom("day=missed&lang=en&route=today");
  assert.match(missedToday, /data-stage="dormant"/);
  assert.match(missedToday, /is-tone-dormant/);
  assert.doesNotMatch(missedToday, /data-error=/);
});

test("improved now-card renders daily moments journey board, active/missed/done/later pills, weekly banner, and pause/next pill", { skip }, () => {
  const noonAr = dumpDom("day=noon&lang=ar&route=today");
  assert.match(noonAr, /الأذكار خلال اليوم/);
  for (const m of ["waking", "morning", "evening", "sleep"]) {
    assert.match(noonAr, new RegExp('data-id="moment-' + m + '"'), m);
  }
  assert.match(noonAr, /data-id="now-track-diamond"/);
  assert.match(noonAr, /data-id="now-button"[\s\S]*class="now-cta-sheen"[\s\S]*قول ذكر دلوقتي/);
  assert.match(noonAr, /data-id="pause"[\s\S]*data-id="now-next"/);
  assert.doesNotMatch(noonAr, /data-error=/);

  const pausedAr = dumpDom("day=noon&lang=ar&route=today&autoClick=pause");
  assert.match(pausedAr, /رجّع التذكير/);
  assert.doesNotMatch(pausedAr, /data-error=/);

  const weekUpAr = dumpDom("day=weekup&lang=ar&route=today");
  assert.match(weekUpAr, /data-id="now-weekly-open"[\s\S]*وقفة الأسبوع جاهزة/);
  const weekOpen = dumpDom("day=weekup&lang=ar&route=today&autoClick=now-weekly-open");
  assert.match(weekOpen, /data-screen="weekly"/);
  assert.doesNotMatch(weekOpen, /data-error=/);
});

test("audit fixes: micro-piece say-now carry, later moment session, onboarding goal, more/level, auto-adjust switch, custom dua, and banner", { skip }, () => {
  const ob2 = dumpDom("day=first&lang=en&route=onboarding/2&autoClick=ob-goal-moments");
  assert.match(ob2, /data-id="ob-goal-moments"[^>]*aria-checked="true"|aria-checked="true"[^>]*data-id="ob-goal-moments"/);
  assert.doesNotMatch(ob2, /data-error=/);

  const carryBack = dumpDom("day=noon&lang=en&route=today&autoClick=now-button,card,app-back");
  assert.match(carryBack, /data-id="now-card"[^>]*data-kind="continue"/);

  const laterTap = dumpDom("day=noon&lang=ar&route=today&autoClick=moment-sleep");
  assert.match(laterTap, /data-screen="session\/sleep"/);

  const moreLv = dumpDom("day=noon&lang=en&route=more&autoClick=more-row-level");
  assert.match(moreLv, /data-id="more-level"/);
  assert.match(moreLv, /data-id="more-goal"/);

  const customSheet = dumpDom("day=noon&lang=ar&route=add&autoClick=add-custom-open");
  assert.match(customSheet, /data-id="add-custom-sheet"/);

  const dhikrAuto = dumpDom("day=noon&lang=en&route=adhkar/" + firstId);
  assert.match(dhikrAuto, /data-id="dhikr-auto-switch"/);

  const banner = dumpDom("day=noon&lang=en&popup=banner");
  assert.match(banner, /data-id="card"[^>]*data-size="banner"/);
  assert.doesNotMatch(banner, /data-error=/);
});

test("comments #31 & #32: onboarding/1 font slider sits above language, and more/sleep 24h dial supports daytime sleep & quick picker", { skip }, () => {
  const obWin = dumpDom("day=first&frame=windows&lang=ar&route=onboarding/1&autoClick=ob-size-more");
  const idxFont = obWin.indexOf('data-id="ob-fontsize"');
  const idxLang = obWin.indexOf('data-id="ob-lang"');
  assert.ok(idxFont > 0 && idxLang > idxFont, "font slider must appear above language choice");
  assert.match(obWin, /<html[^>]*data-size="4"/);
  assert.doesNotMatch(obWin, /data-error=/);

  const shiftSleep = dumpDom("day=noon&lang=ar&size=7&route=more/sleep&autoClick=sleep-preset-shift,more-wake-value");
  assert.match(shiftSleep, /data-id="sleep-sky"/);
  assert.match(shiftSleep, /data-id="sleep-sun"/);
  assert.match(shiftSleep, /data-id="sleep-moon"/);
  assert.match(shiftSleep, /data-id="sleep-quick-sheet"/);
  assert.match(shiftSleep, /data-id="sleep-hour-18"/);
  assert.doesNotMatch(shiftSleep, /data-error=/);
});
