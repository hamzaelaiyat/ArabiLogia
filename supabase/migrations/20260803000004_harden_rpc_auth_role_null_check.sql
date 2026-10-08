-- Hardens the two SECURITY DEFINER RPCs against the NULL-trap:
-- auth_role() returns NULL for anonymous / missing-profile callers, and
-- `IF NULL NOT IN ('teacher','admin')` evaluates to NULL (treated as false),
-- so anonymous users could previously call the leaderboard and points RPCs.
CREATE OR REPLACE FUNCTION public.adjust_student_points(p_user_id uuid, p_amount integer, p_action text)
 RETURNS TABLE(new_balance bigint, change_amount integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_current_balance BIGINT;
    v_change INTEGER;
    v_actor UUID;
    v_target_exists BOOLEAN;
BEGIN
    -- Authorization check: only teachers/admins
    IF COALESCE(public.auth_role(), '') NOT IN ('teacher', 'admin') THEN
        RAISE EXCEPTION 'غير مصرح لك بتعديل النقاط'
            USING ERRCODE = 'insufficient_privilege';
    END IF;

    -- Validate target student exists
    SELECT EXISTS(
        SELECT 1 FROM public.profiles
        WHERE id = p_user_id AND role = 'student'
    ) INTO v_target_exists;

    IF NOT v_target_exists THEN
        -- P0001 (raise_exception) maps to HTTP 400 via PostgREST; no_data_found (P0002)
        -- is not mapped and surfaced as 500 over /rest/v1/rpc.
        RAISE EXCEPTION 'الطالب غير موجود'
            USING ERRCODE = 'raise_exception';
    END IF;

    -- Validate action
    IF p_action NOT IN ('increment', 'decrement', 'reset') THEN
        RAISE EXCEPTION 'إجراء غير صالح'
            USING ERRCODE = 'raise_exception';
    END IF;

    v_actor := auth.uid();

    -- Compute current manual adjustments total
    SELECT COALESCE(SUM(amount), 0)
    INTO v_current_balance
    FROM public.points_adjustments
    WHERE user_id = p_user_id;

    IF p_action = 'increment' THEN
        v_change := ABS(p_amount);
        IF v_change <= 0 THEN
            RAISE EXCEPTION 'يجب أن تكون القيمة أكبر من صفر'
                USING ERRCODE = 'check_violation';
        END IF;
    ELSIF p_action = 'decrement' THEN
        v_change := -ABS(p_amount);
        IF ABS(p_amount) <= 0 THEN
            RAISE EXCEPTION 'يجب أن تكون القيمة أكبر من صفر'
                USING ERRCODE = 'check_violation';
        END IF;
        -- Prevent balance from going below zero
        IF v_current_balance + v_change < 0 THEN
            v_change := -v_current_balance;
        END IF;
    ELSIF p_action = 'reset' THEN
        v_change := -v_current_balance;
    END IF;

    INSERT INTO public.points_adjustments (user_id, amount, performed_by)
    VALUES (p_user_id, v_change, v_actor);

    new_balance := v_current_balance + v_change;
    change_amount := v_change;
    RETURN NEXT;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_students_with_balances(p_grade integer DEFAULT NULL::integer)
 RETURNS TABLE(user_id uuid, full_name text, username text, avatar_url text, grade integer, exam_points bigint, manual_adjustments bigint, total_balance bigint)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
#variable_conflict use_column
BEGIN
    -- Authorization check
    IF COALESCE(public.auth_role(), '') NOT IN ('teacher', 'admin') THEN
        RAISE EXCEPTION 'غير مصرح لك بالوصول'
            USING ERRCODE = 'insufficient_privilege';
    END IF;

    RETURN QUERY
    WITH exam_totals AS (
        SELECT er.user_id,
               COALESCE(SUM(best_points), 0)::BIGINT AS exam_pts
        FROM (
            SELECT user_id, exam_id,
                   MAX(COALESCE(points, score::integer)) AS best_points
            FROM public.exam_results
            WHERE status = 'completed'
            GROUP BY user_id, exam_id
        ) er
        GROUP BY er.user_id
    ),
    adj_totals AS (
        SELECT pa.user_id,
               COALESCE(SUM(pa.amount), 0)::BIGINT AS adj_pts
        FROM public.points_adjustments pa
        GROUP BY pa.user_id
    )
    SELECT
        p.id AS user_id,
        p.full_name,
        p.username,
        p.avatar_url,
        p.grade,
        COALESCE(et.exam_pts, 0) AS exam_points,
        COALESCE(at.adj_pts, 0) AS manual_adjustments,
        COALESCE(et.exam_pts, 0) + COALESCE(at.adj_pts, 0) AS total_balance
    FROM public.profiles p
    LEFT JOIN exam_totals et ON et.user_id = p.id
    LEFT JOIN adj_totals at ON at.user_id = p.id
    WHERE p.role = 'student'
      AND (p_grade IS NULL OR p_grade = 0 OR p.grade = p_grade)
    ORDER BY total_balance DESC, p.full_name ASC;
END;
$function$;
