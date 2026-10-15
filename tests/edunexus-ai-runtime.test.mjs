import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import handler, { buildKnowledgeOnlyAnswer, selectAgents } from "../neon/functions/edunexusai/index.mjs";

test("health endpoint exposes configuration state without secrets", async () => {
  const response = await handler.fetch(new Request("https://example.test/health"));
  assert.equal(response.status, 200);
  const data = await response.json();
  assert.equal(data.service, "edunexus-ai");
  assert.equal(typeof data.inferenceConfigured, "boolean");
  assert.equal(data.knowledgeConfigured, true);
  assert.ok(data.knowledgeChunks >= 20);
  assert.equal("apiKey" in data, false);
});

test("unknown paths fail closed", async () => {
  const response = await handler.fetch(new Request("https://example.test/admin"));
  assert.equal(response.status, 404);
});

test("chat requires a valid authenticated caller", async () => {
  const response = await handler.fetch(new Request("https://example.test/chat", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ message: "Bantu saya belajar komunikasi" }),
  }));
  assert.equal(response.status, 401);
  assert.equal((await response.json()).error, "authentication_required");
});

test("OPTIONS supports CORS preflight without invoking inference", async () => {
  const response = await handler.fetch(new Request("https://example.test/chat", {
    method: "OPTIONS",
    headers: { origin: "https://akvisomr-eng.github.io" },
  }));
  assert.equal(response.status, 204);
  assert.equal(response.headers.get("access-control-allow-origin"), "https://akvisomr-eng.github.io");
});

test("disallowed origins cannot invoke chat", async () => {
  const response = await handler.fetch(new Request("https://example.test/chat", {
    method: "POST",
    headers: { origin: "https://attacker.example", "content-type": "application/json" },
    body: JSON.stringify({ message: "Belajar" }),
  }));
  assert.equal(response.status, 403);
});

test("curated knowledge corpus has source provenance and unique chunk ids", async () => {
  const corpus = JSON.parse(await readFile(new URL("../neon/functions/edunexusai/knowledge.json", import.meta.url), "utf8"));
  assert.ok(Array.isArray(corpus.chunks) && corpus.chunks.length >= 8);
  const ids = corpus.chunks.map((chunk) => chunk.id);
  assert.equal(new Set(ids).size, ids.length);
  for (const chunk of corpus.chunks) {
    assert.ok(chunk.title && chunk.url && chunk.text && chunk.trust_tier);
    assert.match(chunk.url, /^https:\/\//);
  }
  for (const id of ["CURRICULUM-ID-KEMENDIKDASMEN","UNESCO-AI-STUDENT","UNESCO-GENAI-EDUCATION","ONET-SKILLS","ESCO-API","OWASP-LLM-TOP10","CURR-AI-VERIFY","CURR-SECURE-PHISHING","CURR-CAREER-PORTFOLIO"]) {
    assert.ok(ids.includes(id), "missing expected knowledge source " + id);
  }
  assert.equal(corpus.version, "edunexus-curated-knowledge-2026-10-14-v3");
});

test("knowledge-only fallback is transparent and grounded in retrieved chunks", () => {
  const answer = buildKnowledgeOnlyAnswer([{ title: "UNESCO AI Framework", text: "Verify AI outputs and protect learner privacy." }]);
  assert.match(answer, /tanpa model generatif/i);
  assert.match(answer, /UNESCO AI Framework/);
  assert.match(answer, /protect learner privacy/);
  assert.match(buildKnowledgeOnlyAnswer([]), /tidak dibuat-buat/i);
});


test("project mode routes to a bounded specialist team without claiming execution", () => {
  const agents = selectAgents("Bangun aplikasi inventaris UMKM", "project");
  assert.deepEqual(agents.map(([id]) => id), ["projectManager", "architect", "engineer", "qa"]);
  assert.ok(agents.every(([, agent]) => agent.instruction && agent.label));
  const source = readFile(new URL("../neon/functions/edunexusai/index.mjs", import.meta.url), "utf8");
  return source.then((raw) => {
    assert.match(raw, /project_builder_not_configured/);
    assert.match(raw, /projectExecutionConfigured: false/);
    assert.match(raw, /Tidak ada rencana proyek simulasi/);
  });
});

test("project mode cannot claim repo or deployment execution", () => {
  const agents = selectAgents("Bangun dan deploy website", "project");
  assert.equal(agents.length, 4);
  assert.deepEqual(agents.map(([id]) => id), ["projectManager", "architect", "engineer", "qa"]);
  assert.ok(agents.every(([, agent]) => agent.instruction.length > 30));
});
