-- Optimize exam_results storage + add archive system for Free Plan (500 MB limit)
--
-- Storage analysis for 800 students × 3,000 exams = 2.4M rows:
--   Before:  ~960 MB (exceeds Free Plan 500 MB)
--   After:   ~180 MB hot + ~440 MB cold = ~620 MB across both tables
--   Archive allows purging hot table regularly, keeping cold storage index-minimal
--
-- Archive cutoff: configurable 1h-120h (default 24h) via archive_config table

-- ============================================
-- Part 1: Optimize exam_results (hot table)
-- ============================================

-- Drop redundant index (user_id is prefix of idx_exam_results_user_exam,
-- so PostgreSQL uses the composite index for user-only queries)
DROP INDEX IF EXISTS idx_exam_results_user_id;

-- Remove unused updated_at column + trigger + function
-- (Dart code never reads or writes updated_at)
DROP TRIGGER IF EXISTS on_exam_results_update ON public.exam_results;
DROP FUNCTION IF EXISTS public.update_exam_results_updated_at;
ALTER TABLE public.exam_results DROP COLUMN IF EXISTS updated_at;

-- ============================================
-- Part 2: Create archive table (cold storage)
-- ============================================
-- No wrong_mask — old results show final grade only
-- No subject — derived from exam_id if needed
-- REAL score instead of DOUBLE PRECISION (saves 4 bytes/row)
-- Minimal indexes (only 2 vs current 8 on hot table)

