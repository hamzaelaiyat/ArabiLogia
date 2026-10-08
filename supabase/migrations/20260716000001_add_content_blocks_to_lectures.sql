-- Add content_blocks column to lectures
ALTER TABLE public.lectures ADD COLUMN IF NOT EXISTS content_blocks JSONB NOT NULL DEFAULT '[]'::jsonb;
