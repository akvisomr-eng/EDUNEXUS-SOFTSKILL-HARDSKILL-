# Keputusan penyedia AI EDUNEXUS — opsi Rp0

**Tanggal pemeriksaan:** 17 Oktober 2026  
**Status:** keputusan teknis; belum mengaktifkan inferensi produksi.

## Keputusan

1. **Jangan mengganti endpoint inferensi dengan GitHub.** GitHub Models telah dihentikan pada 30 Juli 2026. GitHub tetap dipakai untuk source control, pull request, CI/CD, pemeriksaan keamanan, dan otomasi tugas repository.
2. **Pertahankan Groq sebagai pilihan pertama untuk uji coba Rp0**, karena EDUNEXUS sebelumnya memang memilih Groq dan Groq menerbitkan batas pemakaian Free Plan. Batas berbeda menurut model dan dapat berubah; cek dashboard akun dan tabel limit resmi sebelum uji.
3. **Jangan aktifkan inferensi sampai kredensial yang sah tersedia di secret server-side Neon.** Tidak ada kunci yang boleh masuk ke Git, GitHub Actions logs, browser/frontend, dokumentasi, atau percakapan.
4. Gemini API dan Hugging Face Inference Providers adalah alternatif eksperimen, bukan pengganti otomatis. Gemini Free Tier memiliki ketentuan penggunaan data untuk peningkatan produk; jangan kirim data pribadi siswa, data institusi rahasia, atau data sensitif sebelum tinjauan privasi dan syarat layanan. Kredit gratis Hugging Face sangat kecil dan bukan jaminan kapasitas publik berkelanjutan.
5. **Jangan pernah fallback diam-diam ke provider berbayar.** Jika limit tercapai, kredensial tidak valid, atau provider gagal, runtime harus tetap gagal tertutup/menyajikan curated retrieval yang diberi label jelas.

## Matriks keputusan

| Opsi | Bisa menjadi endpoint model? | Biaya/kuota | Keputusan |
|---|---|---|---|
| GitHub Models | Tidak; layanannya telah dihentikan | Tidak tersedia | Gunakan GitHub hanya untuk development/CI |
| Groq API Free Plan | Ya, dengan API key dan model yang didukung | Batas gratis per model; periksa dashboard | Pilihan pertama untuk pilot terbatas |
| Gemini API Free Tier | Ya, dengan API key dan konfigurasi yang sesuai | Free tier dengan batas; data free-tier dapat dipakai untuk peningkatan produk | Alternatif hanya setelah tinjauan privasi |
| Hugging Face Inference Providers | Ya, provider/model yang didukung | Akun Free tercantum mendapat kredit bulanan kecil; bukan kapasitas produksi | Hanya eksperimen terukur |
| Model lokal/self-host | Ya, jika ada mesin/hosting yang menjalankannya | Tidak selalu Rp0: listrik, perangkat, dan hosting tetap berbiaya | Belum dipilih untuk produksi |

## Arsitektur yang dipertahankan

- **Frontend:** GitHub Pages; tidak menyimpan secret provider.
- **Backend:** Neon Auth, database, persistent quota, dan fungsi `edunexusai`.
- **Inferensi:** provider eksternal melalui environment secret di Neon; Groq pilihan pertama bila pemilik telah membuat key.
- **GitHub Actions:** lint, test, dependency/security checks, health checks, dan workflow repository yang dibatasi. Actions tidak menggantikan inferensi percakapan model.
- **Batas kuota aplikasi:** pertahankan batas persistent yang sudah diuji, 10 permintaan/menit dan 100/hari per identitas aplikasi. Ini tidak menggantikan limit dan pemantauan penggunaan di sisi provider.

## Gerbang aktivasi

- [ ] API key dibuat melalui dashboard resmi provider dan disimpan hanya di Neon Function environment sebagai `MODEL_API_KEY`.
- [ ] `AI_ENABLED` tetap `false` sampai konfigurasi lengkap dan disetujui.
- [ ] `MODEL_API_BASE_URL` dan `MODEL_ID` sesuai dokumentasi resmi provider/model; base URL tanpa suffix `/chat/completions` jika itulah kontrak runtime.
- [ ] Deploy versi baru `edunexusai`, lalu uji satu permintaan autentikasi nyata dengan data non-sensitif.
- [ ] Buktikan respons model nyata, provider/model terlapor, timeout/error handling, batas penggunaan, dan tidak ada secret di respons/log/bundle.
- [ ] Uji tanpa autentikasi (401), kuota habis, provider gagal, origin tidak diizinkan, serta emergency stop.
- [ ] Jalankan workflow `EDUNEXUS Public Trial Readiness Gate`; jangan membuka pilot publik jika gate gagal.
- [ ] Catat hasil pengujian dan tinjau syarat privasi provider sebelum menerima data pengguna nyata.

## Sumber resmi yang diperiksa

- GitHub Models retirement: https://github.blog/changelog/2026-07-30-github-models-is-now-retired/
- Groq rate limits: https://console.groq.com/docs/rate-limits
- Gemini API pricing/free-tier terms: https://ai.google.dev/gemini-api/docs/pricing
- Hugging Face Inference Providers pricing: https://huggingface.co/docs/inference-providers/pricing

**Kesimpulan operasional:** tidak ada perubahan provider produksi yang aman untuk dilakukan hanya dengan mengganti nama “Groq” menjadi “GitHub”. Pertahankan `AI_ENABLED=false` sampai ada key provider sah di Neon dan uji end-to-end berhasil. Tidak ada paket yang perlu dibeli untuk pekerjaan dokumentasi/CI ini.
