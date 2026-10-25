# EDUNEXUS AI Runtime — konfigurasi aman

Dokumen ini adalah runbook operasional untuk mengaktifkan inferensi model pada fungsi Neon `edunexusai`. Jangan menambahkan kredensial ke repository, source frontend, issue, log, atau percakapan.

## Status yang telah diverifikasi

- Fungsi produksi berada pada project Neon `holy-breeze-21216615`, branch `br-bitter-king-azb11lde`, slug `edunexusai`.
- Fungsi produksi terakhir yang diperiksa memiliki environment `APP_ORIGIN`, `KNOWLEDGE_CORPUS_URL`, `MODEL_API_BASE_URL`, `MODEL_ID`, dan `NEON_AUTH_JWKS_URL`.
- Neon AI Gateway metadata is enabled and branch-scoped credentials exist, but an authenticated preview model request returned HTTP 403 with the sanitized provider message that AI Gateway is not enabled on this account's current plan. Production `edunexusai` deployment #16 now has `AI_ENABLED=false` to keep the service in safe curated-retrieval mode until access is authorized. The code supports explicit server-side provider credentials and a managed-gateway fallback; health configuration alone does not prove model access.
- Kuota persisten `consume_edunexus_ai_quota()` telah diterapkan dan diuji pada production serta preview: 10 permintaan/menit dan 100 permintaan/hari per identitas aplikasi. Runtime memanggil RPC dengan JWT pengguna dan gagal tertutup jika layanan kuota tidak tersedia.
- Workflow Runtime Health telah lulus pada kedua deployment setelah pembaruan ini. Inferensi model masih belum aktif.
- Browser smoke test terbaru menguji autentikasi, alur praktik, frontend, dan isolasi lintas akun. Pengujian itu bukan bukti bahwa inferensi AI sudah aktif.

## Emergency stop

Set `AI_ENABLED=false` in the Neon Function server-side environment and deploy a new function version to stop provider inference immediately. `/health` then reports `inferenceConfigured: false` and `inferenceDisabled: true`; curated retrieval remains available, while Project Builder fails closed. Restore only after investigating the incident.

## Langkah aktivasi

1. Pemanggilan Neon AI Gateway saat ini ditolak oleh paket akun (HTTP 403); jangan mencoba memutar model berulang kali untuk melewati batas paket. Minta pemilik akun mengaktifkan paket yang memenuhi syarat dan kredit AI yang diperlukan, atau pilih provider eksternal yang disetujui.
2. Untuk provider eksternal, buat API key hanya di dashboard resmi provider dan simpan sebagai environment secret `MODEL_API_KEY`; jangan pernah mengirim key melalui chat atau memasukkannya ke source code. Set `MODEL_API_BASE_URL` (tanpa `/chat/completions`) dan `MODEL_ID` ke nilai yang provider konfirmasi.
3. Setelah akses disetujui, ubah environment `AI_ENABLED` menjadi `true` atau hapus nilai `false`, deploy versi fungsi baru, lalu uji permintaan model autentikasi. Jangan mengubah `NEON_AUTH_JWKS_URL` atau `APP_ORIGIN` tanpa memverifikasi integrasi yang sudah berjalan.
4. Periksa endpoint `/health`. `inferenceConfigured: true` hanya menunjukkan kredensial dan konfigurasi tersedia; itu belum membuktikan panggilan model berhasil.
5. Dari aplikasi, masuk dengan akun terautentikasi dan kirim satu pertanyaan belajar berbiaya rendah. Periksa respons, waktu tunggu, batas penggunaan, dan error provider. Uji Project Builder setelah inference berhasil; hasilnya adalah rencana multi-agent, bukan commit atau deployment.
7. Uji kasus negatif: tanpa token harus menghasilkan HTTP 401; origin yang tidak diizinkan harus ditolak; pesan terlalu besar harus ditolak; kegagalan penyedia tidak boleh mengembalikan jawaban simulasi.
8. Jangan mengklaim fitur GitHub write, patch, CI orchestration, atau deployment otonom sudah aktif. Policy guard GitHub yang ada masih merupakan helper teruji, bukan konektor yang terhubung ke runtime.

## Checklist setelah konfigurasi

- [ ] Neon AI Gateway env tersedia pada fungsi atau secret provider eksternal disimpan hanya pada konfigurasi server-side.
- [ ] Emergency switch `AI_ENABLED` tersedia dan diuji.
- [ ] `/health` melaporkan `persistentQuotaConfigured: true` pada production dan preview.
- [ ] `/health` melaporkan inferensi terkonfigurasi setelah deployment runtime fallback.
- [ ] Permintaan model terautentikasi berhasil dengan model yang tersedia pada katalog gateway.
- [ ] Uji tanpa autentikasi tetap menghasilkan 401.
- [ ] Tidak ada secret dalam bundle frontend, commit, atau log.
- [ ] Penggunaan dan biaya dipantau; batas biaya/provider disetel jika tersedia.
- [ ] Project Builder tetap hanya merencanakan sampai gateway GitHub terpisah selesai diaudit dan diuji.

## Batasan keamanan

Mengaktifkan `MODEL_API_KEY` mengaktifkan panggilan model saja. Itu tidak memberi fungsi akses GitHub, tidak mengaktifkan eksekusi kode, dan tidak memigrasikan tabel Project Builder ke produksi. Skema `0011_project_builder_records.sql` saat ini baru tercatat diterapkan dan diverifikasi pada branch preview. Promosi ke produksi memerlukan pemeriksaan pemetaan identitas `auth.uid()` dan kebijakan RLS terlebih dahulu.


## Jalur free tier: Groq (preview terlebih dahulu)

Runtime mendukung provider OpenAI-compatible. Untuk uji preview, kandidat awal adalah `MODEL_API_BASE_URL=https://api.groq.com/openai/v1`, `MODEL_ID=openai/gpt-oss-20b`, dan `MODEL_API_KEY` yang dibuat pada konsol resmi Groq. Function menambahkan `/chat/completions` secara otomatis. Model dan kuota gratis dapat berubah; verifikasi daftar model serta batas akun pada dokumentasi resmi Groq sebelum pengujian. Lihat [runbook aktivasi Groq](GROQ_FREE_TIER_ACTIVATION.md) untuk checklist koneksi, kualitas, keamanan, privasi, kuota, fallback, dan gerbang pilot publik.

**Jangan mengaktifkan produksi pada tahap ini.** Simpan key hanya di environment server-side fungsi Neon pada branch preview. Pertahankan `AI_ENABLED=false` di produksi. Gunakan data sintetis, bukan data siswa atau data pribadi. Aktifkan uji publik terbatas hanya setelah seluruh tes preview lulus dan pemilik menyetujui perubahan produksi secara terpisah.
