-- =================================================================
-- DATABASE SCHEMA INITIALIZATION
-- File: 01_init.sql
-- Description: Creates all tables for the Berani Bicara application
-- Prerequisites: 00_types.sql must be run first to create enum types
-- =================================================================

-- NOTE: Tables are created in dependency order to avoid FK errors
-- Step 1: Create tables WITHOUT circular FKs
-- Step 2: Add circular FKs with ALTER TABLE
-- Run 00_types.sql BEFORE running this file

-- =================================================================
-- STEP 1: CREATE STANDALONE TABLES (No dependencies)
-- =================================================================

-- Table: kelas (standalone - FK will be added later)
CREATE TABLE public.kelas (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  tingkat integer NOT NULL,
  jurusan text NOT NULL,
  wali_kelas_id uuid, -- FK will be added after profiles is created
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT kelas_pkey PRIMARY KEY (id),
  CONSTRAINT kelas_tingkat_jurusan_key UNIQUE(tingkat, jurusan)
);

-- Table: nisn_registry (depends only on auth.users)
CREATE TABLE public.nisn_registry (
  nisn text NOT NULL CHECK (char_length(nisn) = 10),
  nama_siswa text NOT NULL,
  tingkat integer CHECK (tingkat >= 1 AND tingkat <= 6),
  jurusan text,
  is_registered boolean DEFAULT false,
  user_id uuid,
  created_at timestamp with time zone DEFAULT now(),
  registered_at timestamp with time zone,
  CONSTRAINT nisn_registry_pkey PRIMARY KEY (nisn),
  CONSTRAINT nisn_registry_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);

-- =================================================================
-- STEP 2: CREATE PROFILES TABLE (depends on kelas and auth.users)
-- =================================================================

-- Table: profiles (circular deps with kelas - some FKs added later)
CREATE TABLE public.profiles (
  id uuid NOT NULL,
  full_name text,
  role user_role NOT NULL DEFAULT 'siswa'::user_role,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  kelas_id bigint, -- FK will be added after table is created
  status user_status NOT NULL DEFAULT 'aktif'::user_status,
  blocked_until timestamp with time zone,
  blocked_reason text,
  blocked_by uuid, -- Self-reference FK will be added later
  blocked_at timestamp with time zone,
  nisn text UNIQUE CHECK (nisn IS NULL OR char_length(nisn) = 10),
  CONSTRAINT profiles_pkey PRIMARY KEY (id),
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
);

-- =================================================================
-- STEP 3: ADD CIRCULAR FOREIGN KEYS
-- =================================================================

-- Add profiles -> kelas FK
ALTER TABLE public.profiles 
  ADD CONSTRAINT profiles_kelas_id_fkey 
  FOREIGN KEY (kelas_id) REFERENCES public.kelas(id);

-- Add profiles -> profiles FK (self-reference)
ALTER TABLE public.profiles 
  ADD CONSTRAINT profiles_blocked_by_fkey 
  FOREIGN KEY (blocked_by) REFERENCES public.profiles(id);

-- Add kelas -> profiles FK
ALTER TABLE public.kelas 
  ADD CONSTRAINT kelas_wali_kelas_id_fkey 
  FOREIGN KEY (wali_kelas_id) REFERENCES public.profiles(id);

-- =================================================================
-- STEP 4: CREATE DEPENDENT TABLES (Level 2 - depend on profiles)
-- =================================================================

-- Table: reports (depends on profiles)
CREATE TABLE public.reports (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  reporter_id uuid,
  description text NOT NULL CHECK (char_length(description) > 10),
  status report_status NOT NULL DEFAULT 'baru'::report_status,
  is_anonymous boolean NOT NULL DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  title text,
  CONSTRAINT reports_pkey PRIMARY KEY (id),
  CONSTRAINT reports_reporter_id_fkey FOREIGN KEY (reporter_id) REFERENCES public.profiles(id)
);

