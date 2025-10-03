-- =================================================================
-- AKTIFKAN PG_NET EXTENSION UNTUK HTTP CALLS
-- File: 20_enable_net_extension.sql
-- =================================================================

-- Enable pg_net extension untuk net.http_post()
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Verifikasi extension sudah aktif
SELECT * FROM pg_extension WHERE extname = 'pg_net';

-- =================================================================
-- SELESAI
-- ================================================================= 