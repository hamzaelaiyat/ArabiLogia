-- Enable pg_cron extension if not already enabled
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Function to reset image violations older than 7 days
CREATE OR REPLACE FUNCTION public.reset_old_image_violations()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.profiles
  SET image_violation_count = 0,
      last_violation_at = NULL
  WHERE last_violation_at IS NOT NULL
    AND last_violation_at < NOW() - INTERVAL '7 days'
    AND has_bad_tag = false;
END;
$$;

-- Schedule the function to run daily at 3 AM UTC
SELECT cron.schedule(
  'reset-old-image-violations-daily',
  '0 3 * * *',
  $$SELECT public.reset_old_image_violations();$$
);
