import { test, before, after } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, cpSync, writeFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { start } from "../serve.mjs";

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
