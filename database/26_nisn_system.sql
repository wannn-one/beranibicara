-- =================================================================
-- NISN (Nomor Induk Siswa Nasional) System
-- =================================================================
-- Migration untuk menambahkan sistem login dengan NISN
-- Siswa dapat login dengan email/password ATAU NISN/password

-- =================================================================
-- 1. CREATE NISN REGISTRY TABLE
-- =================================================================

-- Table untuk menyimpan daftar NISN valid yang diinput oleh admin
CREATE TABLE public.nisn_registry (
  nisn TEXT PRIMARY KEY CHECK (char_length(nisn) = 10),
  nama_siswa TEXT NOT NULL,
  tingkat INT CHECK (tingkat BETWEEN 1 AND 6),
  jurusan TEXT,
  is_registered BOOLEAN DEFAULT FALSE,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  registered_at TIMESTAMPTZ
);

COMMENT ON TABLE public.nisn_registry IS 'Registry of valid NISN that can be used for student registration';
COMMENT ON COLUMN public.nisn_registry.nisn IS 'Student National ID Number (10 digits)';
COMMENT ON COLUMN public.nisn_registry.nama_siswa IS 'Student name';
COMMENT ON COLUMN public.nisn_registry.is_registered IS 'Whether this NISN has been registered by a student';
COMMENT ON COLUMN public.nisn_registry.user_id IS 'User ID if NISN has been registered';

-- Add indexes for fast lookup
CREATE INDEX idx_nisn_registry_user_id ON public.nisn_registry(user_id);
CREATE INDEX idx_nisn_registry_is_registered ON public.nisn_registry(is_registered);

-- =================================================================
-- 2. ADD NISN COLUMN TO PROFILES TABLE
-- =================================================================

-- Add NISN column to profiles (nullable, unique)
ALTER TABLE public.profiles 
ADD COLUMN nisn TEXT UNIQUE CHECK (nisn IS NULL OR char_length(nisn) = 10);

COMMENT ON COLUMN public.profiles.nisn IS 'Student NISN if registered with NISN';

-- Add index for fast lookup
CREATE INDEX idx_profiles_nisn ON public.profiles(nisn);

-- =================================================================
-- 3. CREATE FUNCTIONS
-- =================================================================

-- Function untuk admin menambah NISN ke registry
CREATE OR REPLACE FUNCTION add_nisn_to_registry(
  nisn_input TEXT,
  nama_siswa_input TEXT,
  tingkat_input INT,
  jurusan_input TEXT
) RETURNS void AS $$
BEGIN
  INSERT INTO public.nisn_registry (nisn, nama_siswa, tingkat, jurusan)
  VALUES (nisn_input, nama_siswa_input, tingkat_input, jurusan_input)
  ON CONFLICT (nisn) DO UPDATE 
  SET nama_siswa = nama_siswa_input, 
      tingkat = tingkat_input, 
      jurusan = jurusan_input;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION add_nisn_to_registry IS 'Admin function to add or update NISN in registry';

-- Function untuk cek NISN valid dan belum terdaftar
CREATE OR REPLACE FUNCTION check_nisn_available(nisn_input TEXT)
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_build_object(
    'is_valid', CASE WHEN nisn IS NOT NULL THEN true ELSE false END,
    'is_registered', COALESCE(is_registered, false),
    'nama_siswa', nama_siswa,
    'tingkat', tingkat,
    'jurusan', jurusan
  ) INTO result
  FROM public.nisn_registry
  WHERE nisn = nisn_input;
  
  IF result IS NULL THEN
    result := json_build_object(
      'is_valid', false, 
      'is_registered', false,
      'nama_siswa', null,
      'tingkat', null,
      'jurusan', null
    );
  END IF;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION check_nisn_available IS 'Check if NISN is valid and available for registration';

-- Function untuk bulk insert NISN dari CSV
CREATE OR REPLACE FUNCTION bulk_add_nisn(
  nisn_data JSON[]
) RETURNS JSON AS $$
DECLARE
  item JSON;
  success_count INT := 0;
  error_count INT := 0;
