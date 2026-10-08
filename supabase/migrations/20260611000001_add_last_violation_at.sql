-- Add last_violation_at column to track when the last violation occurred
-- This enables automatic violation count reset after 7 days of no violations
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS last_violation_at TIMESTAMPTZ;
