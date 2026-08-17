-- Performance indexes for 1000+ student scale

-- Index for leaderboard period filtering (week/month/all queries)
-- The leaderboard RPC filters exam_results by created_at for 'week'/'month' periods
CREATE INDEX IF NOT EXISTS idx_exam_results_created_at
  ON public.exam_results (created_at DESC);

-- Index for ranking by points (leaderboard ORDER BY total_score DESC)
-- Supports the best_per_exam and user_totals CTEs
CREATE INDEX IF NOT EXISTS idx_exam_results_points
  ON public.exam_results (points DESC)
  WHERE points IS NOT NULL;

-- Composite index for user stats queries (total score per user)
-- Covers the GROUP BY user_id in user_totals and user_averages CTEs
CREATE INDEX IF NOT EXISTS idx_exam_results_user_points
  ON public.exam_results (user_id, points DESC)
  WHERE points IS NOT NULL;

-- Index for user stats without period filter
CREATE INDEX IF NOT EXISTS idx_exam_results_user_created
  ON public.exam_results (user_id, created_at DESC);

-- Index for the profiles join in leaderboard (filters by role + is_public)
CREATE INDEX IF NOT EXISTS idx_profiles_role_public
  ON public.profiles (role, is_public)
  WHERE role = 'student';
