-- Record exam completion points in points_adjustments table
-- Students can record their own exam-earned points

CREATE OR REPLACE FUNCTION public.record_exam_points(p_points INTEGER)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF p_points <= 0 THEN
        RAISE EXCEPTION 'يجب أن تكون النقاط أكبر من صفر'
            USING ERRCODE = 'check_violation';
    END IF;

    INSERT INTO public.points_adjustments (user_id, amount, performed_by)
    VALUES (auth.uid(), p_points, auth.uid());
END;
$$;

-- RLS policy: students can insert their own exam-earned points
DROP POLICY IF EXISTS "Students record own exam points" ON public.points_adjustments;
CREATE POLICY "Students record own exam points"
    ON public.points_adjustments
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = user_id AND auth.uid() = performed_by);

-- Update leaderboard to only count points_adjustments (exam points now live there)
DROP FUNCTION IF EXISTS public.get_leaderboard_by_period(text);

CREATE OR REPLACE FUNCTION public.get_leaderboard_by_period(period_filter TEXT)
RETURNS TABLE(
    user_id UUID,
    full_name TEXT,
    grade INT,
    avatar_url TEXT,
    has_bad_tag BOOLEAN,
    avatar_updated_at TIMESTAMPTZ,
    description TEXT,
    total_score DOUBLE PRECISION,
    avg_score NUMERIC,
    exams_completed BIGINT,
    rank BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
#variable_conflict use_column
DECLARE
    current_user_id UUID;
    current_user_role TEXT;
BEGIN
    current_user_id := auth.uid();
    SELECT p.role INTO current_user_role
    FROM public.profiles p
    WHERE p.id = current_user_id;

    RETURN QUERY
    WITH filtered_results AS (
        SELECT er.user_id, er.exam_id, er.score, er.created_at
        FROM public.exam_results er
        WHERE (
            period_filter = 'all' OR
            (period_filter = 'week' AND er.created_at >= date_trunc('week', now())) OR
            (period_filter = 'month' AND er.created_at >= date_trunc('month', now()))
        )
    ),
    user_points AS (
        SELECT pa.user_id,
               COALESCE(SUM(pa.amount)::double precision, 0::double precision) AS total_score
        FROM public.points_adjustments pa
        GROUP BY pa.user_id
    ),
    user_averages AS (
        SELECT fr.user_id,
               COALESCE(ROUND(AVG(fr.score)::numeric, 1), 0.0) AS avg_score,
               COALESCE(COUNT(DISTINCT fr.exam_id), 0::bigint) AS exams_completed
        FROM filtered_results fr
        GROUP BY fr.user_id
    )
    SELECT
        p.id AS user_id,
        CASE
            WHEN p.hide_name AND current_user_role != 'admin' THEN COALESCE(p.random_name, 'مستخدم')
            ELSE p.full_name
        END AS full_name,
        p.grade,
        CASE WHEN p.hide_avatar THEN NULL ELSE p.avatar_url END AS avatar_url,
        p.has_bad_tag,
        p.avatar_updated_at,
        COALESCE(p.description, '') AS description,
        COALESCE(ut.total_score, 0::double precision) AS total_score,
        COALESCE(ua.avg_score, 0.0) AS avg_score,
        COALESCE(ua.exams_completed, 0::bigint) AS exams_completed,
        RANK() OVER (ORDER BY COALESCE(ut.total_score, 0::double precision) DESC) AS rank
    FROM public.profiles p
    LEFT JOIN user_points ut ON p.id = ut.user_id
    LEFT JOIN user_averages ua ON p.id = ua.user_id
    WHERE (p.is_public = true OR auth.uid() = p.id)
      AND p.role = 'student';
END;
$$;

-- Update get_students_with_balances to use points_adjustments as the source of truth
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
BEGIN
    IF public.auth_role() NOT IN ('teacher', 'admin') THEN
        RAISE EXCEPTION 'غير مصرح لك بالوصول'
            USING ERRCODE = 'insufficient_privilege';
    END IF;

    RETURN QUERY
    WITH adj_totals AS (
        SELECT pa.user_id,
               COALESCE(SUM(pa.amount) FILTER (WHERE pa.performed_by = pa.user_id), 0)::BIGINT AS exam_pts,
               COALESCE(SUM(pa.amount) FILTER (WHERE pa.performed_by != pa.user_id), 0)::BIGINT AS manual_pts
        FROM public.points_adjustments pa
        GROUP BY pa.user_id
    )
    SELECT
        p.id AS user_id,
        p.full_name,
        p.username,
        p.avatar_url,
        p.grade,
        COALESCE(at.exam_pts, 0) AS exam_points,
        COALESCE(at.manual_pts, 0) AS manual_adjustments,
        COALESCE(at.exam_pts, 0) + COALESCE(at.manual_pts, 0) AS total_balance
    FROM public.profiles p
    LEFT JOIN adj_totals at ON at.user_id = p.id
    WHERE p.role = 'student'
      AND (p_grade IS NULL OR p_grade = 0 OR p.grade = p_grade)
    ORDER BY total_balance DESC, p.full_name ASC;
END;
$$;
