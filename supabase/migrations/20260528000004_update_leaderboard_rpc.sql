-- Update get_leaderboard_by_period to return has_bad_tag and avatar_updated_at
CREATE OR REPLACE FUNCTION public.get_leaderboard_by_period(period_filter TEXT)
RETURNS TABLE(
    user_id UUID,
    full_name TEXT,
    grade INT,
    avatar_url TEXT,
    has_bad_tag BOOLEAN,
    avatar_updated_at TIMESTAMPTZ,
    total_score DOUBLE PRECISION,
    avg_score NUMERIC,
    exams_completed BIGINT,
    rank BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
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
        SELECT er.user_id, er.exam_id, er.score, er.created_at
        FROM public.exam_results er
        WHERE (
            period_filter = 'all' OR
            (period_filter = 'week' AND er.created_at >= date_trunc('week', now())) OR
            (period_filter = 'month' AND er.created_at >= date_trunc('month', now()))
        )
    ),
    best_filtered_scores AS (
        SELECT fr.user_id, fr.exam_id, MAX(fr.score) as best_score
        FROM filtered_results fr
        GROUP BY fr.user_id, fr.exam_id
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
        COALESCE(SUM(bfs.best_score), 0::double precision) AS total_score,
        COALESCE(ROUND(AVG(fr.score)::numeric, 1), 0.0) AS avg_score,
        COALESCE(COUNT(DISTINCT fr.exam_id), 0::bigint) AS exams_completed,
        RANK() OVER (ORDER BY COALESCE(SUM(bfs.best_score), 0::double precision) DESC) AS rank
    FROM public.profiles p
    LEFT JOIN best_filtered_scores bfs ON p.id = bfs.user_id
    LEFT JOIN filtered_results fr ON p.id = fr.user_id
    WHERE p.is_public = true OR auth.uid() = p.id
    GROUP BY p.id, p.full_name, p.grade, p.avatar_url, p.hide_avatar, p.hide_name, p.random_name, p.has_bad_tag, p.avatar_updated_at;
END;
$$;
