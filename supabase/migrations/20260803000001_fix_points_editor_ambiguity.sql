-- Fix ambiguous column reference "user_id" in get_students_with_balances
-- The RETURNS TABLE(user_id uuid, ...) OUT parameter collides with the
-- unqualified user_id references in the exam_results subquery (42702).
-- Same fix pattern as 20260716000002_fix_leaderboard_ambiguity.sql

DROP FUNCTION IF EXISTS public.get_students_with_balances(int);

CREATE OR REPLACE FUNCTION public.get_students_with_balances(p_grade INT DEFAULT NULL)
RETURNS TABLE(
    user_id UUID,
    full_name TEXT,
    username TEXT,
    avatar_url TEXT,
    grade INT,
    exam_points BIGINT,
    manual_adjustments BIGINT,
    total_balance BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
#variable_conflict use_column
BEGIN
    -- Authorization check
    IF public.auth_role() NOT IN ('teacher', 'admin') THEN
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
$$;
