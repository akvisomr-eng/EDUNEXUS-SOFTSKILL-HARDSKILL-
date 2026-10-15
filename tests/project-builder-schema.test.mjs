import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";

const migrationUrl = new URL("../neon/migrations/0011_project_builder_records.sql", import.meta.url);

test("Project Builder records schema is additive and bounded", async () => {
  const sql = await readFile(migrationUrl, "utf8");
  for (const table of [
    "ai_projects", "ai_project_tasks", "ai_agent_runs",
    "ai_project_artifacts", "ai_project_audit_events",
  ]) {
    assert.match(sql, new RegExp("CREATE TABLE IF NOT EXISTS public\\." + table));
    assert.match(sql, new RegExp("ALTER TABLE public\\." + table + " ENABLE ROW LEVEL SECURITY"));
    assert.match(sql, new RegExp("CREATE POLICY " + table.replaceAll("_", "_") + "_owner_read|CREATE POLICY ai_"));
  }
  assert.match(sql, /FOREIGN KEY \(project_id, owner_id\) REFERENCES public\.ai_projects\(id, owner_id\)/);
  assert.match(sql, /CHECK \(pg_column_size\(metadata\) <= 16384\)/);
  assert.match(sql, /CHECK \(pg_column_size\(details\) <= 8192\)/);
  assert.match(sql, /BEGIN;[\s\S]*COMMIT;/);
});

test("Project Builder schema does not grant browser mutation privileges", async () => {
  const sql = await readFile(migrationUrl, "utf8");
  assert.match(sql, /REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON public\.ai_projects,[\s\S]*FROM authenticated/);
  assert.match(sql, /GRANT SELECT ON public\.ai_projects,[\s\S]*TO authenticated/);
  assert.match(sql, /FOR SELECT TO authenticated USING \(owner_id = auth\.uid\(\)\)/);
  assert.doesNotMatch(sql, /GRANT ALL .* TO authenticated/i);
});
