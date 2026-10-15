import test from "node:test";
import assert from "node:assert/strict";
import { createRateLimiter } from "../neon/functions/edunexusai/rate-limit.mjs";

test("rate limiter blocks requests after the configured limit", () => {
  const limiter = createRateLimiter({ limit: 2, windowMs: 60_000, now: () => 1000 });
  assert.equal(limiter.check("account-a"), true);
  assert.equal(limiter.check("account-a"), true);
  assert.equal(limiter.check("account-a"), false);
  assert.equal(limiter.check("account-a"), false);
});

test("rate limiter resets after its window", () => {
  let now = 1000;
  const limiter = createRateLimiter({ limit: 1, windowMs: 100, now: () => now });
  assert.equal(limiter.check("account-a"), true);
  assert.equal(limiter.check("account-a"), false);
  now += 100;
  assert.equal(limiter.check("account-a"), true);
});

test("rate limiter bounds retained identities", () => {
  const limiter = createRateLimiter({ limit: 1, maxKeys: 2, sweepEvery: 100, now: () => 1000 });
  assert.equal(limiter.check("account-a"), true);
  assert.equal(limiter.check("account-b"), true);
  assert.equal(limiter.check("account-c"), true);
  assert.equal(limiter.size, 2);
});

test("rate limiter rejects missing identities and invalid limits", () => {
  const limiter = createRateLimiter();
  assert.equal(limiter.check(""), false);
  assert.equal(limiter.check(null), false);
  assert.equal(limiter.size, 0);
  assert.throws(() => createRateLimiter({ limit: 0 }), /limit_must_be_positive_integer/);
});
