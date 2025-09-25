-- KEBIJAKAN 1 (DIPERBARUI): Mengizinkan HANYA TPPK untuk MEMBACA semua log
DROP POLICY IF EXISTS "Allow TPPK and Teachers to view handling logs" ON public.log_penanganan;
CREATE POLICY "Allow TPPK to view handling logs" -- Nama diubah agar lebih akurat
ON public.log_penanganan FOR SELECT
TO authenticated
USING (
  get_my_role() = 'tppk' -- Dihapus 'guru' dari kondisi
);


-- KEBIJAKAN 2 (TETAP SAMA): Mengizinkan HANYA TPPK untuk MENAMBAH log baru
DROP POLICY IF EXISTS "Allow TPPK to insert handling logs" ON public.log_penanganan;
CREATE POLICY "Allow TPPK to insert handling logs"
ON public.log_penanganan FOR INSERT
TO authenticated
WITH CHECK (
  get_my_role() = 'tppk'
);