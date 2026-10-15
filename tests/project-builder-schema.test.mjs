import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";

const migrationUrl = new URL("../neon/migrations/0011_project_builder_records.sql", import.meta.url);

test("Project Builder records schema is additive and bounded", async () => {
  const sql = await readFile(migrationUrl, "utf8");
  const tables = [
    ["ai_projects", "ai_projects_owner_read"],
    ["ai_project_tasks", "ai_project_tasks_owner_read"],
    ["ai_agent_runs", "ai_agent_runs_owner_read"],
    ["ai_project_artifacts", "ai_project_artifacts_owner_read"],
    ["ai_project_audit_events", "ai_project_audit_owner_read"],
  ];
  for (const [table, policy] of tables) {
    assert.ok(sql.includes("CREATE TABLE IF NOT EXISTS public." + table));
    assert.ok(sql.includes("ALTER TABLE public." + table + " ENABLE ROW LEVEL SECURITY"));
    assert.ok(sql.includes("CREATE POLICY " + policy));
  }
  assert.ok(sql.includes("FOREIGN KEY (project_id, owner_id) REFERENCES public.ai_projects(id, owner_id)"));
  assert.ok(sql.includes("CHECK (pg_column_size(metadata) <= 16384)"));
  assert.ok(sql.includes("CHECK (pg_column_size(details) <= 8192)"));
  assert.ok(sql.includes("BEGIN;") && sql.includes("COMMIT;"));
});

test("Project Builder schema does not grant browser mutation privileges", async () => {
  const sql = await readFile(migrationUrl, "utf8");
  assert.ok(sql.includes("REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON public.ai_projects,"));
  assert.ok(sql.includes("FROM authenticated;"));
  assert.ok(sql.includes("GRANT SELECT ON public.ai_projects,"));
  assert.ok(sql.includes("TO authenticated;"));
  assert.ok(sql.includes("FOR SELECT TO authenticated USING (owner_id = auth.uid())"));
  assert.equal(/GRANT ALL .* TO authenticated/i.test(sql), false);
});
