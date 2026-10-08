-- ============================================================
-- Fix leaderboard score aggregation and ranking.
--
-- Two defects made the board look empty / collapsed:
--
-- 1. user_totals was aggregated from exam_totals alone, so a
--    student whose points came only from points_adjustments
--    produced no row at all and silently scored 0.
--    scoring_users now unions both contributors.
--
-- 2. RANK() ordered only by total_score, so every student tied at
--    0 received rank 1. The UI read the rank to decide how many
--    students exist, so a fully-tied board collapsed to "3".
--    p.id is a unique tie-breaker, making both the rank and the
--    final ORDER BY deterministic and matching.
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_leaderboard_by_period(period_filter text)
RETURNS TABLE(
    user_id uuid,
    full_name text,
    grade integer,
    avatar_url text,
    has_bad_tag boolean,
    avatar_updated_at timestamp with time zone,
    description text,
    total_score double precision,
    avg_score numeric,
    exams_completed bigint,
    rank bigint
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
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
    exam_totals AS (
        SELECT bpe.user_id,
               SUM(bpe.best_points)::double precision AS exam_points
        FROM best_per_exam bpe
        GROUP BY bpe.user_id
    ),
    adjustment_totals AS (
        SELECT pa.user_id,
               SUM(pa.amount)::double precision AS total_adjustments
        FROM public.points_adjustments pa
        GROUP BY pa.user_id
    ),
    -- Union of both score contributors. Aggregating user_totals from
    -- best_per_exam alone produced no row at all for users who only have
    -- manual point adjustments, silently zeroing their real score.
    scoring_users AS (
        SELECT user_id FROM exam_totals
        UNION
        SELECT user_id FROM adjustment_totals
    ),
    user_totals AS (
        SELECT su.user_id,
               COALESCE(et.exam_points, 0::double precision)
               + COALESCE(at.total_adjustments, 0::double precision) AS total_score
        FROM scoring_users su
        LEFT JOIN exam_totals et ON et.user_id = su.user_id
        LEFT JOIN adjustment_totals at ON at.user_id = su.user_id
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
        -- p.id is unique, so this is deterministic even when scores tie.
        -- Plain RANK() gave every zero-score user rank 1, which the UI then
        -- read as "only three students exist".
        RANK() OVER (
            ORDER BY COALESCE(ut.total_score, 0::double precision) DESC,
                     COALESCE(ua.exams_completed, 0::bigint) DESC,
                     p.id
        ) AS rank
    FROM public.profiles p
    LEFT JOIN user_totals ut ON p.id = ut.user_id
    LEFT JOIN user_averages ua ON p.id = ua.user_id
    WHERE (p.is_public = true OR auth.uid() = p.id)
      AND p.role = 'student'
    ORDER BY COALESCE(ut.total_score, 0::double precision) DESC,
             COALESCE(ua.exams_completed, 0::bigint) DESC,
             p.id;
END;
$function$;
