import { test } from "node:test";
import assert from "node:assert/strict";
import { browserPath, dumpDom } from "./helpers.mjs";

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
