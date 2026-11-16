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
