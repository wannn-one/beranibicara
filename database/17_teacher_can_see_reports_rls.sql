-- KEBIJAKAN BARU: Mengizinkan Wali Kelas melihat laporan non-anonim dari kelasnya
CREATE POLICY "Allow teachers to view reports from their class"
ON public.reports FOR SELECT
TO authenticated
USING (
  -- Kondisi 1: Pengguna harus seorang guru
  get_my_role() = 'guru'
  
  -- Kondisi 2: Laporan tidak boleh anonim
  AND is_anonymous = false
  
  -- Kondisi 3: Siswa pelapor harus berada di kelas yang diampu oleh guru ini
  AND (
    (SELECT p.kelas_id FROM public.profiles p WHERE p.id = reports.reporter_id) 
    = 
    (SELECT k.id FROM public.kelas k WHERE k.wali_kelas_id = auth.uid())
  )
);