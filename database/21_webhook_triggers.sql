-- =================================================================
-- ALTERNATIVE: WEBHOOK TRIGGERS UNTUK NOTIFIKASI FCM
-- File: 21_webhook_triggers.sql
-- =================================================================

-- APPROACH 1: Menggunakan supabase_functions.http_request (jika tersedia)
-- APPROACH 2: Menggunakan database webhooks di Supabase Dashboard

-- 1. TRIGGER UNTUK LAPORAN BARU (Updated)
CREATE OR REPLACE FUNCTION notify_new_report_v2()
RETURNS TRIGGER AS $$
DECLARE
  webhook_url text := 'https://hcifdgbwcacjsqzenjq.supabase.co/functions/v1/send-new-report-notification';
  payload jsonb;
  service_key text := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhjaWZkZ2J3Y2FjanNxemVuanEiLCJyb2xlIjoic2VydmljZV9yb2xlIiwiaWF0IjoxNzU4ODQ1Nzc2LCJleHAiOjIwNzQ0MjE3NzZ9.hJFQYUYCrKjHvG5GqUNlKnDLDfJIGqSWVTOtqIFCHvs';
BEGIN
  -- Prepare payload
  payload := jsonb_build_object(
    'type', 'INSERT',
    'table', 'reports',
    'record', to_jsonb(NEW),
    'schema', 'public'
  );

  -- Try using pg_net if available
  BEGIN
    PERFORM net.http_post(
      url := webhook_url,
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || service_key
      ),
      body := payload
    );
  EXCEPTION 
    WHEN OTHERS THEN
      -- Log error but don't fail the insert
      RAISE NOTICE 'Failed to call webhook: %', SQLERRM;
  END;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. TRIGGER UNTUK BALASAN BARU (Updated)
CREATE OR REPLACE FUNCTION notify_new_reply_v2()
RETURNS TRIGGER AS $$
DECLARE
  webhook_url text := 'https://hcifdgbwcacjsqzenjq.supabase.co/functions/v1/send-reply-notification';
  payload jsonb;
  service_key text := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhjaWZkZ2J3Y2FjanNxemVuanEiLCJyb2xlIjoic2VydmljZV9yb2xlIiwiaWF0IjoxNzU4ODQ1Nzc2LCJleHAiOjIwNzQ0MjE3NzZ9.hJFQYUYCrKjHvG5GqUNlKnDLDfJIGqSWVTOtqIFCHvs';
BEGIN
  -- Prepare payload
  payload := jsonb_build_object(
    'type', 'INSERT',
    'table', 'balasan_laporan',
    'record', to_jsonb(NEW),
    'schema', 'public'
  );

  -- Try using pg_net if available
  BEGIN
    PERFORM net.http_post(
      url := webhook_url,
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || service_key
      ),
      body := payload
    );
  EXCEPTION 
    WHEN OTHERS THEN
      -- Log error but don't fail the insert
      RAISE NOTICE 'Failed to call webhook: %', SQLERRM;
  END;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update triggers to use new functions
DROP TRIGGER IF EXISTS on_report_created ON public.reports;
CREATE TRIGGER on_report_created
  AFTER INSERT ON public.reports
  FOR EACH ROW
  EXECUTE FUNCTION notify_new_report_v2();

DROP TRIGGER IF EXISTS on_reply_created ON public.balasan_laporan;
CREATE TRIGGER on_reply_created
  AFTER INSERT ON public.balasan_laporan
  FOR EACH ROW
  EXECUTE FUNCTION notify_new_reply_v2();

-- =================================================================
-- NOTES:
-- 1. Ganti service_key dengan yang sebenarnya dari Supabase Dashboard
-- 2. Jika pg_net tidak tersedia, gunakan Database Webhooks di Supabase Dashboard
-- 3. Alternative: Panggil Edge Functions dari aplikasi Flutter langsung
-- ================================================================= 