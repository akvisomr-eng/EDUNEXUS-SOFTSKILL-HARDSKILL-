# EDUNEXUS Master Blueprint v3.0
**Human Intelligence & Future Skills OS**  
Tanggal: 15 Oktober 2026  
Status: arah produk dan spesifikasi bertahap — bukan pernyataan bahwa seluruh fitur telah diimplementasikan.

## 1. Visi dan prinsip
EDUNEXUS membantu setiap pembelajar mengenali kekuatan, membangun kompetensi melalui praktik, menerima umpan balik yang dapat ditindaklanjuti, mengumpulkan bukti nyata, dan menghubungkan penguasaan dengan tujuan hidup serta pekerjaan. Produk harus berguna untuk individu, sekolah, perguruan tinggi, pelatihan vokasi, organisasi, dan pembelajaran sepanjang hayat.

Prinsip desain:
- **Evidence before claims:** setiap klaim kompetensi harus ditautkan ke hasil belajar, artefak, rubrik, atau verifikasi yang jelas.
- **Human agency:** AI memberi dukungan dan pilihan; pembelajar tetap mengambil keputusan.
- **Source-grounded knowledge:** materi memiliki sumber, tanggal akses/publikasi bila tersedia, lisensi, tingkat keyakinan, dan status tinjauan.
- **Accessible by default:** mobile-first, bahasa Indonesia sebagai bahasa utama, dukungan bahasa lain, navigasi keyboard, kontras dan teks yang jelas.
- **Privacy by design:** minimisasi data, kontrol akses, pemisahan peran, transparansi penggunaan AI, serta retensi data yang terukur.
- **Low-cost first:** pertahankan GitHub Pages + Neon Auth/Data API yang sudah ada; jangan pindah provider tanpa alasan teknis dan biaya yang terukur.
- **No false neuroscience:** jangan mengklasifikasikan orang sebagai “otak kiri” atau “otak kanan”. Latih keterampilan kognitif yang dapat diamati melalui tugas, misalnya penalaran analitis, kreativitas, pemecahan masalah, strategi memori, perhatian, metakognisi, pengambilan keputusan, dan berpikir sistem.

## 2. Landasan kurikulum
Gunakan kerangka internasional sebagai rujukan yang diadaptasi, bukan disalin mentah:
- OECD Learning Compass 2030: agency pembelajar, well-being, pengetahuan, keterampilan, sikap dan nilai.
- EU LifeComp: kompetensi personal, sosial, dan belajar-untuk-belajar.
- EU DigComp 3.0: kompetensi digital dan integrasi kompetensi AI.
- UNESCO ICT Competency Framework for Teachers: pengembangan kapasitas digital pendidik.
- UNESCO AI competency resources: pola pikir berpusat pada manusia, etika AI, penggunaan/penerapan AI, dan desain sistem AI.
- WEF Future of Jobs: sinyal perubahan keterampilan kerja; perlu ditinjau ulang secara berkala.
- NACE Career Readiness: komunikasi, berpikir kritis, kerja tim, profesionalisme, kepemimpinan, teknologi, dan pengembangan karier.

Sumber awal:
- OECD Learning Compass 2030: https://www.oecd.org/en/data/tools/oecd-learning-compass-2030.html
- OECD Future of Education and Skills 2030/2040: https://www.oecd.org/en/about/projects/future-of-education-and-skills-2030.html
- DigComp 3.0: https://joint-research-centre.ec.europa.eu/scientific-activities/key-competences-lifelong-learning/digital-competence-framework-digcomp/digcomp-30_en
- UNESCO ICT CFT: https://www.unesco.org/en/digital-competencies-skills/ict-cft
- UNESCO SDG4 Knowledge Hub — DigComp 2.2: https://www.unesco.org/sdg4education2030/en/knowledge-hub/digital-competence-framework-citizens-22

Catat setiap sumber di Knowledge Hub dengan: judul, penerbit/organisasi, URL kanonis, tanggal terbit jika diketahui, tanggal diperiksa, bahasa, jenis lisensi/ketentuan penggunaan, topik, kompetensi terkait, ringkasan orisinal, dan status verifikasi. Jangan menganggap seluruh konten internet bebas disalin atau dilisensikan ulang.

