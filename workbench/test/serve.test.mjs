import { test, before, after } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, cpSync, writeFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { start } from "../serve.mjs";
import { browserPath, dumpDomAsync } from "./helpers.mjs";

const skip = browserPath() ? false : "no Edge or Chrome found, browser tests skipped";

const src = resolve(dirname(fileURLToPath(import.meta.url)), "..");
let dir, server, base;

before(async () => {
  dir = mkdtempSync(join(tmpdir(), "wb-serve-"));
  cpSync(src, dir, { recursive: true });
  server = start(0, dir);
  await new Promise((r) => (server.listening ? r() : server.once("listening", r)));
  base = "http://127.0.0.1:" + server.address().port;
});
after(() => {
  server.close();
  rmSync(dir, { recursive: true, force: true });
});

const getJson = async (p) => (await fetch(base + p)).json();
const put = (p, body) =>
  fetch(base + p, { method: "PUT", headers: { "content-type": "application/json" }, body: JSON.stringify(body) });

test("ping", async () => { assert.deepEqual(await getJson("/api/ping"), { ok: true }); });
test("comments round trip", async () => {
  await put("/api/comments", [{ id: "c1", text: "x" }]);
  assert.deepEqual(await getJson("/api/comments"), [{ id: "c1", text: "x" }]);
});
test("a full comment keeps its place and anchor", async () => {
  const c = { id: "c2", at: 5, status: "done", doneAt: 9, kind: "idea", text: "كبّر الخط",
    place: { frame: "phone", day: "noon", lang: "ar", route: "adhkar/d1", popup: null },
    anchor: { label: "Button [now-button]", dataId: "now-button", own: true, tag: "button", path: null, text: "x", fx: 0.25, fy: 0.75 } };
  await put("/api/comments", [c]);
  assert.deepEqual(await getJson("/api/comments"), [c]);
});
test("broken comments file reads as empty", async () => {
  writeFileSync(join(dir, "comments.json"), "{not json");
  assert.deepEqual(await getJson("/api/comments"), []);
});
test("cannot read outside the folder", async () => {
  assert.equal((await fetch(base + "/..%2f..%2fpubspec.yaml")).status, 404);
});
test("serves index and 404s the rest", async () => {
  assert.equal((await fetch(base + "/index.html")).status, 200);
  assert.equal((await fetch(base + "/api/nothing")).status, 404);
});
test("oversized body is refused", async () => {
  const res = await fetch(base + "/api/comments", { method: "PUT", body: "[" + " ".repeat(2 * 1024 * 1024 + 10) + "]" });
  assert.equal(res.status, 413);
});

test("a comment made by clicking a part is pinned and written to comments.json", { skip }, async () => {
  await put("/api/comments", []);
  const dom = await dumpDomAsync("day=noon&route=today&autoComment=tab-adhkar", base + "/index.html");
  assert.match(dom, /class="cmt-pin"/);
  assert.doesNotMatch(dom, /data-error=/);
  const rows = await getJson("/api/comments");
  assert.equal(rows.length, 1);
  assert.equal(rows[0].anchor.dataId, "tab-adhkar");
  assert.equal(rows[0].place.route, "today");
  assert.equal(rows[0].place.frame, "phone");
  assert.equal(rows[0].text, "auto");
});
test("comments in the file come back as pins when the page is served", { skip }, async () => {
  await put("/api/comments", [{ id: "cfile", at: 3, status: "open", doneAt: null, kind: "idea", text: "from file",
    place: { frame: "phone", day: "noon", lang: "ar", route: "today", popup: null },
    anchor: { label: "x", dataId: "tab-more", own: true, tag: "button", path: null, text: "", fx: 0.5, fy: 0.5 } }]);
  const dom = await dumpDomAsync("day=noon&route=today", base + "/index.html");
  assert.match(dom, /class="cmt-pin"/);
});
