import { test } from "node:test";
import assert from "node:assert/strict";
import { readdirSync, readFileSync } from "node:fs";
import { join, dirname, resolve, extname } from "node:path";
import { fileURLToPath } from "node:url";

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
