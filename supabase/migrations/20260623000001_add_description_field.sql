ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS description TEXT DEFAULT '';
