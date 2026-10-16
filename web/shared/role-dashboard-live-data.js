import { createAuthClient } from "https://esm.sh/@neondatabase/auth@0.5.0-beta";

const AUTH_URL = "https://ep-curly-bread-azog8hfw.neonauth.c-3.ap-southeast-1.aws.neon.tech/neondb/auth";
const DATA_API_URL = "https://ep-curly-bread-azog8hfw.apirest.c-3.ap-southeast-1.aws.neon.tech/neondb/rest/v1";
const auth = createAuthClient(AUTH_URL);
const role = document.body.dataset.roleDashboard;
const roleLabels = { student: "Siswa", mentor: "Mentor", parent: "Orang tua" };
const $ = (tag, className, text) => {
  const node = document.createElement(tag);
  if (className) node.className = className;
  if (text !== undefined) node.textContent = text;
  return node;
};

function createPanel() {
  const panel = $("section", "live-data-panel");
  panel.id = "liveAccountData";
  panel.setAttribute("aria-live", "polite");
  const head = $("div", "live-data-head");
  const copy = $("div");
  copy.append($("div", "live-data-eyebrow", "DATA AKUN · NEON AUTH"));
  copy.append($("h2", "", "Ringkasan akun terhubung"));
  copy.append($("p", "live-data-muted", "Bagian ini menampilkan data yang diambil saat sesi terautentikasi tersedia. Hak akses tetap ditentukan oleh database."));
  head.append(copy);
  panel.append(head);
  const status = $("p", "live-data-status", "Memeriksa sesi akun…");
  status.id = "liveAccountStatus";
  panel.append(status);
  const body = $("div", "live-data-body");
  body.id = "liveAccountBody";
  panel.append(body);
  const main = document.querySelector("main.main");
  const topbar = main?.querySelector(".topbar");
  if (topbar && main) topbar.insertAdjacentElement("afterend", panel);
  else document.body.prepend(panel);
  return { panel, status, body };
}

const ui = createPanel();

function setStatus(message, kind = "") {
  ui.status.textContent = message;
  ui.status.className = "live-data-status" + (kind ? " " + kind : "");
}

function addActionLink(host, label, href) {
  const link = $("a", "live-data-link", label);
  link.href = href;
  host.append(link);
}

function showSignIn(message) {
  setStatus(message, "is-muted");
  const actions = $("div", "live-data-actions");
  addActionLink(actions, "Masuk / buat akun di EDUNEXUS", "../app/");
  ui.body.replaceChildren(actions);
}

async function api(path, options = {}) {
  let sessionResult = await auth.getSession();
  if (sessionResult?.error) throw new Error("Sesi autentikasi tidak dapat dibaca.");
  let token = sessionResult?.data?.session?.token;
  if (typeof token !== "string" || token.split(".").length !== 3) throw new Error("Sesi tidak menyediakan token Data API yang valid.");
  const request = async jwt => fetch(DATA_API_URL + path, {
    ...options,
    signal: AbortSignal.timeout(15000),
    headers: {
      "Authorization": "Bearer " + jwt,
      "Content-Type": "application/json",
      ...(options.headers || {})
    }
  });
  let response = await request(token);
  if (response.status === 401) {
    sessionResult = await auth.getSession();
    token = sessionResult?.data?.session?.token;
    if (typeof token === "string" && token.split(".").length === 3) response = await request(token);
  }
  const raw = await response.text();
  let data = null;
  try { data = raw ? JSON.parse(raw) : null; } catch { data = raw; }
  if (!response.ok) throw new Error(data?.message || data?.details || "Permintaan data ditolak (HTTP " + response.status + ").");
  return data;
}

async function ensureIdentity() {
  const result = await api("/rpc/ensure_my_profile", { method: "POST", body: "{}" });
  const uid = typeof result === "string" ? result : Array.isArray(result) ? result[0] : result?.ensure_my_profile;
  const verifiedResult = await api("/rpc/current_user_id", { method: "POST", body: "{}" });
  const verified = typeof verifiedResult === "string" ? verifiedResult : Array.isArray(verifiedResult) ? verifiedResult[0] : verifiedResult?.current_user_id;
  if (!uid || String(uid) !== String(verified)) throw new Error("Identitas akun tidak konsisten; akses dihentikan.");
  return String(uid);
}

async function getProfile(uid) {
  const rows = await api("/profiles?select=id,display_name,role&id=eq." + encodeURIComponent(uid) + "&limit=1");
  if (!Array.isArray(rows) || !rows[0]) throw new Error("Profil EDUNEXUS belum tersedia untuk akun ini.");
  if (rows[0].role !== role) throw new Error("Akun ini tidak memiliki peran " + roleLabels[role] + ". Silakan gunakan portal sesuai peran akun.");
  return rows[0];
}

function metric(label, value, hint) {
  const card = $("article", "live-data-metric");
  card.append($("span", "live-data-metric-label", label));
  card.append($("strong", "", String(value)));
  card.append($("small", "", hint));
  return card;
}

