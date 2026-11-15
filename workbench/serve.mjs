import http from "node:http";
import { readFileSync, writeFileSync, renameSync, existsSync, statSync } from "node:fs";
import { join, resolve, extname, sep, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const TYPES = {
  ".html": "text/html; charset=utf-8", ".js": "text/javascript; charset=utf-8", ".mjs": "text/javascript; charset=utf-8",
  ".css": "text/css; charset=utf-8", ".json": "application/json; charset=utf-8", ".svg": "image/svg+xml",
  ".png": "image/png", ".jpg": "image/jpeg", ".woff2": "font/woff2", ".woff": "font/woff", ".ttf": "font/ttf", ".md": "text/plain; charset=utf-8",
};
const MAX_BODY = 2 * 1024 * 1024;

export function start(port = 4173, dir = here) {
  const root = resolve(dir);
  const commentsFile = join(root, "comments.json");
  const send = (res, code, body, type = "application/json; charset=utf-8") => {
    res.writeHead(code, { "content-type": type, "cache-control": "no-store" });
    res.end(body);
  };
  const readComments = () => {
    try {
      const v = JSON.parse(readFileSync(commentsFile, "utf8"));
      return Array.isArray(v) ? v : [];
    } catch { return []; }
  };

  const server = http.createServer((req, res) => {
    let path;
    try { path = decodeURIComponent(new URL(req.url, "http://x").pathname); }
    catch { return send(res, 404, "{}"); }

    if (path === "/api/ping" && req.method === "GET") return send(res, 200, '{"ok":true}');
    if (path === "/api/comments" && req.method === "GET") return send(res, 200, JSON.stringify(readComments()));
    if (path === "/api/comments" && req.method === "PUT") {
      const chunks = [];
      let size = 0, refused = false;
      req.on("data", (c) => {
        if (refused) return;
        size += c.length;
        if (size > MAX_BODY) {
          refused = true;
          res.writeHead(413, { "content-type": "application/json; charset=utf-8", connection: "close" });
          res.end('{"error":"too large"}');
          return;
        }
        chunks.push(c);
      });
      req.on("end", () => {
        if (refused) return;
        let v;
        try { v = JSON.parse(Buffer.concat(chunks).toString("utf8")); } catch { return send(res, 400, '{"error":"bad json"}'); }
        if (!Array.isArray(v)) return send(res, 400, '{"error":"array expected"}');
        const tmp = commentsFile + ".tmp";
        writeFileSync(tmp, JSON.stringify(v, null, 2));
        renameSync(tmp, commentsFile);
        send(res, 200, '{"ok":true}');
      });
      return;
    }
    if (req.method !== "GET" || path.startsWith("/api/")) return send(res, 404, "{}");

    const file = resolve(root, "." + (path === "/" ? "/index.html" : path));
    if ((file !== root && !file.startsWith(root + sep)) || !existsSync(file) || !statSync(file).isFile()) return send(res, 404, "{}");
    send(res, 200, readFileSync(file), TYPES[extname(file)] || "application/octet-stream");
  });
  server.listen(port, "127.0.0.1");
  return server;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const port = Number(process.env.PORT) || 4173;
  start(port).on("listening", () => console.log("Dhikr workbench at http://127.0.0.1:" + port + "/"));
}