-- Table: notifications (depends on profiles) - Will be replaced by device_tokens
CREATE TABLE public.notifications (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  user_id uuid NOT NULL,
  fcm_token text NOT NULL UNIQUE,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT notifications_pkey PRIMARY KEY (id),
  CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);

-- Table: socialization (depends on profiles)
CREATE TABLE public.socialization (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  author_id uuid NOT NULL,
  title text NOT NULL,
  content text NOT NULL,
  published_at timestamp with time zone DEFAULT now(),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  cover_image_url text,
  CONSTRAINT socialization_pkey PRIMARY KEY (id),
  CONSTRAINT socialization_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.profiles(id)
);

-- Table: cerita_kelas (depends on profiles and kelas)
CREATE TABLE public.cerita_kelas (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  author_id uuid NOT NULL,
  kelas_id bigint NOT NULL,
  judul text NOT NULL CHECK (char_length(judul) >= 3 AND char_length(judul) <= 200),
  konten text NOT NULL CHECK (char_length(konten) >= 10),
  gambar_url text,
  is_published boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT cerita_kelas_pkey PRIMARY KEY (id),
  CONSTRAINT cerita_kelas_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.profiles(id),
  CONSTRAINT cerita_kelas_kelas_id_fkey FOREIGN KEY (kelas_id) REFERENCES public.kelas(id)
);

-- Table: user_deletion_log (depends on profiles)
CREATE TABLE public.user_deletion_log (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  deleted_user_id uuid NOT NULL,
  deleted_user_name text NOT NULL,
  deleted_user_email text,
  deleted_by uuid,
  deletion_reason text NOT NULL,
  deleted_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT user_deletion_log_pkey PRIMARY KEY (id),
  CONSTRAINT user_deletion_log_deleted_by_fkey FOREIGN KEY (deleted_by) REFERENCES public.profiles(id)
);

-- =================================================================
-- STEP 5: CREATE DEEPLY NESTED TABLES (Level 3+)
-- =================================================================

-- Table: evidence (depends on reports)
CREATE TABLE public.evidence (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  report_id bigint NOT NULL,
  file_url text NOT NULL,
  file_type file_type,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT evidence_pkey PRIMARY KEY (id),
  CONSTRAINT evidence_report_id_fkey FOREIGN KEY (report_id) REFERENCES public.reports(id)
);

-- Table: log_penanganan (depends on reports and profiles)
CREATE TABLE public.log_penanganan (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  report_id bigint NOT NULL,
  author_id uuid NOT NULL,
  catatan text NOT NULL,
  tahapan tahapan NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT log_penanganan_pkey PRIMARY KEY (id),
  CONSTRAINT log_penanganan_report_id_fkey FOREIGN KEY (report_id) REFERENCES public.reports(id),
  CONSTRAINT log_penanganan_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.profiles(id)
);

-- Table: balasan_laporan (depends on reports and profiles)
CREATE TABLE public.balasan_laporan (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  report_id bigint NOT NULL,
  author_id uuid NOT NULL,
  pesan text NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT balasan_laporan_pkey PRIMARY KEY (id),
  CONSTRAINT balasan_laporan_report_id_fkey FOREIGN KEY (report_id) REFERENCES public.reports(id),
  CONSTRAINT balasan_laporan_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.profiles(id)
);

-- Table: tanggapan_cerita (depends on cerita_kelas and profiles)
CREATE TABLE public.tanggapan_cerita (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  cerita_id bigint NOT NULL,
  author_id uuid NOT NULL,
  tanggapan text NOT NULL CHECK (char_length(tanggapan) >= 1 AND char_length(tanggapan) <= 1000),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT tanggapan_cerita_pkey PRIMARY KEY (id),
  CONSTRAINT tanggapan_cerita_cerita_id_fkey FOREIGN KEY (cerita_id) REFERENCES public.cerita_kelas(id),
  CONSTRAINT tanggapan_cerita_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.profiles(id)
);

-- =================================================================
-- TABLES CREATED SUCCESSFULLY
-- All tables created in proper dependency order
-- Circular dependencies resolved with ALTER TABLE
-- =================================================================