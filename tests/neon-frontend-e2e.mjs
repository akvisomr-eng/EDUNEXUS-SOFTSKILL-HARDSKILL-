import { chromium } from "playwright";

const base = process.env.FRONTEND_BASE_URL || "http://127.0.0.1:4173/web/neon-preview.html";
const email = `edunexus-ui-${Date.now()}-${Math.random().toString(16).slice(2)}@example.com`;
const password = `N3on-UI-${Date.now()}!a`;
const browser = await chromium.launch({ headless: true });
const context = await browser.newContext();
const page = await context.newPage();
const diagnostics = [];
let observedJwt = null;
page.on("request", request => {
  if (request.url().includes("apirest.c-3.ap-southeast-1.aws.neon.tech") && !observedJwt) {
    const authorization = request.headers().authorization || "";
    if (authorization.startsWith("Bearer ") && authorization.split(".").length === 3) observedJwt = authorization.slice(7);
  }
});
page.on("pageerror", error => diagnostics.push("PAGEERROR: " + error.message));
page.on("console", msg => { if (msg.type() === "error") diagnostics.push("CONSOLE: " + msg.text()); });
page.on("requestfailed", request => diagnostics.push("REQUEST FAILED: " + request.method() + " " + request.url() + " — " + (request.failure()?.errorText || "unknown")));

