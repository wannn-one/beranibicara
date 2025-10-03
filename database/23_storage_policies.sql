-- =================================================================
-- STORAGE POLICIES UNTUK BUCKET CERITA-IMAGES
-- =================================================================

-- 1. POLICY UNTUK UPLOAD (INSERT)
-- Hanya siswa dan admin yang bisa upload gambar untuk cerita
CREATE POLICY "Students and admins can upload story images" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'cerita-images'
        AND (
            (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'siswa'
            OR (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'tppk'
        )
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- 2. POLICY UNTUK VIEW/DOWNLOAD (SELECT)
-- Semua user yang bisa akses cerita kelas bisa lihat gambar
CREATE POLICY "Users can view story images in their class" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'cerita-images'
        AND (
            -- Admin bisa lihat semua
            (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'tppk'
            OR
            -- Siswa bisa lihat gambar cerita di kelas mereka
            (
                (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'siswa'
                AND EXISTS (
                    SELECT 1 FROM public.cerita_kelas ck
                    WHERE ck.gambar_url LIKE '%' || name || '%'
                    AND ck.kelas_id = (SELECT kelas_id FROM public.profiles WHERE id = auth.uid())
                )
            )
            OR
            -- Guru bisa lihat gambar cerita di kelas yang mereka wali
            (
                (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'guru'
                AND EXISTS (
                    SELECT 1 FROM public.cerita_kelas ck
                    JOIN public.kelas k ON ck.kelas_id = k.id
                    WHERE ck.gambar_url LIKE '%' || name || '%'
                    AND k.wali_kelas_id = auth.uid()
                )
            )
        )
    );

-- 3. POLICY UNTUK UPDATE
-- Hanya pemilik file dan admin yang bisa update
CREATE POLICY "Authors and admins can update their story images" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'cerita-images'
        AND (
            auth.uid()::text = (storage.foldername(name))[1]
            OR (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'tppk'
        )
    );

-- 4. POLICY UNTUK DELETE
-- Hanya pemilik file dan admin yang bisa delete
CREATE POLICY "Authors and admins can delete their story images" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'cerita-images'
        AND (
            auth.uid()::text = (storage.foldername(name))[1]
            OR (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'tppk'
        )
    );

-- =================================================================
-- ALTERNATIF SEDERHANA (Jika yang di atas kompleks)
-- =================================================================

-- Hapus policies di atas jika ingin pakai yang sederhana
-- DROP POLICY IF EXISTS "Students and admins can upload story images" ON storage.objects;
-- DROP POLICY IF EXISTS "Users can view story images in their class" ON storage.objects;
-- DROP POLICY IF EXISTS "Authors and admins can update their story images" ON storage.objects;
-- DROP POLICY IF EXISTS "Authors and admins can delete their story images" ON storage.objects;

-- Policy sederhana: Semua authenticated user bisa akses
-- CREATE POLICY "Authenticated users can access story images" ON storage.objects
--     FOR ALL USING (bucket_id = 'cerita-images' AND auth.role() = 'authenticated');

-- =================================================================
-- SELESAI - STORAGE POLICIES
-- =================================================================