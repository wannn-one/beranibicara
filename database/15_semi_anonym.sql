-- Hapus policy INSERT yang lama
DROP POLICY IF EXISTS "Allow users to create reports" ON public.reports;
DROP POLICY IF EXISTS "Allow users to create own or anonymous reports" ON public.reports;

-- Buat policy INSERT baru yang lebih sederhana untuk semi-anonim
CREATE POLICY "Allow authenticated users to create reports"
ON public.reports FOR INSERT
TO authenticated
WITH CHECK (
  -- Aturan satu-satunya: Pelapor harus sama dengan pengguna yang login.
  reporter_id = auth.uid()
);