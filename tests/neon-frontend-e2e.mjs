import { chromium } from "playwright";

const base = process.env.FRONTEND_BASE_URL || "http://127.0.0.1:4173/web/neon-preview.html";
const email = `edunexus-ui-${Date.now()}-${Math.random().toString(16).slice(2)}@example.com`;
const password = `N3on-UI-${Date.now()}!a`;
const browser = await chromium.launch({ headless: true });
const context = await browser.newContext();
const page = await context.newPage();
const diagnostics = [];
page.on("pageerror", error => diagnostics.push("PAGEERROR: " + error.message));
page.on("console", msg => { if (msg.type() === "error") diagnostics.push("CONSOLE: " + msg.text()); });
page.on("requestfailed", request => diagnostics.push("REQUEST FAILED: " + request.method() + " " + request.url() + " — " + (request.failure()?.errorText || "unknown")));

try {
  await page.goto(base, { waitUntil: "domcontentloaded", timeout: 60000 });
  await page.locator("#email").fill(email);
  await page.locator("#password").fill(password);
  await page.locator("#signupBtn").click();
  await page.waitForFunction(() => {
    const text = document.querySelector("#authStatus")?.textContent || "";
    return text.includes("Akun berhasil dibuat") || text.includes("sudah terdaftar") || text.includes("Email") && text.includes("gagal");
  }, null, { timeout: 30000 });
  const signupStatus = (await page.locator("#authStatus").innerText()).trim();
  console.log("FRONTEND_SIGNUP_STATUS=" + signupStatus);
  if (!signupStatus.includes("Akun berhasil dibuat")) throw new Error("Frontend sign-up failed: " + signupStatus);

  await page.locator("#authForm button[type=submit]").click();
  await page.waitForFunction(() => {
    const app = document.querySelector("#app");
    const health = document.querySelector("#health")?.textContent;
    const error = document.querySelector("#scenarios")?.textContent || "";
    return app && getComputedStyle(app).display !== "none" &&
      (health === "OK" || error.includes("GAGAL") || error.includes("HTTP "));
  }, null, { timeout: 60000 });
  await page.locator("#scenarios button[data-scenario]").first().waitFor({ state: "visible", timeout: 30000 });
  const scenarioTitle = await page.locator("#scenarios .item h3").first().innerText();
  console.log("FRONTEND_CATALOG_SCENARIO=" + scenarioTitle);
  await page.locator("#scenarios button[data-scenario]").first().click();

  await page.locator("#practice").waitFor({ state: "visible", timeout: 15000 });
  const fields = page.locator("#practiceForm textarea[data-key]");
  const fieldCount = await fields.count();
  if (fieldCount < 1) throw new Error("Practice scenario rendered no response fields.");
  for (let i = 0; i < fieldCount; i++) {
    await fields.nth(i).fill("Jawaban uji otomatis dengan penjelasan yang cukup rinci untuk menunjukkan proses berpikir, contoh konkret, dan langkah tindak lanjut yang relevan.");
  }

  const validity = await page.locator("#practiceForm").evaluate(form => ({
    valid: form.checkValidity(),
    fields: [...form.querySelectorAll("textarea[data-key]")].map(field => ({key: field.dataset.key, length: field.value.length, valid: field.checkValidity()}))
  }));
  console.log("FRONTEND_FORM_VALIDITY=" + JSON.stringify(validity));
  if (!validity.valid) throw new Error("Practice form invalid before submit: " + JSON.stringify(validity));
  await page.locator("#submitPractice").click();
  await page.waitForFunction(() => {
    const status = document.querySelector("#practiceStatus")?.textContent || "";
    return status.includes("Mengirim jawaban") || status.includes("berhasil diselesaikan") ||
      status.includes("gagal") || status.includes("HTTP ") || document.querySelector("#result")?.style.display === "block";
  }, null, { timeout: 15000 });
  await page.waitForFunction(() => {
    const result = document.querySelector("#result");
    const status = document.querySelector("#practiceStatus");
    return (result && getComputedStyle(result).display !== "none") || status?.classList.contains("error");
  }, null, { timeout: 70000 });
  if (await page.locator("#practiceStatus").evaluate(el => el.classList.contains("error"))) {
    throw new Error("Practice submission failed: " + (await page.locator("#practiceStatus").innerText()));
  }
  await page.locator("#result").waitFor({ state: "visible", timeout: 15000 });
  await page.waitForFunction(() => document.querySelector("#resultScore")?.textContent?.includes("/100"), null, { timeout: 15000 });
  const score = (await page.locator("#resultScore").innerText()).trim();
  const resultStatus = (await page.locator("#resultStatus").innerText()).trim();
  const evidenceCount = await page.locator("#evidence .item").count();
  const practiceStatus = (await page.locator("#practiceStatus").innerText()).trim();
  console.log("FRONTEND_PRACTICE_RESULT=" + JSON.stringify({ score, resultStatus, evidenceCount, practiceStatus }));
  if (!/\d+(\.\d+)?\/100/.test(score)) throw new Error("Practice score is not displayed: " + score);
  if (evidenceCount < 1) throw new Error("Practice completed without a candidate evidence item.");
  if (!practiceStatus.includes("berhasil diselesaikan")) throw new Error("Practice completion status missing: " + practiceStatus);

  await page.locator("#history .item").first().waitFor({ state: "visible", timeout: 15000 });
  const history = (await page.locator("#history").innerText()).trim();
  if (!history.includes("Selesai")) throw new Error("Completed practice was not visible in history: " + history);
  if (diagnostics.length) console.log("FRONTEND_BROWSER_DIAGNOSTICS=" + diagnostics.join("\n"));
  console.log("PASS: Neon frontend signup/login, profile bootstrap, catalog, practice submission, trusted score, candidate evidence and history.");
} catch (error) {
  console.error("FRONTEND_E2E_FAILURE=" + (error?.stack || error));
  if (diagnostics.length) console.error("FRONTEND_BROWSER_DIAGNOSTICS=\n" + diagnostics.join("\n"));
  console.error("AUTH_STATUS=" + await page.locator("#authStatus").innerText().catch(() => "(unavailable)"));
  console.error("HEALTH_STATUS=" + await page.locator("#health").innerText().catch(() => "(unavailable)"));
  console.error("PRACTICE_STATUS=" + await page.locator("#practiceStatus").innerText().catch(() => "(unavailable)"));
  process.exitCode = 1;
} finally {
  await context.close();
  await browser.close();
}