BEGIN
  FOREACH item IN ARRAY nisn_data LOOP
    BEGIN
      INSERT INTO public.nisn_registry (nisn, nama_siswa, tingkat, jurusan)
      VALUES (
        item->>'nisn',
        item->>'nama_siswa',
        (item->>'tingkat')::INT,
        item->>'jurusan'
      )
      ON CONFLICT (nisn) DO UPDATE 
      SET nama_siswa = EXCLUDED.nama_siswa,
          tingkat = EXCLUDED.tingkat,
          jurusan = EXCLUDED.jurusan;
      
      success_count := success_count + 1;
    EXCEPTION WHEN OTHERS THEN
      error_count := error_count + 1;
    END;
  END LOOP;
  
  RETURN json_build_object(
    'success_count', success_count,
    'error_count', error_count
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION bulk_add_nisn IS 'Bulk insert NISN from CSV upload';

-- Function untuk validasi NISN di server (SECURITY)
CREATE OR REPLACE FUNCTION validate_nisn_registration(
  nisn_input TEXT,
  user_email TEXT
) RETURNS BOOLEAN AS $$
BEGIN
  -- Cek apakah NISN valid dan available
  IF NOT EXISTS (
    SELECT 1 FROM nisn_registry 
    WHERE nisn = nisn_input 
    AND is_registered = FALSE
  ) THEN
    RAISE EXCEPTION 'NISN tidak valid atau sudah terdaftar: %', nisn_input;
  END IF;
  
  -- Cek apakah email sudah terdaftar
  IF EXISTS (
    SELECT 1 FROM auth.users 
    WHERE email = user_email
  ) THEN
    RAISE EXCEPTION 'Email sudah terdaftar: %', user_email;
  END IF;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION validate_nisn_registration IS 'Server-side validation untuk registrasi NISN - mencegah bypass client validation';

-- =================================================================
-- 4. UPDATE HANDLE_NEW_USER FUNCTION
-- =================================================================

-- Update function untuk handle registrasi dengan NISN
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  user_nisn TEXT;
BEGIN
  -- Extract NISN from metadata jika ada
  user_nisn := new.raw_user_meta_data->>'nisn';
  
  -- Create profile
  INSERT INTO public.profiles (id, full_name, role, nisn)
  VALUES (
    new.id, 
    new.raw_user_meta_data->>'full_name', 
    'siswa',
    user_nisn
  );
  
  -- Update nisn_registry jika NISN digunakan
  IF user_nisn IS NOT NULL THEN
    UPDATE public.nisn_registry
    SET is_registered = TRUE, 
        user_id = new.id,
        registered_at = now()
    WHERE nisn = user_nisn;
  END IF;
  
  RETURN new;
END;
$$;

-- =================================================================
-- 5. ROW LEVEL SECURITY POLICIES
-- =================================================================

ALTER TABLE public.nisn_registry ENABLE ROW LEVEL SECURITY;

-- Admin (TPPK) dapat melihat dan mengelola semua NISN
CREATE POLICY "Admin dapat mengelola NISN registry"
  ON public.nisn_registry FOR ALL
  USING (public.get_my_role() = 'tppk');

-- Guru dapat melihat semua NISN (read-only)
CREATE POLICY "Guru dapat melihat NISN registry"
  ON public.nisn_registry FOR SELECT
  USING (public.get_my_role() = 'guru');

-- Siswa hanya bisa melihat NISN mereka sendiri
CREATE POLICY "Siswa dapat melihat NISN sendiri"
  ON public.nisn_registry FOR SELECT
  USING (user_id = auth.uid());

-- Public dapat cek NISN available (untuk registrasi)
-- Hanya menampilkan is_registered dan nama untuk validasi
CREATE POLICY "Public dapat cek NISN untuk registrasi"
  ON public.nisn_registry FOR SELECT
  USING (true);

-- =================================================================
-- GRANT PERMISSIONS
-- =================================================================

-- Grant execute permission on functions
GRANT EXECUTE ON FUNCTION add_nisn_to_registry TO authenticated;
GRANT EXECUTE ON FUNCTION check_nisn_available TO anon, authenticated;
GRANT EXECUTE ON FUNCTION bulk_add_nisn TO authenticated;

