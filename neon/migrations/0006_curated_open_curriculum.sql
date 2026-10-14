-- Curated public-source curriculum extension for EDUNEXUS.
-- Original Indonesian learning content with source links and license notes.
-- Does not copy third-party course text; official/open sources are cited for further study.
BEGIN;

INSERT INTO public.programs (name, slug, description)
VALUES
 ('Literasi Digital dan Kecakapan AI', 'literasi-digital-kecakapan-ai', 'Literasi informasi, data, dan penggunaan AI yang bertanggung jawab.'),
 ('Kesiapan Karier dan Pembelajaran Sepanjang Hayat', 'kesiapan-karier-pembelajaran-sepanjang-hayat', 'Keterampilan kerja, refleksi bukti, dan pengembangan kompetensi.')
ON CONFLICT (slug) DO UPDATE SET name=EXCLUDED.name, description=EXCLUDED.description, updated_at=now();

INSERT INTO public.skills (slug,name,domain,description)
VALUES
 ('literasi-ai-bertanggung-jawab','Literasi AI yang Bertanggung Jawab','hard_skill','Memahami kemampuan, keterbatasan, risiko, dan penggunaan AI secara bertanggung jawab.'),
 ('literasi-informasi-digital','Literasi Informasi Digital','hard_skill','Menemukan, memeriksa, dan mengomunikasikan informasi dengan sumber yang dapat ditelusuri.'),
 ('berpikir-kritis','Berpikir Kritis','soft_skill','Mengevaluasi bukti, asumsi, alternatif, dan ketidakpastian sebelum mengambil keputusan.'),
 ('adaptabilitas-belajar-mandiri','Adaptabilitas dan Belajar Mandiri','soft_skill','Menetapkan tujuan belajar, mencari umpan balik, dan menyesuaikan strategi berdasarkan bukti.'),
 ('perencanaan-karier','Perencanaan Karier','soft_skill','Menghubungkan keterampilan, bukti kerja, minat, dan persyaratan peran secara reflektif.')
ON CONFLICT (slug) DO UPDATE SET name=EXCLUDED.name, domain=EXCLUDED.domain, description=EXCLUDED.description, updated_at=now();

INSERT INTO public.courses (program_id,name,slug,description)
SELECT p.id,v.name,v.slug,v.description
FROM (VALUES
 ('literasi-digital-kecakapan-ai','Literasi AI dan Penggunaan yang Bertanggung Jawab','literasi-ai-penggunaan-bertanggung-jawab','Memahami AI generatif, memeriksa keluaran, menjaga privasi, dan menyatakan penggunaan AI dengan transparan.'),
 ('literasi-digital-kecakapan-ai','Literasi Informasi dan Data Digital','literasi-informasi-data-digital','Menilai kredibilitas sumber, memeriksa klaim, membaca data, dan membuat ringkasan berbasis bukti.'),
 ('kesiapan-karier-pembelajaran-sepanjang-hayat','Kesiapan Karier dan Portofolio Keterampilan','kesiapan-karier-portofolio-keterampilan','Memetakan keterampilan terhadap peran, menyiapkan bukti kerja, dan merencanakan pembelajaran berikutnya.')
) AS v(program_slug,name,slug,description)
JOIN public.programs p ON p.slug=v.program_slug
ON CONFLICT (slug) DO UPDATE SET program_id=EXCLUDED.program_id,name=EXCLUDED.name,description=EXCLUDED.description,updated_at=now();

INSERT INTO public.modules(course_id,name,position)
SELECT c.id,v.name,v.position FROM public.courses c
JOIN (VALUES
 ('literasi-ai-penggunaan-bertanggung-jawab','Memahami AI Generatif',1),
 ('literasi-ai-penggunaan-bertanggung-jawab','Etika, Privasi, dan Verifikasi',2),
 ('literasi-informasi-data-digital','Menilai Sumber dan Klaim',1),
 ('literasi-informasi-data-digital','Membaca dan Menyampaikan Data',2),
 ('kesiapan-karier-portofolio-keterampilan','Memetakan Keterampilan',1),
 ('kesiapan-karier-portofolio-keterampilan','Bukti Kerja dan Rencana Belajar',2)
) AS v(course_slug,name,position) ON c.slug=v.course_slug
ON CONFLICT(course_id,position) DO UPDATE SET name=EXCLUDED.name;

