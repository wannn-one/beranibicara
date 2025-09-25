-- Menambahkan kolom 'title' dengan tipe TEXT ke tabel reports
ALTER TABLE public.reports
ADD COLUMN title TEXT;

-- Memberi komentar/deskripsi pada kolom baru (praktik yang baik)
COMMENT ON COLUMN public.reports.title IS 'Judul singkat untuk laporan.';