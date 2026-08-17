-- Add violation tracking columns to profiles table
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS image_violation_count INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS image_blocked_until TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS has_bad_tag BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS avatar_updated_at TIMESTAMPTZ DEFAULT NOW();

-- Partial index for leaderboard queries (excludes bad-tagged users from fast path)
CREATE INDEX IF NOT EXISTS idx_profiles_leaderboard
  ON profiles (id) WHERE has_bad_tag = false;
