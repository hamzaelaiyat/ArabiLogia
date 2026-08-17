-- ============================================================
-- Gate + Security hardening — Part 6: Advisor fixes
-- - Views were SECURITY DEFINER (RLS bypass = privesc hole):
--   switch to security_invoker. Both views are unused by the
--   Flutter app (it uses get_leaderboard_by_period RPC), so
--   invoker mode only tightens access for any external tooling.
-- - Fix mutable search_path on 3 SECURITY DEFINER functions.
-- - Revoke EXECUTE on maintenance-only RPCs from client roles.
-- ============================================================

ALTER VIEW public.profiles_public SET (security_invoker = true);
ALTER VIEW public.leaderboard SET (security_invoker = true);

-- ---------- Search-path hardening ----------
CREATE OR REPLACE FUNCTION public.auth_role()
RETURNS text
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $function$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$function$;

CREATE OR REPLACE FUNCTION public.is_teacher_or_admin()
RETURNS boolean
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $function$
  SELECT EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = ANY (ARRAY['teacher', 'admin']));
$function$;

CREATE OR REPLACE FUNCTION public.reset_old_image_violations()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  UPDATE public.profiles
  SET image_violation_count = 0,
      last_violation_at = NULL
  WHERE last_violation_at IS NOT NULL
    AND last_violation_at < NOW() - INTERVAL '7 days'
    AND has_bad_tag = false;
END;
$function$;

-- ---------- Maintenance-only RPCs: client roles don't need EXECUTE ----------
REVOKE EXECUTE ON FUNCTION public.archive_old_results() FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.reset_old_image_violations() FROM anon, authenticated;
