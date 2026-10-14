-- EDUNEXUS starter curriculum v1. Original learning content; safe to re-run.
-- Catalog records are public-read. Enrollment and lesson progress remain user-owned.
BEGIN;

INSERT INTO public.programs (name, slug, description)
VALUES (
  'Fondasi Keterampilan Profesional',
  'fondasi-keterampilan-profesional',
  'Kursus awal untuk komunikasi profesional, kolaborasi, literasi data, dan pemecahan masalah.'
)
ON CONFLICT (slug) DO UPDATE
SET name = EXCLUDED.name, description = EXCLUDED.description, updated_at = now();

INSERT INTO public.skills (slug, name, domain, description)
VALUES
  ('komunikasi-profesional', 'Komunikasi Profesional', 'soft_skill', 'Menyampaikan pesan dengan jelas sesuai tujuan dan audiens.'),
  ('mendengar-aktif', 'Mendengar Aktif dan Umpan Balik', 'soft_skill', 'Memastikan pemahaman dan memberi umpan balik yang spesifik serta dapat ditindaklanjuti.'),
  ('literasi-data', 'Literasi Data', 'hard_skill', 'Membaca tabel, pola, tren, dan keterbatasan data.'),
  ('pemecahan-masalah', 'Pemecahan Masalah', 'hard_skill', 'Merumuskan masalah, membedakan fakta dan asumsi, serta mengevaluasi pilihan.')
ON CONFLICT (slug) DO UPDATE
SET name = EXCLUDED.name, domain = EXCLUDED.domain, description = EXCLUDED.description, updated_at = now();

INSERT INTO public.courses (program_id, name, slug, description)
SELECT p.id, v.name, v.slug, v.description
FROM public.programs p
CROSS JOIN (VALUES
  ('Komunikasi Profesional dan Kolaborasi', 'komunikasi-profesional-kolaborasi', 'Latihan praktis merumuskan pesan, mendengar aktif, dan memberi umpan balik berbasis perilaku.'),
  ('Literasi Data dan Pemecahan Masalah', 'literasi-data-pemecahan-masalah', 'Latihan mendefinisikan pertanyaan, membaca tabel dan tren, serta menyusun rekomendasi yang dapat diperiksa.')
) AS v(name, slug, description)
WHERE p.slug = 'fondasi-keterampilan-profesional'
ON CONFLICT (slug) DO UPDATE
SET program_id = EXCLUDED.program_id, name = EXCLUDED.name, description = EXCLUDED.description, updated_at = now();

INSERT INTO public.modules (course_id, name, position)
SELECT c.id, v.name, v.position
FROM public.courses c
JOIN (VALUES
  ('komunikasi-profesional-kolaborasi', 'Merumuskan Pesan', 1),
  ('komunikasi-profesional-kolaborasi', 'Mendengar Aktif dan Umpan Balik', 2),
  ('literasi-data-pemecahan-masalah', 'Mendefinisikan Masalah', 1),
  ('literasi-data-pemecahan-masalah', 'Membaca Data untuk Keputusan', 2)
) AS v(course_slug, name, position) ON c.slug = v.course_slug
ON CONFLICT (course_id, position) DO UPDATE SET name = EXCLUDED.name;

INSERT INTO public.lessons (module_id, title, content, position)
SELECT m.id, v.title,
  jsonb_build_object(
    'summary', v.summary,
    'objectives', jsonb_build_array(v.objective),
    'sections', jsonb_build_array(jsonb_build_object('heading', 'Materi inti', 'body', v.body)),
    'exercise', v.exercise
  ),
  v.lesson_position
