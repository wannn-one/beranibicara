-- =================================================================
-- DATABASE TRIGGERS UNTUK NOTIFIKASI FCM
-- File: 18_notification_triggers.sql
-- =================================================================

-- 1. TRIGGER UNTUK LAPORAN BARU
-- Ketika ada laporan baru di tabel 'reports', panggil Edge Function
CREATE OR REPLACE FUNCTION notify_new_report()
RETURNS TRIGGER AS $$
BEGIN
  -- Panggil Edge Function send-new-report-notification
  PERFORM
    net.http_post(
      url := 'https://hcifdgbwcacjsqzenjq.supabase.co/functions/v1/send-new-report-notification',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true)
      ),
      body := jsonb_build_object(
        'type', 'INSERT',
        'table', 'reports',
        'record', to_jsonb(NEW),
        'schema', 'public'
      )
    );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Buat trigger yang memanggil function di atas
DROP TRIGGER IF EXISTS on_report_created ON public.reports;
CREATE TRIGGER on_report_created
  AFTER INSERT ON public.reports
  FOR EACH ROW
  EXECUTE FUNCTION notify_new_report();


-- 2. TRIGGER UNTUK BALASAN BARU
-- Ketika ada balasan baru di tabel 'balasan_laporan', panggil Edge Function
CREATE OR REPLACE FUNCTION notify_new_reply()
RETURNS TRIGGER AS $$
BEGIN
  -- Panggil Edge Function send-reply-notification
  PERFORM
    net.http_post(
      url := 'https://hcifdgbwcacjsqzenjq.supabase.co/functions/v1/send-reply-notification',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true)
      ),
      body := jsonb_build_object(
        'type', 'INSERT',
        'table', 'balasan_laporan',
        'record', to_jsonb(NEW),
        'schema', 'public'
      )
    );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Buat trigger yang memanggil function di atas
DROP TRIGGER IF EXISTS on_reply_created ON public.balasan_laporan;
CREATE TRIGGER on_reply_created
  AFTER INSERT ON public.balasan_laporan
  FOR EACH ROW
  EXECUTE FUNCTION notify_new_reply();

-- =================================================================
-- SELESAI
-- ================================================================= 