function renderMetrics(items) {
  const grid = $("div", "live-data-metrics");
  items.forEach(item => grid.append(metric(item[0], item[1], item[2])));
  ui.body.replaceChildren(grid);
}

function listPanel(title, rows, emptyMessage, renderRow) {
  const section = $("section", "live-data-list");
  section.append($("h3", "", title));
  if (!rows.length) {
    section.append($("p", "live-data-muted", emptyMessage));
  } else {
    const list = $("ul");
    rows.forEach(row => {
      const item = $("li");
      renderRow(item, row);
      list.append(item);
    });
    section.append(list);
  }
  ui.body.append(section);
}

async function loadStudent(uid, profile) {
  const query = encodeURIComponent(uid);
  const [courses, enrollments, progress, lessons, evidence] = await Promise.all([
    api("/courses?select=id,name,category&order=name.asc&limit=200"),
    api("/course_enrollments?select=id,course_id,status&user_id=eq." + query + "&order=enrolled_at.desc&limit=200"),
    api("/lesson_progress?select=id,lesson_id,status,progress_percent,completed_at&user_id=eq." + query + "&limit=500"),
    api("/lessons?select=id&limit=1000"),
    api("/skill_evidence?select=id,user_id&user_id=eq." + query + "&limit=500")
  ]);
  const complete = progress.filter(row => row.status === "completed").length;
  const avg = progress.length ? Math.round(progress.reduce((sum, row) => sum + Number(row.progress_percent || 0), 0) / progress.length) : 0;
  renderMetrics([
    ["Kursus diikuti", enrollments.length, "Data pendaftaran akun"],
    ["Pelajaran selesai", complete, "Dari " + lessons.length + " pelajaran dalam katalog"],
    ["Progres rata-rata", avg + "%", "Berdasarkan progres tersimpan"],
    ["Bukti keterampilan", evidence.length, "Catatan bukti milik akun"]
  ]);
  const byId = new Map(courses.map(course => [course.id, course]));
  listPanel("Kursus akun ini", enrollments, "Belum ada pendaftaran kursus untuk akun ini.", (item, row) => {
    const course = byId.get(row.course_id);
    item.append($("strong", "", course?.name || "Kursus tersedia"));
    item.append($("span", "live-data-pill", row.status === "completed" ? "Selesai" : row.status === "paused" ? "Dijeda" : row.status === "dropped" ? "Dihentikan" : "Aktif"));
  });
  setStatus("Terhubung sebagai " + (profile.display_name || "siswa") + ". Data dibaca dari Neon Data API menggunakan sesi akun; tidak ada data contoh pada panel ini.", "is-ok");
}

async function loadMentor(uid, profile) {
  const query = encodeURIComponent(uid);
  const [relationships, reviews] = await Promise.all([
    api("/mentor_student_relationships?select=id,student_user_id,status,created_at&mentor_user_id=eq." + query + "&status=eq.active&order=created_at.desc&limit=500"),
    api("/mentor_reviews?select=id,mentor_id,observation_id&mentor_id=eq." + query + "&limit=500")
  ]);
  const students = [...new Set(relationships.map(row => row.student_user_id))];
  renderMetrics([
    ["Peserta aktif", students.length, "Relasi pendampingan aktif"],
    ["Catatan tinjauan", reviews.length, "Tinjauan yang tercatat oleh mentor"],
    ["Status sesi", "Terautentikasi", "Identitas diperiksa oleh backend"]
  ]);
  const profiles = students.length
    ? await api("/profiles?select=id,display_name,role&id=in.(" + students.map(encodeURIComponent).join(",") + ")&limit=500")
    : [];
  const byId = new Map(profiles.map(row => [row.id, row]));
  listPanel("Peserta dampingan", relationships, "Belum ada relasi pendampingan aktif pada akun ini.", (item, row) => {
    const student = byId.get(row.student_user_id);
    item.append($("strong", "", student?.display_name || "Peserta terhubung"));
    item.append($("span", "live-data-pill", "Aktif"));
  });
  setStatus("Terhubung sebagai " + (profile.display_name || "mentor") + ". Hanya relasi yang diizinkan oleh kebijakan database yang dimuat.", "is-ok");
}

