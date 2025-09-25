CREATE OR REPLACE FUNCTION create_new_report(
  title TEXT,
  description TEXT,
  is_anonymous BOOLEAN,
  evidence_urls TEXT[]
)
RETURNS void AS $$
DECLARE
  new_report_id BIGINT;
BEGIN
  -- Insert ke tabel reports, dan dapatkan ID laporan yang baru dibuat
  INSERT INTO public.reports (title, description, is_anonymous, reporter_id)
  VALUES (
    title,
    description,
    is_anonymous,
    CASE WHEN is_anonymous THEN NULL ELSE auth.uid() END
  ) RETURNING id INTO new_report_id;

  -- Jika ada URL bukti, insert ke tabel evidence
  IF array_length(evidence_urls, 1) > 0 THEN
    FOR i IN 1..array_length(evidence_urls, 1) LOOP
      INSERT INTO public.evidence (report_id, file_url, file_type)
      VALUES (new_report_id, evidence_urls[i], 'image/jpeg');
    END LOOP;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;