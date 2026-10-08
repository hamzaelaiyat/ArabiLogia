ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS last_avatar_upload_at TIMESTAMPTZ;