CREATE TABLE IF NOT EXISTS public.exam_results_archive (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    exam_id TEXT NOT NULL,
    score REAL NOT NULL CHECK (score >= 0 AND score <= 100),
    status TEXT CHECK (status IN ('completed', 'abandoned')) DEFAULT 'completed',
    points INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Minimal covering indexes for leaderboard + user-history queries
CREATE INDEX IF NOT EXISTS idx_archive_user_created
    ON public.exam_results_archive (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_archive_created_at
    ON public.exam_results_archive (created_at DESC);

-- RLS: same access model as exam_results
ALTER TABLE public.exam_results_archive ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own archived results" ON public.exam_results_archive;
CREATE POLICY "Users can view own archived results"
    ON public.exam_results_archive FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Teachers can view all archived results" ON public.exam_results_archive;
CREATE POLICY "Teachers can view all archived results"
    ON public.exam_results_archive FOR SELECT TO authenticated
    USING (public.auth_role() = 'teacher');

DROP POLICY IF EXISTS "Admins can view all archived results" ON public.exam_results_archive;
CREATE POLICY "Admins can view all archived results"
    ON public.exam_results_archive FOR SELECT TO public
    USING (public.auth_role() = ANY (ARRAY['teacher', 'admin']));

-- ============================================
-- Part 3: Archive config (singleton table)
-- ============================================
-- cutoff_hours: 1 to 120 (5 days), default 24

CREATE TABLE IF NOT EXISTS public.archive_config (
    id INT PRIMARY KEY DEFAULT 1 CHECK (id = 1),
    cutoff_hours INT NOT NULL DEFAULT 24 CHECK (cutoff_hours BETWEEN 1 AND 120)
);

INSERT INTO public.archive_config (cutoff_hours) VALUES (24)
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- Part 4: Archive function (called by pg_cron)
-- ============================================
-- Moves rows older than cutoff from exam_results to exam_results_archive
-- Drops wrong_mask during transfer (intentional data loss for storage savings)

CREATE OR REPLACE FUNCTION public.archive_old_results()
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    cutoff TIMESTAMPTZ;
    moved INT;
BEGIN
    SELECT NOW() - (cutoff_hours || ' hours')::INTERVAL INTO cutoff
    FROM public.archive_config WHERE id = 1;

    WITH moved_rows AS (
        DELETE FROM public.exam_results
        WHERE created_at < cutoff
        RETURNING id, user_id, exam_id, score, status, points, created_at
    )
    INSERT INTO public.exam_results_archive
        (id, user_id, exam_id, score, status, points, created_at)
    SELECT id, user_id, exam_id, score, status, points, created_at
    FROM moved_rows;

    GET DIAGNOSTICS moved = ROW_COUNT;
    RETURN moved;
END;
$$;

-- Schedule every hour (runs at :00 past each hour)
-- Unschedule first in case it already exists from a prior run
SELECT cron.unschedule('archive-old-results');
SELECT cron.schedule(
    'archive-old-results',
    '0 * * * *',
    $$SELECT public.archive_old_results();$$
);

-- ============================================
-- Part 5: Combined-user-results RPC (for app SDK)
-- ============================================
-- Returns results from both tables in one call
-- has_wrong_details=false means archived (grade-only)

DROP FUNCTION IF EXISTS public.get_all_user_results(UUID) CASCADE;

CREATE FUNCTION public.get_all_user_results(p_user_id UUID)
RETURNS TABLE(
    exam_id TEXT,
    subject TEXT,
    score REAL,
    points INT,
    created_at TIMESTAMP WITH TIME ZONE,
    has_wrong_details BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF auth.uid() != p_user_id THEN
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
$$;

-- ============================================
-- Part 6: Update leaderboard RPC to include archive
-- ============================================

DROP FUNCTION IF EXISTS public.get_leaderboard_by_period(TEXT) CASCADE;
DROP VIEW IF EXISTS public.leaderboard;

CREATE FUNCTION public.get_leaderboard_by_period(period_filter TEXT)
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
    WITH all_results AS (
        SELECT er.user_id, er.exam_id, er.score, er.points, er.created_at
        FROM public.exam_results er
        UNION ALL
        SELECT ar.user_id, ar.exam_id, ar.score::DOUBLE PRECISION, ar.points, ar.created_at
        FROM public.exam_results_archive ar
    ),
    filtered_results AS (
        SELECT ar.user_id, ar.exam_id, ar.score, ar.points, ar.created_at
        FROM all_results ar
        WHERE (
            period_filter = 'all' OR
            (period_filter = 'week' AND ar.created_at >= date_trunc('week', now())) OR
            (period_filter = 'month' AND ar.created_at >= date_trunc('month', now()))
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

-- Update leaderboard VIEW to include archive
CREATE OR REPLACE VIEW public.leaderboard AS
WITH all_results AS (
    SELECT er.user_id, er.exam_id, er.score, er.points, er.created_at, er.status
    FROM public.exam_results er
    UNION ALL
    SELECT ar.user_id, ar.exam_id, ar.score::DOUBLE PRECISION, ar.points, ar.created_at, ar.status
    FROM public.exam_results_archive ar
),
first_per_exam AS (
    SELECT ar1.user_id,
           ar1.exam_id,
           COALESCE(ar1.points, ar1.score::integer) AS first_score
    FROM all_results ar1
    WHERE ar1.status = 'completed'
      AND NOT EXISTS (
        SELECT 1 FROM all_results ar2
        WHERE ar2.user_id = ar1.user_id
          AND ar2.exam_id = ar1.exam_id
          AND ar2.status = 'completed'
          AND ar2.created_at < ar1.created_at
    )
),
user_totals AS (
    SELECT user_id, SUM(first_score)::double precision AS total_score
    FROM first_per_exam
    GROUP BY user_id
),
exam_counts AS (
    SELECT user_id, COUNT(DISTINCT exam_id) AS exams_completed
    FROM all_results
    WHERE status = 'completed'
    GROUP BY user_id
)
SELECT
    p.id AS user_id,
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
FROM public.profiles p
LEFT JOIN user_totals ut ON p.id = ut.user_id
LEFT JOIN exam_counts ec ON p.id = ec.user_id
WHERE p.is_public = true
  AND p.role = 'student'
ORDER BY p.grade, ut.total_score DESC;
