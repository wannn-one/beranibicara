-- =================================================================
-- COMPLETE SEMI-ANONYMOUS REPORTS POLICY
-- File: 16_complete_semi_anonym_policy.sql
-- =================================================================

-- STEP 1: Hapus semua policy lama untuk reports
DROP POLICY IF EXISTS "Allow authenticated users to create reports" ON public.reports;
DROP POLICY IF EXISTS "Allow users to create reports" ON public.reports;
DROP POLICY IF EXISTS "Allow users to create own or anonymous reports" ON public.reports;
DROP POLICY IF EXISTS "Allow users to view their own reports" ON public.reports;

-- STEP 2: Buat policy INSERT untuk semi-anonim
-- Mengizinkan user membuat laporan dengan reporter_id = auth.uid()
-- baik untuk laporan anonim (is_anonymous = true) maupun biasa (is_anonymous = false)
CREATE POLICY "Allow users to create reports"
ON public.reports FOR INSERT
TO authenticated
WITH CHECK (
  -- Pelapor harus sama dengan pengguna yang login (untuk tracking & reply)
  reporter_id = auth.uid()
);

-- STEP 3: Buat policy SELECT untuk semi-anonim
-- Mengizinkan user melihat semua laporan mereka sendiri
-- termasuk yang anonim (karena mereka tetap perlu bisa track & terima reply)
CREATE POLICY "Allow users to view their own reports"
ON public.reports FOR SELECT
TO authenticated
USING (
  -- User bisa melihat semua laporan yang mereka buat
  -- baik anonim maupun tidak anonim
  reporter_id = auth.uid()
);

-- Note: Policy untuk TPPK sudah ada terpisah dan tidak berubah
-- TPPK tetap bisa melihat semua laporan, tapi nama pelapor akan ditampilkan "Anonim" 
-- di UI jika is_anonymous = true

-- =================================================================
-- TESTING QUERY
-- =================================================================

-- Test 1: Insert laporan biasa
-- INSERT INTO reports (title, description, is_anonymous, reporter_id)
-- VALUES ('Laporan Biasa', 'Ini laporan biasa', false, auth.uid());

-- Test 2: Insert laporan anonim (dengan reporter_id tetap ada untuk tracking)
-- INSERT INTO reports (title, description, is_anonymous, reporter_id)
-- VALUES ('Laporan Anonim', 'Ini laporan anonim', true, auth.uid());

-- Test 3: Select laporan user (harus bisa lihat keduanya)
-- SELECT id, title, is_anonymous, reporter_id FROM reports WHERE reporter_id = auth.uid(); 