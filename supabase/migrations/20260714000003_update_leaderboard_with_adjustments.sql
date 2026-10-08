-- Update get_leaderboard_by_period to include manual point adjustments
-- Must DROP first since PostgreSQL doesn't allow changing return type of existing function

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
        SELECT er.user_id, er.exam_id, er.score, er.points, er.created_at
        FROM public.exam_results er
        WHERE (
            period_filter = 'all' OR
            (period_filter = 'week' AND er.created_at >= date_trunc('week', now())) OR
            (period_filter = 'month' AND er.created_at >= date_trunc('month', now()))
        )
    ),
    best_per_exam AS (
        SELECT fr.user_id, fr.exam_id,
               MAX(COALESCE(fr.points, fr.score::integer)) as best_points
        FROM filtered_results fr
        GROUP BY fr.user_id, fr.exam_id
    ),
    user_totals AS (
        SELECT bpe.user_id,
               COALESCE(SUM(bpe.best_points)::double precision, 0::double precision)
               + COALESCE((
                   SELECT SUM(pa.amount)::double precision
                   FROM public.points_adjustments pa
                   WHERE pa.user_id = bpe.user_id
               ), 0::double precision) AS total_score
        FROM best_per_exam bpe
        GROUP BY bpe.user_id
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
    LEFT JOIN user_totals ut ON p.id = ut.user_id
    LEFT JOIN user_averages ua ON p.id = ua.user_id
    WHERE (p.is_public = true OR auth.uid() = p.id)
      AND p.role = 'student';
END;
$$;
