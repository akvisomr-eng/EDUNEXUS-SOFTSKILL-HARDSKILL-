import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createSupabaseContext } from "npm:@supabase/server@1";
import { Pool } from "jsr:@db/postgres@^0.19";

const corsHeaders = {
  "Access-Control-Allow-Origin": "https://akvisomr-eng.github.io",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const db = new Pool(Deno.env.get("SUPABASE_DB_URL")!, 1, true);

type AttemptRow = {
  id: string; user_id: string; session_id: string; status: string;
  score: number | null; response: Record<string, unknown>; scenario_id: string;
};
type ScenarioRow = { id: string; instructions: { response_fields?: Array<{ key: string }> } };

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status, headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
function scoreStructuredResponse(response: Record<string, unknown>, fields: Array<{ key: string }>) {
  if (!fields.length) return 0;
  const completed = fields.filter((field) => {
    const value = response[field.key];
    return typeof value === "string" && value.trim().length >= 12;
  }).length;
  return Math.round((completed / fields.length) * 100);
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  const { data: ctx, error: authError } = await createSupabaseContext(req, { auth: "user" });
  if (authError || !ctx?.userClaims?.sub) return json({ error: "unauthorized" }, 401);

  const userId = ctx.userClaims.sub;
  const body = await req.json().catch(() => null) as { action?: string; attempt_id?: string } | null;
  if (body?.action !== "finalize" || !body.attempt_id) {
    return json({ error: "action_finalize_and_attempt_id_required" }, 400);
  }

  const connection = await db.connect();
  try {
    const attemptResult = await connection.queryObject<AttemptRow>\`
      select a.id, a.user_id, a.session_id, a.status, a.score, a.response, s.scenario_id
      from public.practice_attempts a
      join public.practice_sessions s on s.id = a.session_id
      where a.id = \${body.attempt_id}::uuid and a.user_id = \${userId}::uuid limit 1
    \`;
    const attempt = attemptResult.rows[0];
    if (!attempt) return json({ error: "attempt_not_found" }, 404);
    if (attempt.status !== "submitted") return json({ error: "attempt_must_be_submitted" }, 409);

    const scenarioResult = await connection.queryObject<ScenarioRow>\`
      select id, instructions from public.practice_scenarios where id = \${attempt.scenario_id}::uuid
    \`;
    const scenario = scenarioResult.rows[0];
    if (!scenario) return json({ error: "scenario_not_found" }, 404);

    let score = attempt.score;
    if (score === null) {
      score = scoreStructuredResponse(attempt.response ?? {}, scenario.instructions?.response_fields ?? []);
      await connection.queryObject\`
        select private.finalize_practice_attempt(\${attempt.id}::uuid, \${score}::numeric)
      \`;
    }

    await connection.queryObject\`
      select private.ingest_practice_evidence(\${attempt.id}::uuid)
    \`;
    await connection.queryObject\`
      update public.practice_sessions
      set status='completed', completed_at=coalesce(completed_at, now()), submitted_at=coalesce(submitted_at, now())
      where id=\${attempt.session_id}::uuid and user_id=\${userId}::uuid and status='submitted'
    \`;

    const evidence = await connection.queryObject<{
      id: string; skill_id: string; score: number | null; status: string; summary: string | null;
    }>\`
      select id, skill_id, score, status, summary
      from public.skill_evidence
      where source_id=\${attempt.id}::uuid and source_type='practice_attempt'
      order by created_at
    \`;

    return json({
      status: "completed", score, evidence: evidence.rows,
      review_status: evidence.rows.length ? "pending_mentor_review" : "no_evidence_generated",
      mastery_updated: false,
      note: "Practice evidence is a candidate until an authorized mentor verifies it.",
    });
  } catch (error) {
    return json({ error: String(error instanceof Error ? error.message : error) }, 500);
  } finally {
    connection.release();
  }
});