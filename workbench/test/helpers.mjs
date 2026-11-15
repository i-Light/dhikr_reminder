import { existsSync, mkdtempSync, rmSync } from "node:fs";
import { execFileSync } from "node:child_process";
import { tmpdir } from "node:os";
import { join, dirname, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");

export function browserPath() {
  const list = [
    "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe",
    "C:/Program Files/Google/Chrome/Application/chrome.exe",
  ];
  return list.find((p) => existsSync(p)) || null;
}

function pageUrl(query) {
  return pathToFileURL(join(root, "index.html")).href + (query ? "?" + query : "");
}

function run(extra, query) {
  const exe = browserPath();
  if (!exe) throw new Error("no browser found");
  const profile = mkdtempSync(join(tmpdir(), "wb-profile-"));
  try {
    const args = [
      "--headless=new", "--disable-gpu", "--no-first-run",
      "--user-data-dir=" + profile,
      "--virtual-time-budget=4000", ...extra, pageUrl(query),
    ];
    return execFileSync(exe, args, {
      encoding: "utf8", maxBuffer: 64 * 1024 * 1024, stdio: ["ignore", "pipe", "ignore"], timeout: 60000,
    });
  } finally {
    rmSync(profile, { recursive: true, force: true });
  }
}

export function dumpDom(query) {
  return run(["--dump-dom"], query);
}

export function shot(query, outPath, width = 1280, height = 800) {
  run(["--screenshot=" + outPath, "--window-size=" + width + "," + height], query);
  return outPath;
}
