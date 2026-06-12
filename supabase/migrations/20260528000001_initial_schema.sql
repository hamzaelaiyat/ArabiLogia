-- Migration: Ensure schema is in sync with schema.sql
-- This is the first migration, it verifies + adds missing pieces

-- Create sync_user_role_to_profiles RPC if it doesn't exist
-- This copies role from auth.users.raw_user_meta_data into public.profiles.role
-- where they differ, ensuring RLS policies work correctly for teachers/admins
CREATE OR REPLACE FUNCTION public.sync_user_role_to_profiles()
RETURNS TABLE(user_id uuid, old_role text, new_role text)
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  UPDATE public.profiles p
  SET role = COALESCE(u.raw_user_meta_data->>'role', 'student')
  FROM auth.users u
  WHERE p.id = u.id
    AND COALESCE(u.raw_user_meta_data->>'role', 'student') != p.role
  RETURNING p.id, p.role AS old_role, COALESCE(u.raw_user_meta_data->>'role', 'student') AS new_role;
END;
$$;
