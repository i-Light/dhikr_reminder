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

test("gallery lists every icon, part and motion, and the root carries look, theme and size", { skip }, () => {
  const dom = dumpDom("route=gallery&look=b&theme=dark&size=3");
  assert.match(dom, /<html[^>]*data-look="b"/);
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

test("frame, language and look follow the URL", { skip }, () => {
  const dom = dumpDom("day=noon&lang=en&frame=windows&look=b&theme=dark&size=3");
  assert.match(dom, /data-id="desktop"[^>]*dir="ltr"/);
  assert.match(dom, /data-id="desktop-window"/);
  assert.match(dom, /data-look="b"/);
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

for (let i = 1; i <= 6; i++) test("onboarding step " + i, { skip }, () => {
  const dom = dumpDom("day=first&route=onboarding/" + i);
  assert.match(dom, new RegExp('data-screen="onboarding/' + i + '"'));
  assert.match(dom, /data-id="ob-question"/);
  if (i < 6) assert.match(dom, /data-id="choose-for-me"/);
  if (i > 1) assert.match(dom, /data-id="ob-back"/);
  assert.doesNotMatch(dom, /data-error=/);
  assert.doesNotMatch(dom, /\[[a-z]+\.[a-z.0-9]+\]/);
});

test("onboarding step 1 offers Arabic and English", { skip }, () => {
  const dom = dumpDom("day=first");
  assert.match(dom, /اللغة العربية/);
  assert.match(dom, /English/);
});

test("Choose for me five times, then the permissions, lands on Today", { skip }, () => {
  const five = Array(5).fill("choose-for-me").join(",");
  const dom = dumpDom("day=first&autoClick=" + five + ",perm-allow,perm-notnow,perm-allow");
  assert.match(dom, /data-screen="today"/);
  assert.doesNotMatch(dom, /data-error=/);
});

test("on Windows onboarding has no permission step", { skip }, () => {
  const five = Array(5).fill("choose-for-me").join(",");
  assert.match(dumpDom("day=first&frame=windows&autoClick=" + five), /data-screen="today"/);
});

test("the try step offers the two sizes only after three taps", { skip }, () => {
  assert.doesNotMatch(dumpDom("day=first&route=onboarding/5"), /data-id="ob-size"/);
  assert.match(dumpDom("day=first&route=onboarding/5&autoClick=card,card,card"), /data-id="ob-size"/);
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

test("my adhkar", { skip }, () => { const d = dumpDom("day=noon&route=adhkar"); assert.match(d, /data-id="add-dhikr"/); assert.match(d, /data-id="adhkar-row-/); });
test("add shows six suggestions", { skip }, () => { assert.equal((dumpDom("day=noon&route=add").match(/data-suggest="1"/g) || []).length, 6); });
test("a dhikr page", { skip }, () => { assert.match(dumpDom("day=noon&route=adhkar/" + firstId), /data-id="stepper"/); });

test("weekly up", { skip }, () => { const d = dumpDom("day=weekup&route=weekly"); assert.match(d, /data-id="weekly-change-/); assert.match(d, /data-id="weekly-refuse-/); });
test("weekly heavy", { skip }, () => { const d = dumpDom("day=weekheavy&route=weekly"); for (const k of ["keep","lighter","rest"]) assert.match(d, new RegExp('data-id="heavy-' + k)); });
test("session", { skip }, () => assert.match(dumpDom("day=noon&route=session/morning"), /data-id="session-progress"/));
test("moment card", { skip }, () => assert.match(dumpDom("day=noon&popup=moment"), /data-id="moment-start"/));

test("more rows", { skip }, () => { const d = dumpDom("day=noon&route=more"); for (const r of ["freq","sleep","look","sound","lang","size","days"]) assert.match(d, new RegExp('data-id="more-row-' + r)); });

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
    ["first", "onboarding/4"], ["first", "onboarding/5"], ["first", "onboarding/6"],
    ["noon", "today"], ["noon", "adhkar"], ["noon", "adhkar/" + firstId],
    ["noon", "add"], ["noon", "add/morning"], ["noon", "moments"], ["noon", "moments/morning"],
    ["noon", "session/morning"], ["noon", "count/" + firstId], ["noon", "weekly"], ["weekup", "weekly"],
    ["noon", "more"], ["noon", "more/freq"], ["noon", "more/sleep"], ["noon", "more/look"],
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