INSERT INTO public.lessons(module_id,title,content,position)
SELECT m.id,v.title,
 jsonb_build_object(
  'summary',v.summary,
  'objectives',jsonb_build_array(v.objective),
  'sections',jsonb_build_array(jsonb_build_object('heading','Materi inti','body',v.body),jsonb_build_object('heading','Praktik yang disarankan','body',v.practice)),
  'exercise',v.exercise,
  'sources',v.sources::jsonb,
  'license_note','Materi pembelajaran EDUNEXUS ditulis ulang secara orisinal. Sumber dicantumkan sebagai rujukan dan bacaan lanjutan; bukan salinan isi sumber. Periksa lisensi setiap aset sebelum menggunakan ulang materi pihak ketiga.'
 ),
 v.lesson_position
FROM (VALUES
 ('literasi-ai-penggunaan-bertanggung-jawab',1,1,'Apa yang Dapat dan Tidak Dapat Dilakukan AI Generatif',
 'AI generatif menghasilkan keluaran berdasarkan pola dalam data dan instruksi; keluaran yang terdengar meyakinkan belum tentu benar.',
 'Menjelaskan kemampuan, keterbatasan, dan kebutuhan verifikasi pada keluaran AI.',
 'Gunakan AI untuk membantu menyusun ide, membuat draf, menjelaskan konsep, atau membandingkan pendekatan. Jangan menganggap AI sebagai sumber fakta tunggal. Model dapat salah, mengarang rujukan, kehilangan konteks, atau menyajikan informasi yang sudah kedaluwarsa. Tentukan sejak awal tugas mana yang boleh dibantu AI dan bagian mana yang harus dikerjakan serta dipahami sendiri.',
 'Bandingkan jawaban AI terhadap satu pertanyaan faktual dengan dua sumber primer yang tepercaya. Tandai klaim yang terverifikasi, belum terverifikasi, dan salah.',
 '["UNESCO — AI competency framework for students","https://www.unesco.org/en/articles/ai-competency-framework-students","Kerangka kompetensi AI: human-centred mindset, etika, teknik/aplikasi, dan desain sistem; gunakan sebagai rujukan konseptual."]'),
 ('literasi-ai-penggunaan-bertanggung-jawab',1,2,'Menyusun Instruksi dan Memeriksa Jawaban AI',
 'Instruksi yang jelas memberi konteks, tujuan, format keluaran, batasan, dan kriteria kualitas.',
 'Menyusun prompt yang dapat dievaluasi serta memeriksa keluaran sebelum digunakan.',
 'Berikan konteks secukupnya tanpa memasukkan data rahasia. Nyatakan audiens, tujuan, format, batasan, dan contoh bila perlu. Setelah menerima jawaban, periksa fakta, logika, sumber, bias, kelengkapan, dan kesesuaian tugas. Minta AI menunjukkan ketidakpastian, tetapi tetap lakukan pemeriksaan mandiri.',
 'Tulis dua versi prompt untuk merangkum topik pembelajaran. Buat rubrik lima poin untuk menilai akurasi, relevansi, keterbacaan, bukti, dan keterbatasan.',
 '["UNESCO — AI competency framework for students","https://www.unesco.org/en/articles/ai-competency-framework-students","Rujukan untuk merancang kompetensi AI secara bertahap; materi EDUNEXUS adalah adaptasi pedagogis orisinal."]'),
 ('literasi-ai-penggunaan-bertanggung-jawab',2,1,'Privasi, Persetujuan, dan Data Sensitif',
 'Informasi pribadi dan rahasia organisasi tidak boleh dimasukkan ke layanan AI tanpa dasar, izin, dan pengamanan yang tepat.',
 'Mengenali data sensitif dan memilih cara kerja yang meminimalkan risiko privasi.',
 'Jangan mengirim kata sandi, identitas pribadi, data kesehatan, catatan anak, data pelanggan, atau dokumen rahasia ke layanan AI publik tanpa otorisasi dan penilaian kebijakan. Gunakan contoh sintetis atau anonimisasi yang benar; penghapusan nama saja belum tentu menghilangkan risiko identifikasi ulang. Periksa kebijakan penyimpanan dan penggunaan data layanan.',
 'Ubah sebuah contoh kasus yang berisi nama dan nomor identitas menjadi contoh sintetis. Daftarkan data yang masih berisiko mengidentifikasi seseorang.',
 '["UNESCO — AI competency framework for teachers","https://www.unesco.org/en/articles/ai-competency-framework-teachers","Rujukan kebijakan dan praktik AI pendidikan yang menekankan hak, agensi manusia, dan penggunaan bertanggung jawab."]'),
 ('literasi-ai-penggunaan-bertanggung-jawab',2,2,'Transparansi, Bias, dan Akuntabilitas',
 'Penggunaan AI perlu transparan dan keputusan berdampak tinggi membutuhkan penilaian manusia yang bertanggung jawab.',
 'Mengungkapkan penggunaan AI, memeriksa bias, dan mempertahankan tanggung jawab atas keputusan.',
 'Jelaskan kapan dan untuk bagian apa AI digunakan sesuai aturan institusi. Periksa apakah keluaran merugikan kelompok tertentu, memakai asumsi tak berdasar, atau tidak dapat ditelusuri. Jangan gunakan inferensi otomatis tentang kepribadian, emosi, atau kondisi psikologis sebagai penilaian pasti. Untuk penilaian pembelajaran, gunakan rubrik transparan, bukti tugas, dan tinjauan manusia.',
 'Tinjau satu rekomendasi buatan AI: identifikasi asumsi, pihak yang mungkin dirugikan, bukti yang kurang, dan langkah verifikasi manusia.',
 '["UNESCO — AI competency framework for teachers","https://www.unesco.org/en/articles/ai-competency-framework-teachers","Kerangka global kompetensi AI pendidik; bukan pengganti kebijakan privasi dan regulasi setempat."]'),
 ('literasi-informasi-data-digital',1,1,'Menilai Kredibilitas Sumber',
 'Sumber yang dapat dipercaya memiliki asal-usul, penulis atau lembaga, tanggal, bukti, dan konteks yang bisa diperiksa.',
 'Memeriksa otoritas, kebaruan, bukti, tujuan, dan keterlacakan sebuah sumber.',
 'Mulai dari sumber primer bila tersedia: peraturan resmi, data asli, dokumentasi, atau publikasi peneliti. Periksa tanggal, metodologi, konflik kepentingan, dan apakah klaim sesuai dengan isi sumber. Hasil pencarian atau ringkasan AI adalah petunjuk untuk menelusuri sumber, bukan bukti final. Bandingkan sumber independen untuk klaim penting.',
 'Pilih satu klaim populer. Temukan sumber primer dan satu sumber independen; catat apa yang didukung bukti dan apa yang belum diketahui.',
 '["ESCO — Use ESCO and its classification","https://esco.ec.europa.eu/en/use-esco","Contoh taksonomi keterampilan dan pekerjaan yang dikelola sebagai data terstruktur dan dapat ditelusuri."]'),
 ('literasi-informasi-data-digital',1,2,'Memeriksa Klaim dan Rujukan',
 'Klaim harus sesuai dengan bukti yang benar-benar dikutip, bukan sekadar memiliki tautan atau nama lembaga.',
 'Melacak klaim sampai ke sumber asal dan membedakan fakta, interpretasi, serta ketidakpastian.',
 'Buka rujukan dan pastikan dokumen benar-benar mendukung klaim. Periksa apakah angka, kutipan, periode, populasi, dan konteks disampaikan secara akurat. Waspadai kutipan tanpa halaman, tautan mati, judul yang tidak cocok, serta angka tanpa denominator. Catat tanggal akses dan jangan mengubah perkiraan menjadi kepastian.',
 'Audit tiga klaim dalam satu artikel. Buat tabel: klaim, sumber primer, bukti pendukung, keterbatasan, dan status verifikasi.',
 '["Kementerian Pendidikan — Capaian Pembelajaran 2026","https://internal-portal.kemdikbud.go.id/siaran-pers/15636-capaian-pembelajaran-baru-telah-terbit-yang-berubah-hanya-mata-pelajaran-agama-dan-budi-pekerti","Gunakan kanal resmi untuk melacak pengumuman dan dokumen kebijakan terbaru; selalu buka lampiran/keputusan yang relevan."]'),
 ('literasi-informasi-data-digital',2,1,'Membaca Tabel dan Angka',
 'Interpretasi data harus memperhatikan definisi metrik, satuan, periode, ukuran sampel, dan nilai pembanding.',
 'Membaca data tanpa mengabaikan denominator, skala, dan keterbatasan.',
 'Sebelum menyimpulkan tren, periksa sumber data, definisi variabel, rentang waktu, nilai hilang, serta perubahan metode pengumpulan. Bedakan perubahan absolut dari persentase. Korelasi tidak membuktikan sebab-akibat; data agregat juga dapat menyembunyikan perbedaan antarkelompok.',
 'Bandingkan dua periode data kecil. Hitung perubahan absolut dan relatif, lalu tuliskan dua batasan yang mencegah kesimpulan berlebihan.',
 '["O*NET Resource Center","https://www.onetcenter.org/database.html","Contoh database pekerjaan dan keterampilan terstruktur untuk eksplorasi keterampilan; periksa catatan penggunaan dan atribusi pada data yang diunduh."]'),
 ('literasi-informasi-data-digital',2,2,'Menulis Ringkasan Berbasis Bukti',
 'Ringkasan yang baik menyatakan temuan utama, bukti, batasan, dan tindakan berikutnya.',
 'Menyusun ringkasan yang dapat ditelusuri dan membedakan temuan dari rekomendasi.',
 'Mulai dengan pertanyaan, rangkum temuan yang paling relevan, tautkan bukti, lalu nyatakan keterbatasan. Pisahkan apa yang data tunjukkan dari penjelasan yang masih berupa hipotesis. Rekomendasi harus sesuai kekuatan bukti dan memiliki cara untuk dievaluasi.',
 'Tulis ringkasan 150 kata dari satu tabel publik. Sertakan pertanyaan, dua temuan, satu batasan, dan satu langkah tindak lanjut.',
 '["ESCO — ESCO web-service API","https://esco.ec.europa.eu/en/use-esco/use-esco-services-api/esco-web-service-api","Contoh penggunaan data klasifikasi yang dapat ditelusuri untuk analisis keterampilan dan karier."]'),
 ('kesiapan-karier-portofolio-keterampilan',1,1,'Memahami Taksonomi Keterampilan',
 'Taksonomi membantu menggunakan istilah keterampilan secara konsisten, tetapi tidak otomatis membuktikan seseorang menguasainya.',
 'Menghubungkan keterampilan dengan tugas kerja, indikator perilaku, dan bukti yang relevan.',
 'Pahami perbedaan keterampilan, pengetahuan, tugas, dan jabatan. Gunakan kerangka seperti ESCO atau O*NET sebagai referensi, bukan label mutlak. Cocokkan definisi dengan konteks lokal dan kebutuhan peran. Satu nama keterampilan dapat mencakup beberapa tingkat kemahiran yang harus dijelaskan lewat contoh perilaku dan hasil.',
 'Pilih satu peran kerja. Cocokkan tiga keterampilan dengan tugas nyata, lalu tuliskan bukti yang dapat menunjukkan masing-masing keterampilan.',
 '["ESCO — Use ESCO","https://esco.ec.europa.eu/en/use-esco","Klasifikasi ESCO mendukung pemetaan keterampilan dan pekerjaan; verifikasi versi, definisi, dan lisensi sebelum impor data massal."]'),
 ('kesiapan-karier-portofolio-keterampilan',1,2,'Membuat Peta Kesenjangan Keterampilan',
 'Kesenjangan keterampilan adalah perbedaan antara kemampuan yang dibutuhkan dan bukti kemampuan yang dimiliki saat ini.',
 'Menyusun prioritas belajar berdasarkan tuntutan peran dan bukti yang tersedia.',
 'Pilih sasaran peran atau proyek, kumpulkan persyaratan dari beberapa sumber, lalu nilai bukti yang sudah dimiliki. Jangan menganggap tidak adanya bukti sebagai bukti ketidakmampuan. Prioritaskan keterampilan berdasarkan relevansi, tingkat kebutuhan, dan peluang latihan; tetapkan tindakan belajar yang terukur.',
 'Buat peta lima keterampilan: persyaratan, bukti yang ada, tingkat keyakinan, prioritas, dan aktivitas latihan berikutnya.',
 '["O*NET Resource Center","https://www.onetcenter.org/database.html","Sumber data pekerjaan dan keterampilan untuk eksplorasi awal; gunakan bersama sumber lowongan dan konteks lokal yang mutakhir."]'),
 ('kesiapan-karier-portofolio-keterampilan',2,1,'Portofolio Berbasis Bukti',
 'Portofolio menunjukkan proses, kontribusi, hasil, dan refleksi melalui artefak yang boleh dibagikan.',
 'Memilih bukti kerja yang relevan dan menjelaskan kontribusi tanpa membuka informasi rahasia.',
 'Untuk setiap artefak, jelaskan konteks, tujuan, peran pribadi, proses, hasil, dan pelajaran. Hapus informasi rahasia atau data pihak lain. Nyatakan kontribusi tim dengan akurat dan simpan izin untuk karya yang bukan milik sendiri. Portofolio yang baik menghubungkan bukti ke keterampilan tertentu tanpa mengklaim hasil yang tidak dapat dibuktikan.',
 'Buat satu studi kasus proyek dengan bagian konteks, peran, tindakan, hasil terukur, bukti yang dapat dibagikan, dan refleksi.',
 '["MIT OpenCourseWare — Get Started","https://ocw.mit.edu/pages/get-started/","MIT OCW menyediakan bahan belajar terbuka; sebagian besar berada di bawah CC BY-NC-SA dan dibatasi untuk penggunaan nonkomersial. Tautkan saja jika penggunaan komersial tidak sesuai lisensi."]'),
 ('kesiapan-karier-portofolio-keterampilan',2,2,'Rencana Pengembangan Diri 30 Hari',
 'Rencana belajar efektif menetapkan hasil, latihan, umpan balik, dan bukti kemajuan yang realistis.',
 'Membuat rencana 30 hari yang memiliki target, jadwal, dan evaluasi.',
 'Pilih satu keterampilan prioritas. Tetapkan hasil yang dapat diamati, latihan mingguan, sumber belajar, dan seseorang atau rubrik untuk memberi umpan balik. Lakukan latihan kecil, catat bukti, dan tinjau kemajuan setiap minggu. Ubah rencana bila bukti menunjukkan strategi tidak efektif.',
 'Buat rencana empat minggu dengan satu tujuan, dua sesi latihan per minggu, satu bukti hasil, dan satu refleksi mingguan.',
 '["UNESCO — AI competency framework for students","https://www.unesco.org/en/articles/ai-competency-framework-students","Kerangka kompetensi memberi contoh progresi belajar dari memahami, menerapkan, hingga mencipta; adaptasikan ke konteks keterampilan yang dipilih."]')
) AS v(course_slug,module_position,lesson_position,title,summary,objective,body,practice,exercise,sources)
JOIN public.courses c ON c.slug=v.course_slug
JOIN public.modules m ON m.course_id=c.id AND m.position=v.module_position
ON CONFLICT(module_id,position) DO UPDATE SET title=EXCLUDED.title,content=EXCLUDED.content;

COMMIT;
