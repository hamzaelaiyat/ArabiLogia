-- 1) get_all_user_results had the same NULL-trap: for anonymous callers
--    auth.uid() is NULL, so `auth.uid() != p_user_id` is NULL (not raised),
--    letting anon read any user's exam results. Use explicit COALESCE compare.
CREATE OR REPLACE FUNCTION public.get_all_user_results(p_user_id uuid)
 RETURNS TABLE(exam_id text, subject text, score real, points integer, created_at timestamp with time zone, has_wrong_details boolean)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    IF COALESCE(auth.uid()::text, '') != p_user_id::text THEN
        RAISE EXCEPTION 'Not authorized';
    END IF;

    RETURN QUERY
    SELECT
        er.exam_id,
        er.subject,
        er.score::REAL,
        er.points,
        er.created_at,
        true AS has_wrong_details
    FROM public.exam_results er
    WHERE er.user_id = p_user_id
    UNION ALL
    SELECT
        ar.exam_id,
        NULL::TEXT AS subject,
        ar.score,
        ar.points,
        ar.created_at,
        false AS has_wrong_details
    FROM public.exam_results_archive ar
    WHERE ar.user_id = p_user_id
    ORDER BY created_at DESC;
END;
$function$;

-- 2) These sensitive SECURITY DEFINER RPCs must not be callable by the anon
--    role at all (their bodies already reject non-teacher/admins, this is
--    defense in depth). pg_cron still runs archive_old_results() as postgres.
REVOKE EXECUTE ON FUNCTION public.adjust_student_points(uuid, integer, text) FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_students_with_balances(integer) FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_all_user_results(uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION public.archive_old_results() FROM anon, authenticated;