async function loadParent(uid, profile) {
  const query = encodeURIComponent(uid);
  const relationships = await api("/guardian_student_relationships?select=id,student_user_id,status,created_at&guardian_user_id=eq." + query + "&status=eq.active&order=created_at.desc&limit=500");
  const students = [...new Set(relationships.map(row => row.student_user_id))];
  const [profiles, enrollments, progress] = students.length ? await Promise.all([
    api("/profiles?select=id,display_name,role&id=in.(" + students.map(encodeURIComponent).join(",") + ")&limit=500"),
    api("/course_enrollments?select=id,course_id,user_id,status&user_id=in.(" + students.map(encodeURIComponent).join(",") + ")&limit=1000"),
    api("/lesson_progress?select=id,user_id,status,progress_percent&user_id=in.(" + students.map(encodeURIComponent).join(",") + ")&limit=2000")
  ]) : [[], [], []];
  renderMetrics([
    ["Anak terhubung", students.length, "Relasi wali aktif yang terdaftar"],
    ["Pendaftaran kursus", enrollments.length, "Data peserta yang terhubung"],
    ["Pelajaran selesai", progress.filter(row => row.status === "completed").length, "Berdasarkan progres tersimpan"]
  ]);
  const byId = new Map(profiles.map(row => [row.id, row]));
  listPanel("Peserta yang terhubung", relationships, "Belum ada relasi wali-peserta aktif. Relasi harus diverifikasi melalui alur resmi institusi.", (item, row) => {
    const student = byId.get(row.student_user_id);
    item.append($("strong", "", student?.display_name || "Peserta terhubung"));
    const childCourses = enrollments.filter(enrollment => enrollment.user_id === row.student_user_id).length;
    const childComplete = progress.filter(p => p.user_id === row.student_user_id && p.status === "completed").length;
    item.append($("span", "live-data-pill", childCourses + " kursus · " + childComplete + " pelajaran selesai"));
  });
  setStatus("Terhubung sebagai " + (profile.display_name || "orang tua/wali") + ". Data anak hanya dimuat jika relasi wali aktif diakui oleh database.", "is-ok");
}

async function start() {
  if (!["student", "mentor", "parent"].includes(role)) {
    setStatus("Konfigurasi peran portal tidak valid.", "is-error");
    return;
  }
  try {
    const session = await auth.getSession();
    if (session?.error) throw new Error("Sesi akun tidak dapat dibaca.");
    if (!session?.data?.user || !session?.data?.session) {
      showSignIn("Belum masuk. Data akun tidak dimuat. Masuk melalui EDUNEXUS untuk melihat data terotorisasi.");
      return;
    }
    const uid = await ensureIdentity();
    const profile = await getProfile(uid);
    if (role === "student") await loadStudent(uid, profile);
    else if (role === "mentor") await loadMentor(uid, profile);
    else await loadParent(uid, profile);
  } catch (error) {
    ui.body.replaceChildren();
    setStatus(error?.message || "Data akun belum dapat dimuat.", "is-error");
    const actions = $("div", "live-data-actions");
    addActionLink(actions, "Buka ruang belajar EDUNEXUS", "../app/");
    ui.body.append(actions);
  }
}

const style = document.createElement("style");
style.textContent = `
.live-data-panel{background:#fff;border:1px solid #dce5f3;border-radius:16px;padding:20px;margin:0 0 20px;box-shadow:0 5px 22px #233a6108}
.live-data-head h2{font-size:20px;margin:6px 0}.live-data-eyebrow{font-size:10px;font-weight:800;letter-spacing:.13em;color:#4169e1}
.live-data-muted{font-size:12px;line-height:1.7;color:#758197;margin:7px 0}
.live-data-status{font-size:12px;line-height:1.7;padding:10px 12px;border-radius:9px;background:#f5f7fb;color:#536177}
.live-data-status.is-ok{background:#eef9f2;color:#176b41}.live-data-status.is-error{background:#fff1f0;color:#a42a22}.live-data-status.is-muted{background:#f5f7fb;color:#536177}
.live-data-metrics{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:10px;margin:14px 0}
.live-data-metric{border:1px solid #e7edf5;border-radius:11px;padding:13px;min-width:0;display:grid;gap:7px}
.live-data-metric-label{font-size:11px;color:#758197;font-weight:700}.live-data-metric strong{font-size:23px;letter-spacing:-.04em}.live-data-metric small{font-size:10px;color:#8792a5;line-height:1.5}
.live-data-list{margin-top:14px;border:1px solid #e7edf5;border-radius:11px;padding:14px}.live-data-list h3{margin:0 0 8px}.live-data-list ul{list-style:none;margin:0;padding:0;display:grid;gap:8px}.live-data-list li{display:flex;align-items:center;justify-content:space-between;gap:10px;padding:10px;border-radius:8px;background:#f8faff;font-size:12px}.live-data-pill{font-size:10px;color:#536db6;background:#eaf0ff;border-radius:999px;padding:5px 8px;white-space:nowrap}.live-data-actions{display:flex;gap:10px;flex-wrap:wrap;margin-top:12px}.live-data-link{display:inline-flex;padding:10px 13px;border-radius:9px;background:#4169e1;color:white;font-size:12px;font-weight:800;text-decoration:none}
@media(max-width:760px){.live-data-metrics{grid-template-columns:repeat(2,minmax(0,1fr))}.live-data-panel{padding:14px}.live-data-list li{align-items:flex-start;flex-direction:column}}
`;
document.head.append(style);
start();
