import { chromium } from "playwright";

const base = process.env.SMOKE_BASE_URL || "http://127.0.0.1:4173/tests/fixtures/neon-cutover-smoke.html";
const suffix = Date.now() + "-" + Math.random().toString(16).slice(2);
const password = `N3on-Isolation-${Date.now()}!a`;
const browser = await chromium.launch({ headless: true });
const failures = [];
const diagnostics = [];
const contexts = [];

function listen(page, label) {
  page.on("pageerror", error => diagnostics.push(label + " PAGEERROR: " + error.message));
  page.on("console", msg => { if (msg.type() === "error") diagnostics.push(label + " CONSOLE: " + msg.text()); });
  page.on("requestfailed", request => diagnostics.push(label + " REQUEST FAILED: " + request.method() + " " + request.url() + " — " + (request.failure()?.errorText || "unknown")));
}

async function createAccountAndSignIn(page, email, name) {
  await page.goto(base, { waitUntil: "domcontentloaded", timeout: 60000 });
  await page.locator("#email").fill(email);
  await page.locator("#password").fill(password);
  await page.locator("#name").fill(name);
  await page.locator("#signup").click();
  await page.waitForFunction(() => {
    const text = document.querySelector("#authStatus")?.textContent || "";
    return text.includes("Pendaftaran berhasil") || text.includes("sudah terdaftar") || text.includes("gagal");
  }, null, { timeout: 30000 });
  const signupStatus = (await page.locator("#authStatus").innerText()).trim();
  if (!signupStatus.includes("Pendaftaran berhasil")) throw new Error("Signup failed for " + email + ": " + signupStatus);
  await page.locator("#signin").click();
  await page.waitForFunction(() => (document.querySelector("#authStatus")?.textContent || "").includes("Login berhasil"), null, { timeout: 30000 });
}

try {
  // Account B owns the session whose ID must never be readable by account A.
  const contextB = await browser.newContext();
  contexts.push(contextB);
  const pageB = await contextB.newPage();
  listen(pageB, "ACCOUNT_B");
  const emailB = `edunexus-rls-b-${suffix}@example.com`;
  await createAccountAndSignIn(pageB, emailB, "EDUNEXUS Isolation Account B");
  await pageB.locator("#run").click();
  await pageB.waitForFunction(() => {
    const checks = [...document.querySelectorAll("#checks .check")];
    return checks.some(el => el.textContent.includes("Alur praktik dan finalisasi tepercaya")) &&\n      checks.some(el => el.textContent.includes("RLS sesi praktik milik pengguna"));
  }, null, { timeout: 60000 });
  const checksB = await pageB.locator("#checks .check").allTextContents();
  const lifecycleB = checksB.find(t => t.includes("Alur praktik dan finalisasi tepercaya")) || "";
  const ownRlsB = checksB.find(t => t.includes("RLS sesi praktik milik pengguna")) || "";
  if (!lifecycleB.startsWith("LULUS")) throw new Error("Account B could not create/finalize its own practice session: " + lifecycleB);
  if (!ownRlsB.startsWith("LULUS")) throw new Error("Account B own-session RLS precondition failed: " + ownRlsB);
  const sessionIdB = (await pageB.locator("#createdSessionId").innerText()).trim();
  if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(sessionIdB)) {
    throw new Error("Account B session UUID not available: " + sessionIdB);
  }
  console.log("ACCOUNT_B_SESSION_CREATED=" + sessionIdB);

  // A separate browser context ensures account A has its own independent auth state.
  const contextA = await browser.newContext();
  contexts.push(contextA);
  const pageA = await contextA.newPage();
  listen(pageA, "ACCOUNT_A");
  const emailA = `edunexus-rls-a-${suffix}@example.com`;
  await createAccountAndSignIn(pageA, emailA, "EDUNEXUS Isolation Account A");
  await pageA.locator("#otherSession").fill(sessionIdB);
  await pageA.locator("#checkOther").click();
  await pageA.waitForFunction(() => {
    const text = document.querySelector("#isolation")?.textContent || "";
    return text.includes("LULUS:") || text.includes("GAGAL/PERLU DITINJAU") || text.includes("Format UUID");
  }, null, { timeout: 30000 });
  const result = (await pageA.locator("#isolation").innerText()).trim();
  console.log("CROSS_ACCOUNT_ISOLATION_RESULT=" + result);
  if (!result.startsWith("LULUS: API tidak mengembalikan sesi milik akun lain.")) {
    throw new Error("Cross-account isolation failed: " + result);
  }
  if (diagnostics.length) console.log("BROWSER_DIAGNOSTICS=" + diagnostics.join("\n"));
  console.log("PASS: two independent Neon Auth accounts; account B created and finalized a session; account A's JWT received zero rows for B's session ID.");
} catch (error) {
  console.error("RLS_ISOLATION_FAILURE=" + (error?.stack || error));
  if (diagnostics.length) console.error("BROWSER_DIAGNOSTICS=\n" + diagnostics.join("\n"));
  process.exitCode = 1;
} finally {
  for (const context of contexts) await context.close();
  await browser.close();
}
