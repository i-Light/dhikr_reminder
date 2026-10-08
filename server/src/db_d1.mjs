// Cloudflare D1 behind the three calls core.mjs needs.
export function d1Db(binding) {
  return {
    async run(sql, params = []) {
      const result = await binding.prepare(sql).bind(...params).run();
      return { changes: result.meta?.changes ?? 0 };
    },
    async get(sql, params = []) {
      return (await binding.prepare(sql).bind(...params).first()) ?? undefined;
    },
    async all(sql, params = []) {
      const result = await binding.prepare(sql).bind(...params).all();
      return result.results ?? [];
    },
  };
}
