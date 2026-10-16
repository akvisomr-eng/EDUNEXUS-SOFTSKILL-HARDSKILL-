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
  assert.equal(typeof data.inferenceDisabled, "boolean");
  assert.equal(data.knowledgeConfigured, true);
  assert.equal(data.projectExecutionConfigured, false);
  assert.ok(Array.isArray(data.capabilities) && data.capabilities.includes("project_planning"));
  assert.ok(data.knowledgeChunks >= 20);
  assert.equal("apiKey" in data, false);
});

test("AI emergency switch disables inference without exposing secrets", async () => {
  const previous = {
    AI_ENABLED: process.env.AI_ENABLED,
    MODEL_API_KEY: process.env.MODEL_API_KEY,
    MODEL_API_BASE_URL: process.env.MODEL_API_BASE_URL,
    MODEL_ID: process.env.MODEL_ID,
  };
  try {
    process.env.AI_ENABLED = "false";
    process.env.MODEL_API_KEY = "test-only-not-a-secret";
    process.env.MODEL_API_BASE_URL = "https://example.invalid/v1";
    process.env.MODEL_ID = "test-model";
    const response = await handler.fetch(new Request("https://example.test/health"));
    const data = await response.json();
    assert.equal(data.inferenceConfigured, false);
    assert.equal(data.inferenceDisabled, true);
    assert.equal(JSON.stringify(data).includes("test-only-not-a-secret"), false);
  } finally {
    for (const [key, value] of Object.entries(previous)) {
      if (value === undefined) delete process.env[key];
      else process.env[key] = value;
    }
  }
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
  for (const id of ["CURRICULUM-ID-KEMENDIKDASMEN","UNESCO-AI-STUDENT","UNESCO-GENAI-EDUCATION","ONET-SKILLS","ESCO-API","OWASP-LLM-TOP10","CURR-AI-VERIFY","CURR-SECURE-PHISHING","CURR-CAREER-PORTFOLIO","EDU-MENTOR-PEDAGOGY-LOCAL-V1","EDU-MATH-PERCENTAGE-PRICE-COMPARE-V1","EDU-HUMAN-TUTOR-ASSESSMENT-V1"]) {
    assert.ok(ids.includes(id), "missing expected knowledge source " + id);
  }
  assert.equal(corpus.version, "edunexus-curated-knowledge-2026-10-16-v5");
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

test("explicit Groq selection is server-side, fixed-endpoint, and does not fall back to Neon", async () => {
  const keys = ["AI_ENABLED", "MODEL_PROVIDER", "MODEL_API_KEY", "MODEL_API_BASE_URL", "MODEL_ID", "NEON_AI_GATEWAY_TOKEN", "NEON_AI_GATEWAY_BASE_URL"];
  const previous = Object.fromEntries(keys.map((key) => [key, process.env[key]]));
  try {
    process.env.AI_ENABLED = "true";
    process.env.MODEL_PROVIDER = "groq";
    process.env.MODEL_API_KEY = "unit-test-groq-key";
    process.env.MODEL_ID = "unit-test-model";
    // Even if gateway credentials exist, explicit Groq selection must win.
    process.env.NEON_AI_GATEWAY_TOKEN = "unit-test-neon-token";
    process.env.NEON_AI_GATEWAY_BASE_URL = "https://gateway.example.test";
    const response = await handler.fetch(new Request("https://example.test/health"));
    const data = await response.json();
    assert.equal(data.inferenceConfigured, true);
    assert.equal(data.inferenceProvider, "groq");
    assert.equal(JSON.stringify(data).includes("unit-test-groq-key"), false);
    assert.equal(JSON.stringify(data).includes("unit-test-neon-token"), false);
  } finally {
    for (const [key, value] of Object.entries(previous)) {
      if (value === undefined) delete process.env[key];
      else process.env[key] = value;
    }
  }
});

test("explicit Groq selection without a key fails closed instead of switching provider", async () => {
  const keys = ["AI_ENABLED", "MODEL_PROVIDER", "MODEL_API_KEY", "MODEL_API_BASE_URL", "MODEL_ID", "NEON_AI_GATEWAY_TOKEN", "NEON_AI_GATEWAY_BASE_URL"];
  const previous = Object.fromEntries(keys.map((key) => [key, process.env[key]]));
  try {
    process.env.AI_ENABLED = "true";
    process.env.MODEL_PROVIDER = "groq";
    delete process.env.MODEL_API_KEY;
    process.env.MODEL_ID = "unit-test-model";
    process.env.NEON_AI_GATEWAY_TOKEN = "unit-test-neon-token";
    process.env.NEON_AI_GATEWAY_BASE_URL = "https://gateway.example.test";
    const response = await handler.fetch(new Request("https://example.test/health"));
    const data = await response.json();
    assert.equal(data.inferenceConfigured, false);
    assert.equal(data.inferenceProvider, null);
  } finally {
    for (const [key, value] of Object.entries(previous)) {
      if (value === undefined) delete process.env[key];
      else process.env[key] = value;
    }
  }
});


test("public API learning catalog is curated, provenance-aware, and does not enable live external calls", async () => {
  const catalog = JSON.parse(await readFile(new URL("../knowledge/public-api-catalog.json", import.meta.url), "utf8"));
  assert.equal(catalog.version, 1);
  assert.equal(catalog.policy.live_calls_enabled, false);
  assert.ok(catalog.apis.length >= 5);
  const ids = catalog.apis.map((api) => api.id);
  assert.equal(new Set(ids).size, ids.length);
  for (const api of catalog.apis) {
    assert.ok(api.name && api.url && api.learning_use && api.terms_review);
    assert.match(api.url, /^https:\/\//);
    assert.equal(api.enabled_by_default, false);
  }
  const corpus = JSON.parse(await readFile(new URL("../neon/functions/edunexusai/knowledge.json", import.meta.url), "utf8"));
  assert.ok(corpus.chunks.some((chunk) => chunk.id === "EDU-PUBLIC-API-DISCOVERY" && chunk.url === "https://github.com/marcelscruz/public-apis"));
});