## 3. Delapan sekolah pembelajaran
1. **Intelligence, Cognition & Learning Science** — penalaran, strategi belajar, metakognisi, perhatian, kreativitas, dan pemecahan masalah.
2. **Human & Social Excellence** — komunikasi, empati, kolaborasi, kepemimpinan, negosiasi, ketahanan, dan regulasi diri.
3. **Digital, AI & Computational Intelligence** — literasi digital/data, AI, keamanan siber, berpikir komputasional, dan otomasi.
4. **Creativity, Design & Innovation** — desain, ideasi, prototipe, riset pengguna, eksperimen, dan evaluasi solusi.
5. **Business, Entrepreneurship & Financial Capability** — kewirausahaan, operasi, pemasaran, keuangan pribadi, analisis bisnis, dan etika.
6. **Technical & Professional Mastery** — jalur hard skill yang spesifik profesi, dengan prasyarat, praktik, dan rubrik.
7. **Career, Portfolio & Employability** — kesiapan kerja, CV, wawancara, komunikasi profesional, portofolio, dan transisi karier.
8. **Future Society, Ethics & Global Citizenship** — etika, keberlanjutan, inklusi, kewargaan digital, dan pemecahan masalah masyarakat.

Setiap kursus harus memiliki hasil belajar terukur, level, prasyarat, modul, pelajaran, aktivitas praktik, asesmen, rubrik, bukti yang diharapkan, sumber, estimasi durasi, aksesibilitas, dan tanggal review.

## 4. Pilar produk
### A. Cognitive Fitness Lab
Latihan singkat dan berulang untuk penalaran analitis, kreativitas divergen, pemecahan masalah, memori/strategi belajar, perhatian, dan refleksi metakognitif. Hasil awal adalah umpan balik formatif berbasis tugas, bukan diagnosis psikologis atau tes IQ. Ukur perkembangan lintas waktu hanya setelah metode dan rubrik divalidasi.

### B. Adaptive Learning Navigator
Menyusun jalur belajar berdasarkan tujuan yang dipilih, prasyarat, hasil asesmen, minat, aksesibilitas, waktu yang tersedia, dan bukti kemajuan. Pembelajar dapat mengubah atau menolak rekomendasi.

### C. AI Mentor Council
Peran yang terpisah secara logis: Learning Mentor, Soft Skills Coach, Technical Tutor, Evidence/Rubric Evaluator, Knowledge Researcher, dan Career Advisor. Setiap agen harus menyatakan batas kemampuan, menggunakan sumber yang relevan, tidak mengarang sitasi, serta berbagi konteks hanya sesuai izin.

### D. Real-World Simulation Arena
Role-play dan kasus dunia nyata untuk layanan pelanggan, kerja tim, kepemimpinan, presentasi, pemecahan masalah teknis, keputusan bisnis, keamanan digital, dan situasi profesional. Gunakan rubrik transparan dan kesempatan mencoba ulang.

### E. Evidence-Based Skill Passport
Portofolio artefak dan bukti dengan provenance, waktu, rubrik, umpan balik, serta status verifikasi yang jelas: **evaluasi otomatis**, **ditinjau mentor**, atau **diverifikasi institusi**. Jangan menyamakan ketiganya.

### F. Skill Graph & Career Navigator
Graf hubungan antara kompetensi, prasyarat, kursus, tugas, bukti, peran pekerjaan, dan jalur pengembangan. Rekomendasi karier harus dijelaskan dan tidak deterministik.

### G. Global Knowledge & Curriculum Intelligence
Knowledge Hub dengan pencarian sumber, kurasi, provenance, deduplikasi, review kualitas, pemetaan ke kompetensi, versi kurikulum, dan pembaruan berkala. Integrasi konten harus menghormati hak cipta, lisensi, privasi, dan ketentuan sumber.

## 5. Struktur navigasi target
Menu berikut merupakan target evolusi. Implementasi dilakukan per tahap; menu yang belum aktif harus diberi status “segera hadir” atau tidak ditampilkan sebagai fitur yang sudah berjalan.
1. My EDUNEXUS
2. Intelligence & Skills Profile
3. Learning Universe
4. Cognitive Fitness Lab
5. Simulation Arena
6. AI Mentor Council
7. Career & Opportunity Navigator
8. Portfolio & Skill Passport
9. Global Knowledge Hub
10. Growth Analytics
11. Community & Collaboration
12. Institution & Enterprise Studio

Menu yang telah tersedia pada aplikasi saat blueprint ditulis: Ringkasan, Program & kursus, Praktik & simulasi, Tujuan pengembangan, Multi-agent AI, Pustaka pengetahuan, dan Riwayat praktik. Perubahan harus mempertahankan fungsi yang sudah ada dan menghindari duplikasi modul.

