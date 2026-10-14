# EDUNEXUS starter curriculum v1

## Content included

This migration adds original starter learning content to the catalog:

- **Program:** Fondasi Keterampilan Profesional
- **Course 1:** Komunikasi Profesional dan Kolaborasi
  - Merumuskan Pesan: Tujuan Pesan dan Audiens; Struktur Pesan Profesional
  - Mendengar Aktif dan Umpan Balik: Mendengar Aktif; Umpan Balik Berbasis Perilaku
- **Course 2:** Literasi Data dan Pemecahan Masalah
  - Mendefinisikan Masalah: Membuat Pertanyaan yang Bisa Diuji; Membedakan Fakta dan Asumsi
  - Membaca Data untuk Keputusan: Membaca Tabel dan Tren; Membuat Rekomendasi Berbasis Data
- Four initial skill taxonomy records: Komunikasi Profesional, Mendengar Aktif dan Umpan Balik, Literasi Data, Pemecahan Masalah.

The content is original instructional material, not copied courseware. It is a starter curriculum, not an official certificate, national qualification, or replacement for institutional review.

## Database rollout

- Neon migration: neon/migrations/0005_initial_curriculum_seed.sql
- Supabase migration: supabase/migrations/20261014140000_initial_curriculum_seed.sql
- The Neon migration has been applied and verified **only on the disposable test branch** edunexus-cutover-test-20261014; a repeat run retained exactly 1 program, 2 courses, 4 modules, and 8 lessons.
- Production Neon and rollback Supabase have not been seeded by this change. Apply the migration to production only after reviewing the content and confirming the target branch.

## Learner flow

Learners can browse course → module → lesson, read lesson sections and exercises, enroll, and save lesson completion. The backend checks ownership and enrollment through existing row-level security policies. A completed lesson records 100% progress; it does not automatically award mastery or certification.
