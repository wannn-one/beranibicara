-- FUNGSI UNTUK MEMBUAT PROFIL BARU SECARA OTOMATIS
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, role)
  VALUES (
    new.id,
    new.raw_user_meta_data->>'full_name',
    CASE
      WHEN lower(coalesce(new.raw_user_meta_data->>'role', 'siswa')) = 'guru'
        THEN 'guru'::user_role
      ELSE 'siswa'::user_role
    END
  );
  RETURN new;
END;
$$;


-- TRIGGER YANG MEMANGGIL FUNGSI DI ATAS SETIAP ADA USER BARU
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();