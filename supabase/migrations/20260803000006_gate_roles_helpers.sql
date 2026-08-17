-- ============================================================
-- Gate + Security hardening — Part 1: Roles & helpers
-- ------------------------------------------------------------
-- 1) Enable pgcrypto (bcrypt passcode hashing for the gate)
-- 2) Add 'dev' to profiles.role CHECK
-- 3) is_dev() / is_adminish() helpers
-- 4) handle_new_user() always creates 'student' (blocks privesc)
-- 5) Harden sync_user_role_to_profiles (no role re-sync from metadata)
-- 6) Add search_path to sync_profile_from_metadata
-- 7) Trigger: students can never change role or moderation columns
-- 8) Extend grade rate-limit trigger to block back-dating
-- ============================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ------------------------------------------------------------
-- 1) Add 'dev' role
-- ------------------------------------------------------------
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_role_check;
ALTER TABLE public.profiles ADD CONSTRAINT profiles_role_check
  CHECK (role IN ('student', 'teacher', 'admin', 'dev'));

-- ------------------------------------------------------------
-- 2) Role helpers (SECURITY DEFINER to avoid RLS recursion)
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_dev()
RETURNS boolean
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(auth_role(), '') = 'dev';
$$;

CREATE OR REPLACE FUNCTION public.is_adminish()
RETURNS boolean
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(auth_role(), '') = ANY (ARRAY['teacher', 'admin', 'dev']);
$$;

-- ------------------------------------------------------------
-- 3) handle_new_user: always 'student', never trust client metadata
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
BEGIN
    INSERT INTO public.profiles (id, full_name, username, grade, role)
    VALUES (
        NEW.id,
        NEW.raw_user_meta_data->>'full_name',
        COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || replace(NEW.id::text, '-', '')),
        CAST(NULLIF(NEW.raw_user_meta_data->>'grade', '') AS INT),
        'student'
    );
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO public.profiles (id, role, username)
        VALUES (NEW.id, 'student', 'user_' || replace(NEW.id::text, '-', ''));
        RETURN NEW;
END;
$function$;

-- ------------------------------------------------------------
-- 4) sync_user_role_to_profiles: roles are managed directly in the
--    profiles table by staff; this legacy sync can no longer promote
--    anyone from client metadata. Guarded + downgrade-only.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.sync_user_role_to_profiles()
RETURNS TABLE(user_id uuid, old_role text, new_role text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
BEGIN
    IF NOT public.is_adminish() THEN
        RAISE EXCEPTION 'غير مصرح لك' USING ERRCODE = 'insufficient_privilege';
    END IF;

    -- Only ever normalizes roles back to 'student' (used for cleanup).
    RETURN QUERY
    UPDATE public.profiles p
    SET role = 'student'
    FROM auth.users u
    WHERE p.id = u.id
      AND p.role IN ('teacher', 'admin', 'dev')
      AND p.role <> COALESCE(u.raw_user_meta_data->>'role', 'student')
      AND COALESCE(u.raw_user_meta_data->>'role', 'student') = 'student'
    RETURNING p.id, p.role AS old_role, 'student' AS new_role;
END;
$function$;

-- ------------------------------------------------------------
-- 5) sync_profile_from_metadata: add search_path hardening
--    (never touches role, so it stays safe for student self-edits)
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.sync_profile_from_metadata()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
BEGIN
  UPDATE public.profiles
  SET
    full_name = COALESCE(NEW.raw_user_meta_data->>'full_name', full_name),
    grade = CAST(COALESCE(NEW.raw_user_meta_data->>'grade', grade::text) AS INTEGER),
    avatar_url = COALESCE(NEW.raw_user_meta_data->>'avatar_url', avatar_url),
    updated_at = now()
  WHERE id = NEW.id;
  RETURN NEW;
END;
$function$;

-- ------------------------------------------------------------
-- 6) Prevent privilege escalation & moderation tampering
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.prevent_profile_privilege_escalation()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
    v_role TEXT;
BEGIN
    IF auth.uid() IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT p.role INTO v_role FROM public.profiles p WHERE p.id = auth.uid();

    IF v_role IS NULL THEN
        RAISE EXCEPTION 'profile not found' USING ERRCODE = 'insufficient_privilege';
    END IF;

    IF v_role NOT IN ('teacher', 'admin', 'dev') THEN
        IF NEW.role IS DISTINCT FROM OLD.role THEN
            RAISE EXCEPTION 'لا يمكنك تغيير الدور' USING ERRCODE = 'insufficient_privilege';
        END IF;

        IF NEW.image_violation_count IS DISTINCT FROM OLD.image_violation_count
           OR NEW.image_blocked_until IS DISTINCT FROM OLD.image_blocked_until
           OR NEW.has_bad_tag IS DISTINCT FROM OLD.has_bad_tag
           OR NEW.last_violation_at IS DISTINCT FROM OLD.last_violation_at THEN
            RAISE EXCEPTION 'لا يمكنك تعديل بيانات الرقابة' USING ERRCODE = 'insufficient_privilege';
        END IF;
    END IF;

    RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS on_profiles_privilege_escalation ON public.profiles;
CREATE TRIGGER on_profiles_privilege_escalation
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.prevent_profile_privilege_escalation();

-- ------------------------------------------------------------
-- 7) Grade rate-limiter: also prevent back-dating grade_updated_at
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.check_grade_update_limit()
RETURNS TRIGGER AS $$
DECLARE
    last_update TIMESTAMPTZ;
BEGIN
    IF NEW.grade IS NOT NULL AND (OLD.grade IS NULL OR NEW.grade <> OLD.grade) THEN
        last_update := COALESCE(OLD.grade_updated_at, OLD.created_at);

        IF last_update > NOW() - INTERVAL '3 days' THEN
            RAISE EXCEPTION 'لا يمكنك تغيير الصف الدراسي إلا بعد % أيام',
                CEIL(EXTRACT(EPOCH FROM (INTERVAL '3 days' - (NOW() - last_update))) / 86400)::INT
                USING ERRCODE = 'check_violation';
        END IF;

        NEW.grade_updated_at := NOW();
    ELSIF NEW.grade_updated_at IS DISTINCT FROM OLD.grade_updated_at THEN
        NEW.grade_updated_at := NOW();
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ------------------------------------------------------------
-- 8) Grant helpers to authenticated (used in policies + RPCs)
-- ------------------------------------------------------------
GRANT EXECUTE ON FUNCTION public.is_dev() TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.is_adminish() TO authenticated, service_role;
