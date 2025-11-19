-- Migration: Add RPC function to delete a report and all related data

CREATE OR REPLACE FUNCTION public.delete_report_completely(
  report_id_to_delete bigint
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Only allow TPPK to delete reports
  IF (SELECT role FROM public.profiles WHERE id = auth.uid()) != 'tppk' THEN
    RAISE EXCEPTION 'Only TPPK can delete reports';
  END IF;

  -- Delete from related tables first
  DELETE FROM public.evidence WHERE report_id = report_id_to_delete;
  DELETE FROM public.log_penanganan WHERE report_id = report_id_to_delete;
  DELETE FROM public.balasan_laporan WHERE report_id = report_id_to_delete;

  -- Finally, delete the report itself
  DELETE FROM public.reports WHERE id = report_id_to_delete;
END;
$$;
