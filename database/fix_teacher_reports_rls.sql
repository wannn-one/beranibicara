-- =================================================================
-- FIX TEACHER REPORTS RLS POLICY
-- Perbaiki policy agar guru bisa melihat laporan siswa di kelasnya
-- =================================================================

-- Drop policy lama yang menggunakan get_my_role()
DROP POLICY IF EXISTS "Allow teachers to view reports from their class" ON public.reports;

-- Buat policy baru dengan pattern yang lebih reliable
CREATE POLICY "Allow teachers to view reports from their class"
ON public.reports FOR SELECT
TO authenticated
USING (
  -- Kondisi 1: Pengguna harus seorang guru (menggunakan direct query ke profiles)
  (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'guru'
  
  -- Kondisi 2: Laporan tidak boleh anonim (guru hanya bisa lihat laporan non-anonim)
  AND is_anonymous = false
  
  -- Kondisi 3: Siswa pelapor harus berada di kelas yang diampu oleh guru ini
  AND (
    (SELECT p.kelas_id FROM public.profiles p WHERE p.id = reports.reporter_id) 
    = 
    (SELECT k.id FROM public.kelas k WHERE k.wali_kelas_id = auth.uid())
  )
);

-- Tambahkan policy untuk guru melihat laporan anonim juga (untuk tracking internal)
-- Tapi tetap tidak bisa melihat identitas pelapor
CREATE POLICY "Allow teachers to view anonymous reports from their class"
ON public.reports FOR SELECT
TO authenticated
USING (
  -- Kondisi 1: Pengguna harus seorang guru
  (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'guru'
  
  -- Kondisi 2: Laporan adalah anonim
  AND is_anonymous = true
  
  -- Kondisi 3: Siswa pelapor harus berada di kelas yang diampu oleh guru ini
  AND (
    (SELECT p.kelas_id FROM public.profiles p WHERE p.id = reports.reporter_id) 
    = 
    (SELECT k.id FROM public.kelas k WHERE k.wali_kelas_id = auth.uid())
  )
);

-- Verifikasi policy sudah dibuat
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'reports' AND policyname LIKE '%teacher%';
