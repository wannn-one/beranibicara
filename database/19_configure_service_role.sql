-- =================================================================
-- KONFIGURASI SERVICE ROLE KEY UNTUK DATABASE TRIGGERS
-- File: 19_configure_service_role.sql
-- =================================================================

-- Set service role key untuk digunakan oleh database triggers
-- GANTI DENGAN SERVICE ROLE KEY YANG SEBENARNYA DARI SUPABASE DASHBOARD
ALTER DATABASE postgres SET "app.settings.service_role_key" TO 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhjaWZkZ2J3Y2FjanNxemVuanEiLCJyb2xlIjoic2VydmljZV9yb2xlIiwiaWF0IjoxNzU4ODQ1Nzc2LCJleHAiOjIwNzQ0MjE3NzZ9.YOUR_ACTUAL_SERVICE_ROLE_KEY_HERE';

-- =================================================================
-- PENTING: 
-- 1. Ganti 'YOUR_ACTUAL_SERVICE_ROLE_KEY_HERE' dengan service role key yang sebenarnya
-- 2. Service role key bisa didapat dari Supabase Dashboard > Settings > API
-- 3. Pastikan menggunakan SERVICE ROLE KEY, bukan anon key
-- ================================================================= 