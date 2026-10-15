# Integrasi UX/UI Nexus System untuk EDUNEXUS

Tanggal: 15 Oktober 2026

## Perubahan arsitektur
- web/index.html menjadi website resmi publik EDUNEXUS.
- web/app/index.html mempertahankan aplikasi pembelajaran sebelumnya, termasuk integrasi autentikasi Neon dan fitur belajar.
- Berkas knowledge disalin ke web/app/ agar URL relatif tetap valid pada GitHub Pages project site.

## Arah visual
Website publik memakai bahasa visual industrial-tech yang diadaptasi dari deskripsi resmi TemplateMo Nexus System: permukaan gelap menyerupai titanium, aksen acid-lime, penanda monospace, garis teknis, panel modular, dan animasi ringan yang menghormati preferensi reduced-motion.

## Batasan sumber
Halaman TemplateMo menyatakan Nexus System gratis untuk penggunaan komersial/nonkomersial. Namun unduhan ZIP dan halaman live preview tidak berhasil diakses melalui koneksi integrasi. Implementasi ini adalah adaptasi desain yang terinspirasi dari spesifikasi visual publik, bukan salinan sumber HTML/CSS asli. Jika arsip ZIP tersedia di library lokal, aset asli dapat disinkronkan pada iterasi berikutnya.

## Verifikasi
GitHub Actions CI, frontend syntax, browser smoke tests, dan pemeriksaan halaman publik serta /app/ harus lulus sebelum menyatakan migrasi selesai. Pendaftaran/login dan operasi data tetap bergantung pada backend Neon yang dikonfigurasi.
