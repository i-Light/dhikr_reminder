import { test } from "node:test";
import assert from "node:assert/strict";
import { readdirSync, readFileSync } from "node:fs";
import { join, dirname, resolve, extname } from "node:path";
import { fileURLToPath } from "node:url";
import { createRequire } from "node:module";
import vm from "node:vm";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const exts = new Set([".js", ".css", ".html", ".md", ".mjs"]);
const ranges = [[0x2014, 0x2014], [0x2013, 0x2013], [0x2018, 0x2019], [0x201c, 0x201d],
  [0x2026, 0x2026], [0x2190, 0x21ff], [0x1f000, 0x1faff], [0x2600, 0x27bf]];

function* walk(d) {
  for (const e of readdirSync(d, { withFileTypes: true })) {
    if (e.name === "vendor") continue;
    const p = join(d, e.name);
    if (e.isDirectory()) yield* walk(p);
    else if (exts.has(extname(e.name))) yield p;
  }
}

test("every word exists in both languages and none is empty", () => {
  const STR = createRequire(import.meta.url)("../js/strings.js");
  const ar = Object.keys(STR.ar).sort(), en = Object.keys(STR.en).sort();
  assert.deepEqual(ar, en);
  for (const lang of ["ar", "en"]) for (const k of ar) {
    assert.match(k, /^[a-z]+(\.[a-z0-9]+)+$/, k);
    assert.ok(typeof STR[lang][k] === "string" && STR[lang][k].trim(), lang + " " + k);
  }
});

test("W.t picks the language, fills names and marks a missing key", () => {
  const window = { React: {}, htm: { bind: () => () => null } };
  const ctx = vm.createContext({ window, URLSearchParams });
  for (const f of ["core.js", "strings.js"]) vm.runInContext(readFileSync(join(root, "js", f), "utf8"), ctx);
  const W = window.W;
  W.STR.ar["test.hi"] = W.STR.en["test.hi"] = "{name} {n} {gone}";
  assert.equal(W.t("tab.today"), W.STR.ar["tab.today"]);
  W.U().lang = "en";
  assert.equal(W.t("tab.today"), "Today");
  assert.equal(W.t("test.hi", { name: "Ali", n: 0 }), "Ali 0 {gone}");
  assert.equal(W.t("no.such"), "[no.such]");
});

test("no forbidden characters in workbench files", () => {
  const bad = [];
  for (const f of walk(root)) {
    for (const ch of readFileSync(f, "utf8")) {
      const c = ch.codePointAt(0);
      if (ranges.some(([a, b]) => c >= a && c <= b)) bad.push(f + " U+" + c.toString(16));
    }
  }
  assert.deepEqual(bad, []);
});
