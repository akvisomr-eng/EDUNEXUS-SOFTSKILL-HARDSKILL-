# EDUNEXUS AI Mentor dan Human Tutor — Kerangka v1

**Tanggal:** 15 Oktober 2026  
**Tujuan:** membuat tutor AI yang mengajarkan keterampilan, memberi umpan balik, dan membantu menyusun bukti kompetensi; tutor manusia melakukan verifikasi performa dan keputusan akhir untuk asesmen berisiko tinggi.

## Peran multi-agen

1. **Learning Navigator:** mengidentifikasi tujuan, prasyarat, kemajuan, dan sesi berikutnya.
2. **Subject-Matter Mentor:** menjelaskan konsep dan memeriksa ketepatan materi.
3. **Pedagogy Coach:** menyederhanakan penjelasan, memberikan analogi, scaffolding, dan pertanyaan Socratic sesuai jenjang.
4. **Practice Designer:** membuat latihan dan skenario yang selaras dengan tujuan sesi.
5. **Formative Assessor:** memberi umpan balik berdasarkan rubrik dan mengidentifikasi kesenjangan kompetensi.
6. **Indonesia Context & Safety Reviewer:** mempertimbangkan konteks lokal dan menandai regulasi yang perlu dicek dari sumber resmi terbaru.
7. **Evidence & Portfolio Curator:** membantu mengorganisasi artefak, jawaban, revisi, dan catatan refleksi; tidak mengarang bukti.
8. **Human Tutor Coordinator:** menyiapkan ringkasan kebutuhan verifikasi, pertanyaan wawancara/presentasi, rubrik, dan catatan yang perlu diperiksa manusia.

Semua peran menggunakan basis pengetahuan kurikulum berversi dan retrieval sumber yang terkurasi. Sistem harus menunjukkan sumber saat tersedia, menyatakan ketidakpastian, dan meminta klarifikasi jika konteks kurang.

## Siklus pembelajaran

1. Diagnostik ringan/prasyarat.
2. Materi dan contoh kerja.
3. Latihan dengan umpan balik.
4. Praktik autentik atau produk.
5. Refleksi dan perbaikan.
6. Rekomendasi sesi berikutnya berdasarkan bukti yang benar-benar tersedia.
7. Jika dibutuhkan, penjadwalan atau rujukan ke tutor manusia.

## Rubrik formatif standar

Setiap domain dinilai dengan indikator dan contoh bukti, bukan kesan umum:
- **1 — Mulai berkembang:** memerlukan banyak panduan; kesalahan konsep utama belum diperbaiki.
- **2 — Berkembang:** sebagian benar; masih membutuhkan petunjuk pada langkah penting.
- **3 — Kompeten untuk tugas:** menyelesaikan tugas dengan akurat dan dapat menjelaskan alasan dalam kondisi yang ditentukan.
- **4 — Transfer/adaptasi:** menerapkan keterampilan pada variasi konteks, memeriksa keterbatasan, dan membantu memperbaiki proses.

Domain dapat meliputi ketepatan konsep, penerapan, penalaran/bukti, komunikasi, keselamatan/etika, dan refleksi sesuai kursus. Tidak semua domain harus digunakan pada semua kursus.

## Peran tutor manusia

Untuk presentasi, wawancara, demonstrasi kerja, dan asesmen yang menentukan kelulusan:
- manusia memverifikasi tugas dan konteks yang relevan;
- mengajukan pertanyaan tindak lanjut;
- memeriksa bukti asli/produk dan proses;
- mencatat rubrik, alasan keputusan, umpan balik, serta kesempatan perbaikan;
- membuat keputusan final, bukan sekadar menerima skor AI;
- menyediakan mekanisme peninjauan atau asesmen ulang.

## Privasi, keadilan, dan keselamatan

- Jangan menilai karakter atau potensi berdasarkan demografi/proksi sensitif.
- Minta persetujuan sebelum merekam audio/video atau membagikan hasil kepada tutor.
- Kumpulkan data minimum; tetapkan masa simpan dan hak akses sebelum peluncuran asesmen berisiko tinggi.
- Bedakan hasil kuis latihan, rekomendasi AI, penilaian tutor, dan sertifikat resmi.
- Jangan menyatakan kompetensi atau kelulusan formal tanpa kriteria, bukti, dan otorisasi yang jelas.
- Klaim hukum, ketenagakerjaan, pendidikan, kesehatan, dan keselamatan harus ditautkan ke sumber resmi terkini bila relevan.

## Batasan implementasi saat ini

Antarmuka AI Tutor dapat memanggil endpoint AI yang sudah ada dan menggunakan konteks sesi. Keluaran suara memakai kemampuan browser/perangkat, sehingga ketersediaan suara Bahasa Indonesia bergantung pada sistem. Penilaian kuis pada klien merupakan formatif dan belum menjadi rekam nilai formal. Workflow penilaian manusia, portofolio terstruktur, jadwal wawancara, dan keputusan kelulusan memerlukan modul backend serta skema data dan kontrol akses khusus sebelum dipakai produksi.