## 6. Arsitektur target
- **Experience layer:** learner, mentor, institution, enterprise, mobile-first web.
- **EDUNEXUS Intelligence Core:** learning path, skill graph, assessment/rubrics, simulation, evidence and mastery.
- **AI orchestration:** model-agnostic adapters, policy guardrails, tool permissions, cost/latency controls, traceable agent outputs.
- **Knowledge intelligence:** source registry, retrieval, chunk metadata, citation validation, review workflow, curriculum-to-skill mapping.
- **Learning data platform:** identity/profile, enrollments, lessons, goals, attempts, assessment results, evidence, reviews, credentials, audit events.
- **Trust & Safety:** least privilege, authorization/RLS checks, privacy, accessible UX, abuse controls, export/delete policies, monitoring.

Sumber kebenaran untuk deployment saat ini tetap repo GitHub dan backend Neon yang terkonfigurasi. Jangan menambahkan provider atau memigrasikan data tanpa perubahan arsitektur yang disetujui dan rencana rollback.

## 7. Alur inti pembelajar
Sign Up → Profile → Course → Enrollment → Lesson → Practice → Assessment → Evidence → Mentor Verification → Mastery → Skill Passport.

Setiap langkah harus memiliki status yang eksplisit, pesan kegagalan yang dapat ditindaklanjuti, dan uji penerimaan. Tidak boleh menandai mastery atau verifikasi mentor secara otomatis tanpa aturan yang benar-benar diimplementasikan.

## 8. Roadmap implementasi
### Fase 1 — Stabilitas dan learning flow
- Audit seluruh menu, auth/session, profil, katalog, enrollment, pelajaran, praktik, asesmen, bukti, tujuan, riwayat, dan Knowledge Hub.
- Validasi skema API, izin akses, keadaan kosong, kegagalan jaringan, dan tampilan mobile.
- Standarkan struktur kursus, pelajaran, hasil belajar, rubrik, dan sumber.
- Acceptance: seluruh modul yang ditampilkan berfungsi; tidak ada menu palsu; alur utama dapat diuji dari akun uji hingga bukti.

### Fase 2 — Cognitive Fitness + Skills Profile
- Tambahkan latihan berbasis tugas dan refleksi dengan rubrik yang dapat diperiksa.
- Simpan hasil hanya setelah skema dan izin backend tersedia; jangan menyatakan data tersimpan jika masih lokal.
- Acceptance: petunjuk, tugas, rubrik, feedback, batasan metode, dan status penyimpanan terlihat jelas.

### Fase 3 — AI Mentor Council + Simulation Arena
- Orkestrasi peran, retrieval bersumber, batas biaya, log aman, dan evaluasi kualitas.
- Simulation dengan skenario, kriteria, feedback, percobaan ulang, dan provenance.
- Acceptance: sumber dapat dibuka, feedback mengikuti rubrik, dan klaim agen dapat diaudit.

### Fase 4 — Passport + Portfolio + Career Navigator
- Kaitkan bukti dengan kompetensi; pisahkan penilaian otomatis, review mentor, dan verifikasi institusi.
- Acceptance: setiap pencapaian dapat dilacak ke bukti dan metode evaluasinya.

### Fase 5 — Institusi, perusahaan, dan skala global
- Role-based institution studio, pengelolaan cohort, agregasi analitik yang menjaga privasi, kurikulum bilingual, dan evaluasi dampak.
- Acceptance: uji akses lintas peran, aksesibilitas, ekspor data, serta keamanan sebelum pilot.

## 9. Metrik kualitas
- Learning gain pre/post dan transfer ke kasus baru.
- Penyelesaian pelajaran/praktik dan retensi pengguna.
- Kualitas rubrik, kegunaan umpan balik, dan keterlacakan sumber AI.
- Jumlah bukti portofolio yang valid dan ditinjau.
- Aksesibilitas dan perbedaan hasil antar kelompok, bila pengukuran etis dan sah dilakukan.
- Insiden keamanan/privasi, kegagalan akses kontrol, biaya AI per aktivitas, serta latensi.
- Hasil karier/pendidikan yang dilaporkan harus dibedakan dari hasil yang telah diverifikasi.

## 10. Definition of Done untuk setiap fitur
1. Kebutuhan dan perilaku fitur didokumentasikan.
2. Kode dan migrasi/skema (jika perlu) berada di repo.
3. Uji sintaks/lint/unit/integrasi yang relevan lulus.
4. Hak akses dan penanganan error diuji.
5. Tampilan mobile dan aksesibilitas dasar ditinjau.
6. CI/deployment diperiksa dari run nyata.
7. URL publik diuji bila perubahan memengaruhi situs.
8. Laporan menyebutkan bukti, batasan, dan pekerjaan tersisa — tanpa klaim tes perangkat atau produksi yang belum dilakukan.
