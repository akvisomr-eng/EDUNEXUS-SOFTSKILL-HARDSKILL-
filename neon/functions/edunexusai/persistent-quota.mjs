function normalizeDataApiUrl(value) {
  if (typeof value !== "string" || !value.trim()) throw new Error("quota_service_unavailable");
  let url;
  try { url = new URL(value); } catch { throw new Error("quota_service_unavailable"); }
  if (url.protocol !== "https:") throw new Error("quota_service_unavailable");
  url.search = "";
  url.hash = "";
  url.pathname = url.pathname.replace(/\/+$/, "");
  if (!url.pathname.endsWith("/rest/v1")) url.pathname += "/rest/v1";
  return url.toString().replace(/\/$/, "");
}

export async function consumePersistentQuota({ baseUrl, token, fetchImpl = fetch, timeoutMs = 5000 } = {}) {
  if (typeof token !== "string" || !token || token.length > 10_000) throw new Error("quota_service_unavailable");
  const endpoint = normalizeDataApiUrl(baseUrl) + "/rpc/consume_edunexus_ai_quota";
  let response;
  try {
    response = await fetchImpl(endpoint, {
      method: "POST",
      headers: {
        authorization: "Bearer " + token,
        "content-type": "application/json",
        accept: "application/json",
      },
      body: "{}",
      signal: AbortSignal.timeout(timeoutMs),
    });
  } catch {
    throw new Error("quota_service_unavailable");
  }
  if (!response.ok) throw new Error("quota_service_unavailable");
  let payload;
  try { payload = await response.json(); } catch { throw new Error("quota_service_unavailable"); }
  const row = Array.isArray(payload) ? payload[0] : payload;
  if (!row || typeof row.allowed !== "boolean") throw new Error("quota_service_unavailable");
  return {
    allowed: row.allowed,
    minuteUsed: Number(row.minute_used),
    dayUsed: Number(row.day_used),
    minuteResetsAt: row.minute_resets_at,
    dayResetsAt: row.day_resets_at,
  };
}
