import test from "node:test";
import assert from "node:assert/strict";
import { consumePersistentQuota } from "../neon/functions/edunexusai/persistent-quota.mjs";

test("quota RPC sends authenticated POST and parses an allowed result", async () => {
  let observed;
  const result = await consumePersistentQuota({
    baseUrl: "https://example.neon.tech/neondb",
    token: "signed.jwt.value",
    fetchImpl: async (url, options) => {
      observed = { url, options };
      return new Response(JSON.stringify([{
        allowed: true,
        minute_used: 2,
        day_used: 12,
        minute_resets_at: "2026-10-15T10:01:00Z",
        day_resets_at: "2026-10-16T00:00:00Z",
      }]), { status: 200, headers: { "content-type": "application/json" } });
    },
  });
  assert.equal(observed.url, "https://example.neon.tech/neondb/rest/v1/rpc/consume_edunexus_ai_quota");
  assert.equal(observed.options.method, "POST");
  assert.equal(observed.options.headers.authorization, "Bearer signed.jwt.value");
  assert.equal(observed.options.body, "{}");
  assert.equal(result.allowed, true);
  assert.equal(result.minuteUsed, 2);
  assert.equal(result.dayUsed, 12);
});

test("quota RPC preserves a denied decision", async () => {
  const result = await consumePersistentQuota({
    baseUrl: "https://example.neon.tech/neondb/rest/v1/",
    token: "jwt",
    fetchImpl: async () => new Response(JSON.stringify([{
      allowed: false, minute_used: 11, day_used: 101,
      minute_resets_at: "x", day_resets_at: "y",
    }]), { status: 200 }),
  });
  assert.equal(result.allowed, false);
});

test("quota client fails closed for missing credentials, HTTP errors, and malformed payloads", async () => {
  await assert.rejects(consumePersistentQuota({ baseUrl: "", token: "jwt" }), /quota_service_unavailable/);
  await assert.rejects(consumePersistentQuota({ baseUrl: "https://example.neon.tech", token: "" }), /quota_service_unavailable/);
  await assert.rejects(consumePersistentQuota({
    baseUrl: "https://example.neon.tech", token: "jwt",
    fetchImpl: async () => new Response("unavailable", { status: 503 }),
  }), /quota_service_unavailable/);
  await assert.rejects(consumePersistentQuota({
    baseUrl: "https://example.neon.tech", token: "jwt",
    fetchImpl: async () => new Response("{}", { status: 200 }),
  }), /quota_service_unavailable/);
  await assert.rejects(consumePersistentQuota({
    baseUrl: "http://example.neon.tech", token: "jwt",
    fetchImpl: async () => { throw new Error("should not be called"); },
  }), /quota_service_unavailable/);
});
