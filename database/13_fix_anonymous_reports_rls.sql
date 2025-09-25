-- =================================================================
-- FIX ANONYMOUS REPORTS RLS POLICY
-- File: 13_fix_anonymous_reports_rls.sql
-- Tanggal: 25 September 2025
-- =================================================================

-- Masalah: Laporan anonim tidak bisa dibuat karena RLS policy terlalu ketat
-- Solusi: Update policy INSERT untuk mengizinkan laporan anonim

-- 1. Hapus policy INSERT yang lama
DROP POLICY IF EXISTS "Allow authenticated users to create reports" ON public.reports;
DROP POLICY IF EXISTS "Allow users to create own or anonymous reports" ON public.reports;

-- 2. Buat policy INSERT yang baru dengan logika yang benar
CREATE POLICY "Allow users to create reports"
ON public.reports FOR INSERT
TO authenticated
WITH CHECK (
  -- Kasus 1: Laporan NON-ANONIM - reporter_id harus sama dengan user yang login
  (is_anonymous = false AND reporter_id = auth.uid())
  OR
  -- Kasus 2: Laporan ANONIM - reporter_id harus NULL dan is_anonymous = true
  (is_anonymous = true AND reporter_id IS NULL)
);

-- 3. Update policy SELECT untuk memastikan user hanya bisa lihat laporan mereka sendiri
-- (bukan laporan anonim, karena itu melanggar prinsip anonimitas)
DROP POLICY IF EXISTS "Allow users to view their own reports" ON public.reports;
CREATE POLICY "Allow users to view their own reports"
ON public.reports FOR SELECT
TO authenticated
USING (
  -- User hanya bisa melihat laporan NON-ANONIM yang mereka buat
  is_anonymous = false AND reporter_id = auth.uid()
);

-- Note: Policy untuk TPPK sudah ada dan tidak perlu diubah
-- TPPK tetap bisa melihat semua laporan (termasuk anonim) melalui policy terpisah

-- =================================================================
-- TESTING QUERY (opsional, untuk memverifikasi)
-- =================================================================

-- Test 1: Cek apakah user bisa insert laporan biasa
-- INSERT INTO reports (title, description, reporter_id, is_anonymous) 
-- VALUES ('Test Normal', 'Test description', auth.uid(), false);

-- Test 2: Cek apakah user bisa insert laporan anonim  
-- INSERT INTO reports (title, description, reporter_id, is_anonymous)
-- VALUES ('Test Anonim', 'Test description', NULL, true);

-- Test 3: Cek apakah user hanya bisa lihat laporan mereka sendiri (bukan anonim)
-- SELECT * FROM reports WHERE reporter_id = auth.uid(); 