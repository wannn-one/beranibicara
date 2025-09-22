CREATE OR REPLACE FUNCTION get_report_status_counts()
RETURNS TABLE(status TEXT, total BIGINT) AS $$
BEGIN
  RETURN QUERY
  SELECT r.status::TEXT, COUNT(*) as total
  FROM public.reports r
  GROUP BY r.status;
END;
$$ LANGUAGE plpgsql;