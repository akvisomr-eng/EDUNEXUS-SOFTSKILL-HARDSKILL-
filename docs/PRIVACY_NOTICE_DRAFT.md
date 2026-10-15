# EDUNEXUS — Draft Pemberitahuan Privasi

**Status: DRAF INTERNAL — belum layak dipublikasikan sebelum identitas pengelola, kontak, retensi, dan penyedia pemroses dikonfirmasi.**

Dokumen ini merupakan kerangka awal untuk ditinjau oleh pengelola dan penasihat hukum. Jangan menganggap bagian yang belum diisi sebagai kebijakan final.

## 1. Pengelola data

- Nama badan/orang yang mengelola: **[WAJIB DIISI]**
- Alamat/kedudukan resmi: **[WAJIB DIISI]**
- Kontak privasi dan permintaan pengguna: **[WAJIB DIISI]**
- Tanggal berlaku dan versi: **[WAJIB DIISI]**

## 2. Data yang mungkin diproses

Sesuai fitur yang benar-benar diaktifkan, layanan dapat memproses:
- data akun dan identitas teknis yang diperlukan untuk autentikasi;
- jawaban latihan, progres, riwayat praktik, dan hasil yang ditampilkan kepada pengguna;
- pesan yang sengaja dikirim pengguna ke fitur AI apabila inferensi AI diaktifkan;
- log teknis minimum untuk keamanan, diagnosis kesalahan, dan pencegahan penyalahgunaan.

Jangan mengumpulkan data yang tidak diperlukan. Jangan memasukkan data anak, data kesehatan, dokumen identitas, atau informasi sensitif ke fitur AI kecuali ada dasar pemrosesan dan perlindungan yang telah ditinjau secara khusus.

## 3. Tujuan dan dasar pemrosesan

Pengelola harus mendokumentasikan tujuan dan dasar pemrosesan yang berlaku untuk setiap kategori data, termasuk penyediaan akun, pelaksanaan fitur pembelajaran, keamanan, dukungan, dan kewajiban hukum. **[WAJIB DITINJAU DAN DILENGKAPI]**

## 4. Penyedia layanan dan transfer data

- Infrastruktur autentikasi/database: Neon, sesuai konfigurasi produksi.
- Hosting frontend: GitHub Pages.
- Penyedia model AI: **belum dikonfirmasi pada draf ini; isi hanya setelah provider benar-benar dipilih dan diaktifkan.**
- Analitik, pembayaran, email, dan penyedia lainnya: **isi sesuai integrasi yang benar-benar digunakan; jangan mencantumkan integrasi yang belum ada.**

Catat lokasi pemrosesan, ketentuan provider, subprosesor, dan mekanisme transfer data lintas negara bila berlaku.

## 5. Retensi, keamanan, dan penghapusan

Pengelola wajib menentukan periode retensi yang terukur untuk akun, hasil belajar, percakapan AI, dan log keamanan. Jelaskan langkah teknis dan operasional untuk penghapusan akun/data, backup, dan permintaan penghapusan. **[WAJIB DIISI sebelum peluncuran publik]**

Terapkan akses berbasis kebutuhan, penyimpanan kredensial di sisi server, pembatasan akses, pemantauan, dan prosedur respons insiden. Jangan menjanjikan keamanan mutlak.

## 6. Hak dan permintaan pengguna

Sediakan kanal yang dapat diakses pengguna untuk mengajukan permintaan akses, koreksi, penghapusan, penarikan persetujuan jika relevan, atau keluhan. Tetapkan cara verifikasi identitas, waktu respons, dan pencatatan permintaan. **[WAJIB DIISI]**

## 7. Anak dan pengguna institusi

Sebelum layanan digunakan anak atau melalui institusi pendidikan, tinjau persyaratan persetujuan wali, peran institusi, minimisasi data, kontrol berbagi, dan akses staf. Jangan gunakan hasil AI sebagai satu-satunya dasar keputusan berisiko tinggi.

## 8. Perubahan pemberitahuan

Jelaskan cara memberi tahu pengguna jika perubahan material dilakukan dan bagaimana versi kebijakan terdahulu disimpan.

## 9. Kontak

**[NAMA PENGELOLA, EMAIL/KANAL RESMI, DAN ALAMAT YANG SAH WAJIB DILENGKAPI]**

---
Checklist sebelum publikasi:
- [ ] Identitas pengelola dan kontak sah telah diisi.
- [ ] Inventaris data aktual telah dibandingkan dengan kode dan konfigurasi produksi.
- [ ] Provider AI dan subprosesor telah dikonfirmasi.
- [ ] Retensi, backup, penghapusan, dan proses permintaan pengguna telah diuji.
- [ ] Penggunaan untuk anak/institusi telah ditinjau.
- [ ] Dokumen ditinjau oleh pihak yang kompeten untuk hukum yang berlaku.
