import { chromium } from "playwright";

const base = process.env.SMOKE_BASE_URL || "http://127.0.0.1:4173/tests/fixtures/neon-cutover-smoke.html";
const email = `edunexus-smoke-${Date.now()}-${Math.random().toString(16).slice(2)}@example.com`;
const password = `N3on-Smoke-${Date.now()}!a`;
const browser = await chromium.launch({ headless: true });
const context = await browser.newContext();
const page = await context.newPage();
const failures = [];
const diagnostics = [];
page.on("pageerror", error => diagnostics.push("PAGEERROR: " + error.message));
page.on("console", msg => { if (msg.type() === "error") diagnostics.push("CONSOLE: " + msg.text()); });
page.on("requestfailed", request => diagnostics.push("REQUEST FAILED: " + request.method() + " " + request.url() + " — " + (request.failure()?.errorText || "unknown")));
page.on("response", response => {
  if (/neonauth|\/auth\//i.test(response.url()) && response.status() >= 400) {
    diagnostics.push("AUTH HTTP " + response.status() + ": " + response.url());
  }
});

async function waitForStatusChange() {
  await page.waitForFunction(() => {
    const text = document.querySelector("#authStatus")?.textContent?.trim();
    return text && text !== "Belum terautentikasi.";
  }, null, { timeout: 30000 });
  return (await page.locator("#authStatus").innerText()).trim();
}

try {
  await page.goto(base, { waitUntil: "domcontentloaded", timeout: 60000 });
  await page.locator("#email").fill(email);
  await page.locator("#password").fill(password);
  await page.locator("#name").fill("EDUNEXUS automated smoke test");
  await page.locator("#signup").click();
  const signupStatus = await waitForStatusChange().catch(async error => {
    diagnostics.push("SIGNUP WAIT: " + error.message);
    return (await page.locator("#authStatus").innerText().catch(() => "(status unavailable)")).trim();
  });
  console.log("SIGNUP_STATUS=" + signupStatus);
  if (!signupStatus.includes("Pendaftaran berhasil")) {
    throw new Error("Neon Auth signup did not succeed. " + signupStatus + (diagnostics.length ? "\n" + diagnostics.join("\n") : ""));
  }

  await page.locator("#signin").click();
  await page.waitForFunction(() => document.querySelector("#authStatus")?.textContent?.includes("Login berhasil"), null, { timeout: 30000 })
    .catch(async error => { throw new Error("Neon Auth sign-in did not succeed: " + (await page.locator("#authStatus").innerText()) + "\n" + error.message); });

  await page.locator("#run").click();
  await page.waitForFunction(() => {
    const rows = [...document.querySelectorAll("#checks .check")];
    return rows.length >= 8 || rows.some(row => row.textContent.includes("Pemeriksaan gagal"));
  }, null, { timeout: 20000 });

  const checks = await page.locator("#checks .check").allTextContents();
  console.log("SMOKE_CHECKS=" + JSON.stringify(checks));
  const required = [
    "JWT nyata dari Neon Auth",
    "Profil sendiri dibuat aman",
    "RPC current_user_id",
    "Kuota AI persisten per akun",
    "Baca katalog praktik",
    "Alur praktik dan finalisasi tepercaya",
    "Bukti praktik sebagai kandidat",
    "RLS sesi praktik milik pengguna",
  ];
  for (const label of required) {
    const row = checks.find(value => value.includes(label));
    if (!row || !row.startsWith("LULUS")) failures.push(`Check failed: ${label}: ${row || "missing"}`);
  }
  const aiBase = "https://br-quiet-frost-azemctlk-edunexusai.compute.c-3.ap-southeast-1.aws.neon.tech";
  const aiHealthResponse = await page.request.get(aiBase + "/health", { timeout: 20000 });
  if (!aiHealthResponse.ok()) {
    failures.push("AI runtime health check failed: HTTP " + aiHealthResponse.status());
  } else {
    const aiHealth = await aiHealthResponse.json();
    if (aiHealth.persistentQuotaConfigured !== true) {
      failures.push("AI runtime persistent quota is not configured.");
    } else if (!aiHealth.inferenceConfigured) {
      const token = await page.evaluate(() => window.__edunexusSmokeGetToken());
      const aiResponse = await page.request.post(aiBase + "/chat", {
        timeout: 20000,
        headers: { authorization: "Bearer " + token, origin: "https://akvisomr-eng.github.io" },
        data: { message: "Bantu saya membuat rencana belajar komunikasi yang terukur.", locale: "Indonesia", mode: "learn" },
      });
      const aiData = await aiResponse.json().catch(() => ({}));
      console.log("AI_RUNTIME_QUOTA_CHECK=" + JSON.stringify({ status: aiResponse.status(), mode: aiData.mode, error: aiData.error }));
      if (aiResponse.status() !== 200 || aiData.mode !== "curated_retrieval_only_v1") {
        failures.push("AI runtime quota/RPC integration failed: HTTP " + aiResponse.status() + " / " + (aiData.error || aiData.mode || "unknown"));
      }
    }
  }
  if (failures.length) throw new Error(failures.join("\\n"));
  console.log("PASS: Neon Auth signup/signin, real JWT, profile provisioning, identity RPC, persistent quota RPC, catalog, full practice finalization, candidate evidence and own-session RLS.");
} catch (error) {
  console.error("BROWSER_SMOKE_FAILURE=" + (error?.stack || error));
  if (diagnostics.length) console.error("BROWSER_DIAGNOSTICS=\n" + diagnostics.join("\n"));
  process.exitCode = 1;
} finally {
  await context.close();
  await browser.close();
}
