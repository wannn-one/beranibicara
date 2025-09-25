ALTER TABLE public.socialization
ADD COLUMN cover_image_url TEXT;

COMMENT ON COLUMN public.socialization.cover_image_url IS 'URL ke gambar utama/cover untuk artikel edukasi.';