try {
  await page.goto(base, { waitUntil: "domcontentloaded", timeout: 60000 });

  // Verify the forgot-password UI is reachable without sending an email.
  await page.locator("#forgotPasswordBtn").click();
  await page.locator("#recoveryRequestForm").waitFor({ state: "visible", timeout: 10000 });
  if (!(await page.locator("#recoveryTitle").innerText()).includes("Lupa Password")) {
    throw new Error("Forgot-password panel did not open.");
  }
  // A unique address with no account should get the generic response and send no email.
  await page.locator("#recoveryEmail").fill(`edunexus-no-account-${Date.now()}@example.com`);
  await page.locator("#requestResetBtn").click();
  await page.waitForFunction(() => {
    const text = document.querySelector("#recoveryRequestStatus")?.textContent || "";
    return text.includes("Jika email tersebut terdaftar") || text.includes("Permintaan belum dapat diproses");
  }, null, { timeout: 30000 });
  const requestStatus = (await page.locator("#recoveryRequestStatus").innerText()).trim();
  if (!requestStatus.includes("Jika email tersebut terdaftar")) {
    throw new Error("Password reset request did not return the expected generic success response: " + requestStatus);
  }
  console.log("PASSWORD_RESET_REQUEST=PASS; generic response for nonexistent account");
  await page.locator("#recoveryBackBtn").click();
  await page.locator("#authForm").waitFor({ state: "visible", timeout: 10000 });

  // A deliberately invalid token must be rejected by Neon Auth on the disposable branch.
  await page.goto(base + "?token=invalid-reset-token-for-e2e", { waitUntil: "domcontentloaded", timeout: 60000 });
  await page.locator("#recoveryResetForm").waitFor({ state: "visible", timeout: 10000 });
  await page.locator("#newPassword").fill("New-EDUNEXUS-Test-Password-123!");
  await page.locator("#confirmPassword").fill("New-EDUNEXUS-Test-Password-123!");
  await page.locator("#resetPasswordBtn").click();
  await page.waitForFunction(() => {
    const el = document.querySelector("#recoveryResetStatus");
    return Boolean(el?.textContent?.trim()) && el.classList.contains("error");
  }, null, { timeout: 30000 });
  const invalidTokenMessage = (await page.locator("#recoveryResetStatus").innerText()).trim();
  if (!invalidTokenMessage) throw new Error("Invalid reset token did not produce a visible error.");
  console.log("PASSWORD_RECOVERY_UI=PASS; invalid reset token rejected: " + invalidTokenMessage);

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
  // The app presents each menu as an independent module view; open practice before asserting its controls.
  await page.locator('nav.sidebar-nav a[href="#scenarios"]').click();
  await page.locator("#scenarios button[data-scenario]").first().waitFor({ state: "visible", timeout: 30000 });
  const scenarioTitle = await page.locator("#scenarios .item h3").first().innerText();
  console.log("FRONTEND_CATALOG_SCENARIO=" + scenarioTitle);

  // Navigate to the goal module because module views are intentionally isolated.
  await page.locator('nav.sidebar-nav a[href="#goalForm"]').click();
  const goalTitle = "E2E goal " + Date.now();
  await page.locator("#goalTitle").fill(goalTitle);
  await page.locator("#goalDescription").fill("Tujuan uji untuk memverifikasi alur simpan dan penyelesaian tujuan pembelajar.");
  await page.locator("#saveGoalBtn").click();
  await page.waitForFunction((title) => document.querySelector("#goalsList")?.textContent.includes(title), goalTitle, { timeout: 30000 });
  const goalCard = page.locator("#goalsList .item").filter({ hasText: goalTitle });
  await goalCard.locator("button[data-complete-goal]").click();
  await page.waitForFunction((title) => {
    const item = [...document.querySelectorAll("#goalsList .item")].find((el) => el.textContent.includes(title));
    return Boolean(item?.textContent.includes("Selesai")) && !item.querySelector("[data-complete-goal]");
  }, goalTitle, { timeout: 30000 });
  await page.waitForFunction(() => !document.querySelector("#learningStatus")?.textContent.includes("Memuat katalog"), null, { timeout: 30000 });
  console.log("FRONTEND_GOAL_WORKFLOW=PASS; goal created and completed; learning catalog loaded");

  // Switch to the course module before enrollment and lesson assertions.
  await page.locator('nav.sidebar-nav a[href="#coursesList"]').click();
  await page.waitForFunction(() => document.querySelectorAll("#coursesList .course-card").length >= 2, null, { timeout: 30000 });
  const firstCourse = page.locator("#coursesList .item").first();
  await firstCourse.locator("button[data-enroll-course]").click();
  await page.waitForFunction(() => document.querySelector("#learningStatus")?.textContent.includes("Pendaftaran kursus tersimpan"), null, { timeout: 30000 });
  await page.locator("#coursesList [data-open-lesson]").first().click();
  await page.locator("#lessonReader").waitFor({ state: "visible", timeout: 15000 });
  const lessonTitle = (await page.locator("#lessonTitle").innerText()).trim();
  const lessonContent = (await page.locator("#lessonContent").innerText()).trim();
  if (!lessonTitle || !lessonContent) throw new Error("Lesson reader did not display seeded lesson content.");
  await page.locator("#completeLessonBtn").click();
  await page.waitForFunction(() => document.querySelector("#lessonProgressStatus")?.textContent.includes("Progres tersimpan: pelajaran selesai"), null, { timeout: 30000 });
  console.log("FRONTEND_LEARNING_WORKFLOW=PASS; enrolled, opened lesson, and persisted completion for " + lessonTitle);

  if (!observedJwt) throw new Error("Could not capture authenticated test-branch JWT for AI runtime E2E.");
  const aiResponse = await fetch("https://br-quiet-frost-azemctlk-edunexusai.compute.c-3.ap-southeast-1.aws.neon.tech/chat", {
    method: "POST",
    headers: { "Authorization": "Bearer " + observedJwt, "Content-Type": "application/json", "Origin": "https://akvisomr-eng.github.io" },
    body: JSON.stringify({ message: "Jelaskan literasi AI yang bertanggung jawab dan cara memverifikasi hasil AI." }),
    signal: AbortSignal.timeout(20000)
  });
  const aiData = await aiResponse.json().catch(() => ({}));
  if (!aiResponse.ok) throw new Error("Authenticated EDUNEXUS knowledge retrieval failed: HTTP " + aiResponse.status + " " + JSON.stringify(aiData));
  if (!aiData.answer || !Array.isArray(aiData.agents) || !Array.isArray(aiData.sources) || !aiData.mode.includes("retrieval")) {
    throw new Error("AI runtime did not return grounded retrieval structure: " + JSON.stringify(aiData));
  }
  console.log("AI_KNOWLEDGE_RETRIEVAL=PASS; mode=" + aiData.mode + "; sources=" + aiData.sources.length + "; specialists=" + aiData.agents.length);

  // Course and lesson interactions may have switched module views; reopen practice before starting a scenario.
  await page.locator('nav.sidebar-nav a[href="#scenarios"]').click();
  await page.locator("#scenarios button[data-scenario]").first().click();

  await page.locator("#practice").waitFor({ state: "visible", timeout: 15000 });
  await page.waitForFunction(() => {
    const status = document.querySelector("#practiceStatus");
    return status?.textContent?.includes("Sesi siap") || status?.classList.contains("error");
  }, null, { timeout: 45000 });
  if (await page.locator("#practiceStatus").evaluate(el => el.classList.contains("error"))) {
    throw new Error("Practice session creation failed: " + (await page.locator("#practiceStatus").innerText()));
  }
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
  const buttonInfo = await page.locator("#submitPractice").evaluate(button => ({
    type: button.type,
    disabled: button.disabled,
    formId: button.form?.id || null,
    parentForm: button.closest("form")?.id || null,
    formAttemptId: button.closest("form")?.dataset.attemptId || null
  }));
  console.log("FRONTEND_SUBMIT_BUTTON=" + JSON.stringify(buttonInfo));
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
