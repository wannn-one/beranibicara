-- Migration: Add user blocking system with temporary blocks and reasons
-- Only admin (TPPK) can block/unblock users

-- 1. Create enum for user status
CREATE TYPE public.user_status AS ENUM (
  'aktif',
  'nonaktif', 
  'diblokir',
  'deletion_requested'
);

-- 2. Add columns to profiles table
ALTER TABLE public.profiles 
ADD COLUMN status user_status NOT NULL DEFAULT 'aktif',
ADD COLUMN blocked_until timestamptz NULL,           -- When the block expires (NULL = permanent)
ADD COLUMN blocked_reason text NULL,                 -- Reason for blocking
ADD COLUMN blocked_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL, -- Who blocked this user
ADD COLUMN blocked_at timestamptz NULL;             -- When user was blocked

-- 3. Add comments for documentation
COMMENT ON COLUMN public.profiles.status IS 'User account status';
COMMENT ON COLUMN public.profiles.blocked_until IS 'Block expiration time (NULL for permanent block)';
COMMENT ON COLUMN public.profiles.blocked_reason IS 'Reason why user was blocked';
COMMENT ON COLUMN public.profiles.blocked_by IS 'Admin who blocked this user';
COMMENT ON COLUMN public.profiles.blocked_at IS 'Timestamp when user was blocked';

-- 4. Create function to automatically unblock expired users
CREATE OR REPLACE FUNCTION public.auto_unblock_expired_users()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.profiles 
  SET 
    status = 'aktif',
    blocked_until = NULL,
    blocked_reason = NULL,
    blocked_by = NULL,
    blocked_at = NULL
  WHERE 
    status = 'diblokir' 
    AND blocked_until IS NOT NULL 
    AND blocked_until <= now();
END;
$$;

-- 5. Create trigger to auto-unblock expired users (runs every hour)
-- Note: In production, this should be handled by a cron job or scheduled function