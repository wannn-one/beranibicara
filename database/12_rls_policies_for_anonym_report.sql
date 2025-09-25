-- Hapus kebijakan INSERT yang lama
DROP POLICY IF EXISTS "Allow authenticated users to create reports" ON public.reports;

-- Buat kebijakan INSERT yang baru dan lebih pintar
CREATE POLICY "Allow users to create own or anonymous reports"
ON public.reports FOR INSERT
TO authenticated
WITH CHECK (
  -- Pengguna bisa membuat laporan jika mereka adalah pelapornya
  auth.uid() = reporter_id
  -- ATAU jika laporan tersebut adalah laporan anonim
  OR reporter_id IS NULL
);