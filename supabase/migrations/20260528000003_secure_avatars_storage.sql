-- Revoke all client write access to the avatars bucket.
-- Only the Edge Function (using service_role) can INSERT, UPDATE, or DELETE.
-- Public and authenticated users retain SELECT (read) for displaying avatars.

-- 1. Drop the wide-open INSERT for all authenticated users on avatars
DROP POLICY IF EXISTS "Authenticated Upload" ON storage.objects;

-- 2. Drop the ALL policy that lets authenticated users do anything on their own files
DROP POLICY IF EXISTS "User Control" ON storage.objects;

-- 3. Keep "Public Access" so avatars are publicly readable
-- (already exists, no change needed)

-- 4. Create a SELECT-only policy for authenticated users who need to read their own files
CREATE POLICY "Authenticated Select Own Avatars"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'avatars'::text
    AND (storage.foldername(name))[1] IS NULL
    AND name ~~ ((auth.uid())::text || '%'::text)
  );
