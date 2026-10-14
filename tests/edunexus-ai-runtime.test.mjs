import test from "node:test";
import assert from "node:assert/strict";
import handler from "../neon/functions/edunexusai/index.mjs";

test("health endpoint exposes configuration state without secrets", async () => {
  const response = await handler.fetch(new Request("https://example.test/health"));
  assert.equal(response.status, 200);
  const data = await response.json();
  assert.equal(data.service, "edunexus-ai");
  assert.equal(typeof data.inferenceConfigured, "boolean");
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
