-- Exclude non-students from leaderboard
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
               COALESCE(SUM(bpe.best_points)::double precision, 0::double precision) AS total_score
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

-- Update leaderboard view too
CREATE OR REPLACE VIEW public.leaderboard AS
WITH first_per_exam AS (
    SELECT er1.user_id,
           er1.exam_id,
           COALESCE(er1.points, er1.score::integer) AS first_score
    FROM exam_results er1
    WHERE er1.status = 'completed'
      AND NOT EXISTS (
        SELECT 1 FROM exam_results er2
        WHERE er2.user_id = er1.user_id
          AND er2.exam_id = er1.exam_id
          AND er2.status = 'completed'
          AND er2.created_at < er1.created_at
    )
),
user_totals AS (
    SELECT user_id, SUM(first_score)::double precision AS total_score
    FROM first_per_exam
    GROUP BY user_id
),
exam_counts AS (
    SELECT user_id, COUNT(DISTINCT exam_id) AS exams_completed
    FROM exam_results
    WHERE status = 'completed'
    GROUP BY user_id
)
SELECT p.id AS user_id,
       p.full_name,
       p.grade,
       p.avatar_url,
       p.is_public,
       p.username,
       COALESCE(ut.total_score, 0::double precision) AS total_score,
       COALESCE(ec.exams_completed, 0::bigint) AS exams_completed,
       CASE
           WHEN ec.exams_completed > 0
           THEN (ut.total_score / ec.exams_completed::double precision)::numeric(10,1)
           ELSE 0::numeric(10,1)
       END AS avg_score,
       RANK() OVER (ORDER BY COALESCE(ut.total_score, 0::double precision) DESC) AS overall_rank,
       RANK() OVER (PARTITION BY p.grade ORDER BY COALESCE(ut.total_score, 0::double precision) DESC) AS rank_within_grade
FROM profiles p
LEFT JOIN user_totals ut ON p.id = ut.user_id
LEFT JOIN exam_counts ec ON p.id = ec.user_id
WHERE p.is_public = true
  AND p.role = 'student'
ORDER BY p.grade, ut.total_score DESC;
