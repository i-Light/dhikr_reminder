// node:sqlite behind the three calls core.mjs needs: for the tests and for
// `node dev.mjs`, which run the same code as the Worker without Cloudflare.
import { readFileSync } from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const schema = readFileSync(new URL('../schema.sql', import.meta.url), 'utf8');

export function openNodeDb(path = ':memory:') {
  const db = new DatabaseSync(path);
  db.exec(schema);
  const plain = (row) => (row === undefined ? undefined : { ...row });
  return {
    async run(sql, params = []) {
      const result = db.prepare(sql).run(...params);
      return { changes: Number(result.changes) };
    },
    async get(sql, params = []) {
      return plain(db.prepare(sql).get(...params));
    },
    async all(sql, params = []) {
      return db.prepare(sql).all(...params).map(plain);
    },
    close() {
      db.close();
    },
  };
}
