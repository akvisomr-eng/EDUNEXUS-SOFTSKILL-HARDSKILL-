# EDUNEXUS AI Runtime — konfigurasi aman

Dokumen ini adalah runbook operasional untuk mengaktifkan inferensi model pada fungsi Neon `edunexusai`. Jangan menambahkan kredensial ke repository, source frontend, issue, log, atau percakapan.

## Status yang telah diverifikasi

- Fungsi produksi berada pada project Neon `holy-breeze-21216615`, branch `br-bitter-king-azb11lde`, slug `edunexusai`.
- Fungsi produksi terakhir yang diperiksa memiliki environment `APP_ORIGIN`, `KNOWLEDGE_CORPUS_URL`, `MODEL_API_BASE_URL`, `MODEL_ID`, dan `NEON_AUTH_JWKS_URL`.
- `MODEL_API_KEY` belum terpasang pada deployment tersebut. Karena itu `/health` melaporkan `inferenceConfigured: false`, dan mode Project Builder tetap tertutup.
- Kuota persisten `consume_edunexus_ai_quota()` telah diterapkan dan diuji pada production serta preview: 10 permintaan/menit dan 100 permintaan/hari per identitas aplikasi. Runtime memanggil RPC dengan JWT pengguna dan gagal tertutup jika layanan kuota tidak tersedia.
- Workflow Runtime Health telah lulus pada kedua deployment setelah pembaruan ini. Inferensi model masih belum aktif.
- Browser smoke test terbaru menguji autentikasi, alur praktik, frontend, dan isolasi lintas akun. Pengujian itu bukan bukti bahwa inferensi AI sudah aktif.

## Langkah aktivasi

1. Pilih penyedia model yang menyediakan API kompatibel dengan format OpenAI Chat Completions. Periksa batas penggunaan, ketentuan data, dan harga terlebih dahulu; gunakan free tier jika tersedia dan sesuai.
2. Buat API key pada dashboard resmi penyedia. Jangan pernah mengirim key melalui chat atau memasukkannya ke source code.
3. Buka project Neon yang benar, lalu pilih branch produksi dan fungsi `edunexusai`. Tambahkan `MODEL_API_KEY` sebagai environment secret untuk fungsi. Pastikan `MODEL_API_BASE_URL` adalah base URL API resmi penyedia (tanpa akhiran `/chat/completions`) dan `MODEL_ID` adalah ID model yang benar-benar tersedia untuk akun tersebut.
4. Deploy versi fungsi baru setelah secret/environment diperbarui. Jangan mengubah `NEON_AUTH_JWKS_URL` atau `APP_ORIGIN` tanpa memverifikasi integrasi yang sudah berjalan.
5. Periksa endpoint `/health`. Aktivasi inferensi hanya terkonfirmasi jika `inferenceConfigured` bernilai `true`; hal itu belum membuktikan permintaan model berhasil.
6. Dari aplikasi, masuk dengan akun terautentikasi dan kirim satu pertanyaan belajar berbiaya rendah. Periksa respons, waktu tunggu, batas penggunaan, dan log fungsi. Setelah itu uji mode Project Builder; respons yang diharapkan saat aktif adalah jawaban perencanaan dari empat agen, bukan commit atau deployment.
7. Uji kasus negatif: tanpa token harus menghasilkan HTTP 401; origin yang tidak diizinkan harus ditolak; pesan terlalu besar harus ditolak; kegagalan penyedia tidak boleh mengembalikan jawaban simulasi.
8. Jangan mengklaim fitur GitHub write, patch, CI orchestration, atau deployment otonom sudah aktif. Policy guard GitHub yang ada masih merupakan helper teruji, bukan konektor yang terhubung ke runtime.

## Checklist setelah konfigurasi

- [ ] Secret disimpan hanya pada konfigurasi server-side fungsi.
- [ ] `/health` melaporkan `persistentQuotaConfigured: true` pada production dan preview.
- [ ] `/health` melaporkan inferensi terkonfigurasi.
- [ ] Permintaan model terautentikasi berhasil dengan provider/model yang dipilih.
- [ ] Uji tanpa autentikasi tetap menghasilkan 401.
- [ ] Tidak ada secret dalam bundle frontend, commit, atau log.
- [ ] Penggunaan dan biaya dipantau; batas biaya/provider disetel jika tersedia.
- [ ] Project Builder tetap hanya merencanakan sampai gateway GitHub terpisah selesai diaudit dan diuji.

## Batasan keamanan

Mengaktifkan `MODEL_API_KEY` mengaktifkan panggilan model saja. Itu tidak memberi fungsi akses GitHub, tidak mengaktifkan eksekusi kode, dan tidak memigrasikan tabel Project Builder ke produksi. Skema `0011_project_builder_records.sql` saat ini baru tercatat diterapkan dan diverifikasi pada branch preview. Promosi ke produksi memerlukan pemeriksaan pemetaan identitas `auth.uid()` dan kebijakan RLS terlebih dahulu.
