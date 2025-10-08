-- =================================================================
-- FIX ALL RLS POLICIES - COMPREHENSIVE FIX
-- Ganti semua get_my_role() dengan pattern yang reliable
-- =================================================================

-- 1. FIX REPORTS RLS
DROP POLICY IF EXISTS "Allow TPPK members to view all reports" ON public.reports;
DROP POLICY IF EXISTS "Allow TPPK members to update all reports" ON public.reports;

CREATE POLICY "Allow TPPK members to view all reports"
ON public.reports FOR SELECT TO authenticated 
USING ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'tppk');

CREATE POLICY "Allow TPPK members to update all reports"
ON public.reports FOR UPDATE TO authenticated 
USING ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'tppk');

-- 2. FIX EVIDENCE RLS
DROP POLICY IF EXISTS "Allow users to view evidence for their reports or if TPPK" ON public.evidence;
DROP POLICY IF EXISTS "Allow TPPK members to delete evidence" ON public.evidence;

CREATE POLICY "Allow users to view evidence for their reports or if TPPK"
ON public.evidence FOR SELECT TO authenticated USING (
  (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'tppk'
  OR
  (EXISTS (
    SELECT 1 FROM public.reports
    WHERE reports.id = evidence.report_id AND reports.reporter_id = auth.uid()
  ))
);

CREATE POLICY "Allow TPPK members to delete evidence"
ON public.evidence FOR DELETE TO authenticated 
USING ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'tppk');

-- 3. FIX LOG PENANGANAN RLS
DROP POLICY IF EXISTS "Allow TPPK to view handling logs" ON public.log_penanganan;
DROP POLICY IF EXISTS "Allow TPPK to insert handling logs" ON public.log_penanganan;

CREATE POLICY "Allow TPPK to view handling logs"
ON public.log_penanganan FOR SELECT TO authenticated
USING ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'tppk');

CREATE POLICY "Allow TPPK to insert handling logs"
ON public.log_penanganan FOR INSERT TO authenticated
WITH CHECK ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'tppk');

-- 4. FIX BALASAN LAPORAN RLS
DROP POLICY IF EXISTS "Allow TPPK to create replies" ON public.balasan_laporan;
DROP POLICY IF EXISTS "Allow TPPK to view all replies" ON public.balasan_laporan;

CREATE POLICY "Allow TPPK to create replies"
ON public.balasan_laporan FOR INSERT TO authenticated
WITH CHECK ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'tppk');

CREATE POLICY "Allow TPPK to view all replies"
ON public.balasan_laporan FOR SELECT TO authenticated
USING ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'tppk');

-- 5. FIX SOCIALIZATION RLS
DROP POLICY IF EXISTS "Allow TPPK members to create socialization content" ON public.socialization;
DROP POLICY IF EXISTS "Allow TPPK members to update socialization content" ON public.socialization;
DROP POLICY IF EXISTS "Allow TPPK members to delete socialization content" ON public.socialization;

CREATE POLICY "Allow TPPK members to create socialization content"
ON public.socialization FOR INSERT TO authenticated 
WITH CHECK ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'tppk');

CREATE POLICY "Allow TPPK members to update socialization content"
ON public.socialization FOR UPDATE TO authenticated 
USING ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'tppk');

CREATE POLICY "Allow TPPK members to delete socialization content"
ON public.socialization FOR DELETE TO authenticated 
USING ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'tppk');

-- 6. FIX KELAS RLS
DROP POLICY IF EXISTS "Allow TPPK members to manage classes" ON public.kelas;

CREATE POLICY "Allow TPPK members to manage classes"
ON public.kelas FOR ALL TO authenticated
USING ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'tppk')
WITH CHECK ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'tppk');

-- Test query
SELECT 'All RLS policies fixed - no more get_my_role() issues!' as status;

-- =================================================================
-- SELESAI - COMPREHENSIVE RLS FIX
-- =================================================================
