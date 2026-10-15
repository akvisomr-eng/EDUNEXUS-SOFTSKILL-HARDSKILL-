export function createRateLimiter({
  limit = 10,
  windowMs = 60_000,
  maxKeys = 5_000,
  sweepEvery = 256,
  now = Date.now,
} = {}) {
  if (!Number.isInteger(limit) || limit < 1) throw new TypeError("limit_must_be_positive_integer");
  if (!Number.isFinite(windowMs) || windowMs < 1) throw new TypeError("window_must_be_positive");
  if (!Number.isInteger(maxKeys) || maxKeys < 1) throw new TypeError("max_keys_must_be_positive_integer");
  if (!Number.isInteger(sweepEvery) || sweepEvery < 1) throw new TypeError("sweep_every_must_be_positive_integer");

  const buckets = new Map();
  let requestsSinceSweep = 0;

  function sweepExpired(currentTime) {
    for (const [key, bucket] of buckets) {
      if (currentTime - bucket.startedAt >= windowMs) buckets.delete(key);
    }
  }

  function makeRoom() {
    while (buckets.size >= maxKeys) {
      const oldest = buckets.keys().next();
      if (oldest.done) break;
      buckets.delete(oldest.value);
    }
  }

  return {
    check(userId) {
      if (typeof userId !== "string" || !userId) return false;
      const currentTime = now();
      requestsSinceSweep += 1;
      if (requestsSinceSweep >= sweepEvery) {
        sweepExpired(currentTime);
        requestsSinceSweep = 0;
      }

      const bucket = buckets.get(userId);
      if (!bucket || currentTime - bucket.startedAt >= windowMs) {
        if (!bucket && buckets.size >= maxKeys) {
          sweepExpired(currentTime);
          if (buckets.size >= maxKeys) makeRoom();
        }
        buckets.set(userId, { startedAt: currentTime, count: 1 });
        return true;
      }

      bucket.count = Math.min(bucket.count + 1, limit + 1);
      return bucket.count <= limit;
    },
    get size() {
      return buckets.size;
    },
  };
}
