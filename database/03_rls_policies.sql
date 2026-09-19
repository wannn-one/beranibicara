-- =================================================================
-- SKRIP KEBIJAKAN RLS LENGKAP UNTUK APLIKASI ANTI-BULLYING
-- File: rls_policies.sql
-- =================================================================

-- -----------------------------------------------------------------
-- 1. FUNGSI BANTUAN (HELPER FUNCTION)
-- Fungsi ini harus dibuat pertama kali karena akan digunakan oleh kebijakan lain.
-- -----------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN (
    SELECT role::text FROM public.profiles WHERE id = auth.uid()
  );
END;
$$;


-- -----------------------------------------------------------------
-- 2. Kebijakan untuk Tabel 'profiles'
-- -----------------------------------------------------------------

DROP POLICY IF EXISTS "Allow authenticated users to view all profiles" ON public.profiles;
CREATE POLICY "Allow authenticated users to view all profiles"
ON public.profiles FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Allow users to update their own profile" ON public.profiles;
CREATE POLICY "Allow users to update their own profile"
ON public.profiles FOR UPDATE TO authenticated USING (auth.uid() = id);


-- -----------------------------------------------------------------
-- 3. Kebijakan untuk Tabel 'reports'
-- -----------------------------------------------------------------

DROP POLICY IF EXISTS "Allow authenticated users to create reports" ON public.reports;
CREATE POLICY "Allow authenticated users to create reports"
ON public.reports FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "Allow users to view their own reports" ON public.reports;
CREATE POLICY "Allow users to view their own reports"
ON public.reports FOR SELECT TO authenticated USING (auth.uid() = reporter_id);

DROP POLICY IF EXISTS "Allow TPPK members to view all reports" ON public.reports;
CREATE POLICY "Allow TPPK members to view all reports"
ON public.reports FOR SELECT TO authenticated USING (get_my_role() = 'tppk');

DROP POLICY IF EXISTS "Allow TPPK members to update all reports" ON public.reports;
CREATE POLICY "Allow TPPK members to update all reports"
ON public.reports FOR UPDATE TO authenticated
USING (get_my_role() IN ('tppk', 'admin'))
WITH CHECK (get_my_role() IN ('tppk', 'admin'));

DROP POLICY IF EXISTS "Allow reporters to update own reports" ON public.reports;
CREATE POLICY "Allow reporters to update own reports"
ON public.reports FOR UPDATE TO authenticated
USING (auth.uid() = reporter_id)
WITH CHECK (auth.uid() = reporter_id);


-- -----------------------------------------------------------------
-- 4. Kebijakan untuk Tabel 'evidence'
-- -----------------------------------------------------------------

DROP POLICY IF EXISTS "Allow authenticated users to insert evidence" ON public.evidence;
CREATE POLICY "Allow authenticated users to insert evidence"
ON public.evidence FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "Allow users to view evidence for their reports or if TPPK" ON public.evidence;
CREATE POLICY "Allow users to view evidence for their reports or if TPPK"
ON public.evidence FOR SELECT TO authenticated USING (
  (get_my_role() = 'tppk') OR
  (EXISTS (
    SELECT 1 FROM public.reports
    WHERE reports.id = evidence.report_id AND reports.reporter_id = auth.uid()
  ))
);

DROP POLICY IF EXISTS "Allow TPPK members to delete evidence" ON public.evidence;
CREATE POLICY "Allow TPPK members to delete evidence"
ON public.evidence FOR DELETE TO authenticated USING (get_my_role() = 'tppk');


-- -----------------------------------------------------------------
-- 5. Kebijakan untuk Tabel 'socialization'
-- -----------------------------------------------------------------

DROP POLICY IF EXISTS "Allow authenticated users to view socialization content" ON public.socialization;
CREATE POLICY "Allow authenticated users to view socialization content"
ON public.socialization FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Allow TPPK members to create socialization content" ON public.socialization;
CREATE POLICY "Allow TPPK members to create socialization content"
ON public.socialization FOR INSERT TO authenticated WITH CHECK (get_my_role() = 'tppk');

DROP POLICY IF EXISTS "Allow TPPK members to update socialization content" ON public.socialization;
CREATE POLICY "Allow TPPK members to update socialization content"
ON public.socialization FOR UPDATE TO authenticated USING (get_my_role() = 'tppk');

DROP POLICY IF EXISTS "Allow TPPK members to delete socialization content" ON public.socialization;
CREATE POLICY "Allow TPPK members to delete socialization content"
ON public.socialization FOR DELETE TO authenticated USING (get_my_role() = 'tppk');


-- -----------------------------------------------------------------
-- 6. Kebijakan untuk Tabel 'kelas'
-- -----------------------------------------------------------------

DROP POLICY IF EXISTS "Allow authenticated users to view classes" ON public.kelas;
CREATE POLICY "Allow authenticated users to view classes"
ON public.kelas FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Allow TPPK members to manage classes" ON public.kelas;
CREATE POLICY "Allow TPPK members to manage classes"
ON public.kelas FOR ALL -- 'ALL' mencakup INSERT, UPDATE, DELETE
TO authenticated
USING (get_my_role() = 'tppk')
WITH CHECK (get_my_role() = 'tppk');

-- =================================================================
-- KONFIGURASI KEAMANAN SELESAI
-- 
-- NOTE: Additional RLS policies for new tables are in 12_optimize_rls.sql:
-- - log_penanganan
-- - balasan_laporan
-- - cerita_kelas
-- - tanggapan_cerita
-- - device_tokens (replaces old 'notifications' table)
-- - notification_history
-- - audit_log
-- - nisn_registry
-- - user_deletion_log
-- =================================================================

CREATE POLICY "Allow homeroom teachers to view their students' reports"
ON public.reports FOR SELECT TO authenticated USING (
  EXISTS (
    SELECT 1 
    FROM public.profiles AS reporter
    JOIN public.kelas AS k ON reporter.kelas_id = k.id
    WHERE reporter.id = reports.reporter_id
    AND k.wali_kelas_id = auth.uid()
  )
);

CREATE POLICY "Allow admin to view all reports"
ON public.reports FOR SELECT TO authenticated USING (
  get_my_role() = 'admin'
);