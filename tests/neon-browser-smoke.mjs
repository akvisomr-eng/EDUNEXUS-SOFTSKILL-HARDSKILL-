import { chromium } from "playwright";

const base = process.env.SMOKE_BASE_URL || "http://127.0.0.1:4173/neon-cutover-smoke.html";
const email = `edunexus-smoke-${Date.now()}-${Math.random().toString(16).slice(2)}@example.com`;
const password = `N3on-Smoke-${Date.now()}!a`;
const browser = await chromium.launch({ headless: true });
const context = await browser.newContext();
const page = await context.newPage();
const failures = [];
page.on("pageerror", error => failures.push(error.message));

try {
  await page.goto(base, { waitUntil: "networkidle", timeout: 60000 });
  await page.locator("#email").fill(email);
  await page.locator("#password").fill(password);
  await page.locator("#name").fill("EDUNEXUS automated smoke test");
  await page.locator("#signup").click();
  await page.locator("#authStatus").filter({ hasText: "Pendaftaran berhasil" }).waitFor({ timeout: 30000 });

  await page.locator("#signin").click();
  await page.locator("#authStatus").filter({ hasText: "Login berhasil" }).waitFor({ timeout: 30000 });
  await page.locator("#run").click();
  await page.locator("#checks .check").nth(3).waitFor({ timeout: 45000 });

  const checks = await page.locator("#checks .check").allTextContents();
  console.log("SMOKE_CHECKS=" + JSON.stringify(checks));
  const required = [
    "JWT nyata dari Neon Auth",
    "RPC current_user_id",
    "Baca katalog praktik",
    "RLS sesi praktik milik pengguna",
  ];
  for (const label of required) {
    const row = checks.find(value => value.includes(label));
    if (!row || !row.startsWith("LULUS")) failures.push(`Check failed: ${label}: ${row || "missing"}`);
  }
  if (failures.length) throw new Error(failures.join("\n"));
  console.log("PASS: Neon Auth signup/signin, real JWT, identity RPC, catalog read and own-session RLS diagnostic.");
} finally {
  await context.close();
  await browser.close();
}