FROM (VALUES
  ('komunikasi-profesional-kolaborasi', 1, 1, 'Tujuan Pesan dan Audiens',
   'Pesan yang efektif dimulai dari hasil yang ingin dicapai dan kebutuhan penerima.',
   'Menentukan tujuan, audiens, dan tindakan yang diharapkan dari sebuah pesan.',
   'Sebelum menulis, jawab tiga pertanyaan: siapa penerimanya, apa yang perlu dipahami, dan tindakan apa yang diperlukan? Pilih detail sesuai konteks; jangan menyamakan pesan untuk pimpinan, rekan kerja, dan pelanggan.',
   'Tulis pesan singkat untuk meminta pembaruan proyek. Sebutkan konteks, permintaan spesifik, tenggat, dan alasan bila relevan. Periksa apakah penerima tahu tindakan berikutnya.'),
  ('komunikasi-profesional-kolaborasi', 1, 2, 'Struktur Pesan Profesional',
   'Struktur sederhana membantu pesan dibaca dan ditindaklanjuti.',
   'Menyusun pesan dengan konteks, inti, bukti atau detail, dan tindakan berikutnya.',
   'Gunakan pola: konteks singkat → inti pesan → detail yang diperlukan → permintaan atau keputusan → tenggat. Hindari pembukaan panjang dan permintaan yang ambigu. Untuk isu kompleks, pisahkan fakta, risiko, opsi, dan rekomendasi.',
   'Revisi pesan yang terlalu umum menjadi empat kalimat: konteks, fakta utama, permintaan, dan tenggat.'),
  ('komunikasi-profesional-kolaborasi', 2, 1, 'Mendengar Aktif',
   'Mendengar aktif bertujuan memahami, bukan sekadar menunggu giliran bicara.',
   'Menggunakan parafrasa, pertanyaan klarifikasi, dan rangkuman kesepakatan.',
   'Dengarkan sampai selesai, parafrasekan inti dengan bahasa sendiri, tanyakan bagian yang belum jelas, lalu rangkum kesepakatan dan penanggung jawab. Jangan menyimpulkan niat seseorang tanpa bukti; konfirmasikan pemahaman secara langsung.',
   'Buat tiga pertanyaan klarifikasi untuk situasi ketika instruksi proyek masih ambigu. Akhiri dengan satu kalimat rangkuman untuk dikonfirmasi.'),
  ('komunikasi-profesional-kolaborasi', 2, 2, 'Umpan Balik Berbasis Perilaku',
   'Umpan balik yang berguna membahas tindakan yang dapat diamati dan dampaknya, bukan label kepribadian.',
   'Menyampaikan observasi spesifik, dampak, dan permintaan perbaikan yang realistis.',
   'Gunakan pola situasi → perilaku yang teramati → dampak → permintaan atau pertanyaan. Pisahkan fakta dari interpretasi. Berikan ruang bagi penerima untuk menjelaskan konteks dan sepakati tindak lanjut.',
   'Ubah kalimat “kamu tidak profesional” menjadi umpan balik yang menyebut satu perilaku teramati, dampaknya, dan permintaan yang bisa dilakukan.'),
  ('literasi-data-pemecahan-masalah', 1, 1, 'Membuat Pertanyaan yang Bisa Diuji',
   'Analisis dimulai dari pertanyaan yang jelas, bukan dari grafik yang menarik.',
   'Mendefinisikan keputusan, metrik, kelompok pembanding, dan rentang waktu.',
   'Tuliskan keputusan yang perlu dibuat, metrik yang relevan, unit analisis, periode, serta batasan data. Pertanyaan yang baik dapat dijawab dengan bukti yang tersedia atau menyebut data apa yang masih dibutuhkan.',
   'Ubah “penjualan sedang buruk” menjadi pertanyaan terukur dengan metrik, periode, dan pembanding yang jelas.'),
  ('literasi-data-pemecahan-masalah', 1, 2, 'Membedakan Fakta dan Asumsi',
   'Fakta berasal dari data atau observasi yang dapat diperiksa; asumsi adalah dugaan yang masih perlu diuji.',
   'Memberi label pada fakta, interpretasi, asumsi, dan informasi yang belum tersedia.',
   'Buat empat kolom: fakta, interpretasi, asumsi, dan data yang belum tersedia. Cari penjelasan alternatif sebelum menyimpulkan sebab-akibat. Korelasi atau perubahan bersamaan tidak otomatis membuktikan penyebab.',
   'Dari sebuah laporan penurunan pengguna, tulis dua fakta yang perlu diverifikasi, dua kemungkinan penyebab, dan satu data tambahan yang dibutuhkan.'),
  ('literasi-data-pemecahan-masalah', 2, 1, 'Membaca Tabel dan Tren',
   'Tabel dan tren perlu dibaca dengan memperhatikan satuan, periode, skala, dan nilai pembanding.',
   'Memeriksa label, denominator, perubahan absolut dan relatif, serta keterbatasan sampel.',
   'Sebelum membandingkan angka, periksa satuan, periode, jumlah sampel, definisi metrik, dan denominator. Laporkan perubahan absolut maupun persentase jika keduanya membantu. Perhatikan nilai hilang dan perubahan metode pengukuran.',
   'Buat daftar pemeriksaan singkat sebelum membandingkan dua bulan data. Jelaskan kapan persentase dapat menyesatkan jika jumlah awal sangat kecil.'),
  ('literasi-data-pemecahan-masalah', 2, 2, 'Membuat Rekomendasi Berbasis Data',
   'Rekomendasi yang baik menghubungkan bukti, opsi, risiko, dan cara mengevaluasi hasil.',
   'Menyusun rekomendasi yang menyatakan bukti, ketidakpastian, langkah berikutnya, dan ukuran keberhasilan.',
   'Rangkum temuan, sebutkan keterbatasan, bandingkan opsi, lalu usulkan langkah yang dapat diuji. Tentukan pemilik tindakan, waktu evaluasi, metrik keberhasilan, dan kondisi yang akan mengubah keputusan.',
   'Buat rekomendasi satu paragraf yang berisi temuan, keterbatasan, langkah uji kecil, metrik keberhasilan, dan waktu tinjauan.')
) AS v(course_slug, module_position, lesson_position, title, summary, objective, body, exercise)
JOIN public.courses c ON c.slug = v.course_slug
JOIN public.modules m ON m.course_id = c.id AND m.position = v.module_position
ON CONFLICT (module_id, position) DO UPDATE
SET title = EXCLUDED.title, content = EXCLUDED.content;

COMMIT;
