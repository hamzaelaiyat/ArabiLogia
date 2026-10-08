-- Schema for ArabiLogia

-- Create the profiles table
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    full_name TEXT,
    username TEXT UNIQUE,
    grade INT,
    avatar_url TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_public BOOLEAN DEFAULT true,
    hide_avatar BOOLEAN DEFAULT false,
    hide_name BOOLEAN DEFAULT false,
    random_name TEXT,
    role TEXT DEFAULT 'student' CHECK (role IN ('student', 'teacher', 'admin')),
    grade_updated_at TIMESTAMPTZ DEFAULT (NOW() - INTERVAL '4 days'),
    image_violation_count INT NOT NULL DEFAULT 0,
    image_blocked_until TIMESTAMPTZ,
    has_bad_tag BOOLEAN NOT NULL DEFAULT false,
    avatar_updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_violation_at TIMESTAMPTZ,
    last_avatar_upload_at TIMESTAMPTZ
);

-- Helper function to avoid RLS recursion when checking auth user role
CREATE OR REPLACE FUNCTION public.auth_role()
RETURNS TEXT
SECURITY DEFINER
LANGUAGE sql
STABLE
AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$$;

-- Enable Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Users can view their own profile
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

-- Users can update their own profile
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

-- Teachers/admins can view all profiles (uses auth_role helper to avoid recursion)
DROP POLICY IF EXISTS "Teachers can view profiles" ON public.profiles;
CREATE POLICY "Teachers can view profiles" ON public.profiles
    FOR SELECT TO authenticated
    USING (public.auth_role() = ANY (ARRAY['teacher', 'admin']));

-- Create a function to handle new user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, username, grade, role)
    VALUES (
        new.id,
        new.raw_user_meta_data->>'full_name',
        new.raw_user_meta_data->>'username',
        CAST(NULLIF(new.raw_user_meta_data->>'grade', '') AS INT),
        COALESCE(new.raw_user_meta_data->>'role', 'student')
    );
    RETURN new;
EXCEPTION
    WHEN OTHERS THEN
        -- Fallback: insert minimal profile if metadata parsing fails
        -- This ensures the user can still sign up even if custom fields err
        INSERT INTO public.profiles (id, role) VALUES (new.id, 'student');
        RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a trigger to call the function on signup
CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Server-side grade update rate limiting (3 days)
CREATE OR REPLACE FUNCTION public.check_grade_update_limit()
RETURNS TRIGGER AS $$
DECLARE
    last_update TIMESTAMPTZ;
BEGIN
    IF NEW.grade IS NOT NULL AND (OLD.grade IS NULL OR NEW.grade <> OLD.grade) THEN
        last_update := COALESCE(OLD.grade_updated_at, OLD.created_at);
        
        IF last_update > NOW() - INTERVAL '3 days' THEN
            RAISE EXCEPTION 'لا يمكنك تغيير الصف الدراسي إلا بعد % أيام',
                CEIL(EXTRACT(EPOCH FROM (INTERVAL '3 days' - (NOW() - last_update))) / 86400)::INT
                USING ERRCODE = 'check_violation';
        END IF;
        
        NEW.grade_updated_at := NOW();
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Add trigger for grade update rate limiting
DROP TRIGGER IF EXISTS on_grade_update ON public.profiles;
CREATE TRIGGER on_grade_update
    BEFORE UPDATE OF grade ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.check_grade_update_limit();

-- ============================================
-- Exam Results Table
-- ============================================

-- Create exam_results table
CREATE TABLE IF NOT EXISTS public.exam_results (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    exam_id TEXT,
    subject TEXT,
    score DOUBLE PRECISION NOT NULL CONSTRAINT check_score_range CHECK (score >= 0 AND score <= 100),
    wrong_mask BIGINT NOT NULL DEFAULT 0,
    status TEXT CHECK (status IN ('completed', 'abandoned')) DEFAULT 'completed',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    points INTEGER
);

-- FK to exams table with ON DELETE SET NULL
ALTER TABLE public.exam_results ADD CONSTRAINT fk_exam_results_exam FOREIGN KEY (exam_id) REFERENCES public.exams(id) ON DELETE SET NULL;

-- Enable RLS
ALTER TABLE public.exam_results ENABLE ROW LEVEL SECURITY;

-- Anyone authenticated can insert their own exam results
DROP POLICY IF EXISTS "Users can insert own exam results" ON public.exam_results;
CREATE POLICY "Users can insert own exam results" ON public.exam_results
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can view their own exam results
DROP POLICY IF EXISTS "Users can view own exam results" ON public.exam_results;
CREATE POLICY "Users can view own exam results" ON public.exam_results
    FOR SELECT USING (auth.uid() = user_id);

-- Teachers/admins can view all exam results (uses auth_role helper to avoid recursion)
DROP POLICY IF EXISTS "Teachers can view all exam results" ON public.exam_results;
DROP POLICY IF EXISTS "Teachers can read all scores" ON public.exam_results;
DROP POLICY IF EXISTS "Teachers can view all results" ON public.exam_results;
CREATE POLICY "Teachers can read all scores" ON public.exam_results
    FOR SELECT TO authenticated
    USING (public.auth_role() = 'teacher');
CREATE POLICY "Teachers can view all exam results" ON public.exam_results
    FOR SELECT TO public
    USING (public.auth_role() = ANY (ARRAY['teacher', 'admin']));

-- Create index for faster queries by exam_id
CREATE INDEX IF NOT EXISTS idx_exam_results_exam_id ON public.exam_results(exam_id);
CREATE INDEX IF NOT EXISTS idx_exam_results_user_id ON public.exam_results(user_id);
CREATE INDEX IF NOT EXISTS idx_exam_results_user_exam ON public.exam_results(user_id, exam_id);
CREATE UNIQUE INDEX IF NOT EXISTS uniq_first_completion ON public.exam_results (user_id, exam_id) WHERE status = 'completed';

-- ============================================
-- Reports Table (for bug/issue reporting)
-- ============================================

CREATE TABLE IF NOT EXISTS public.reports (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    issue TEXT NOT NULL,
    whatsapp TEXT NOT NULL,
    phone TEXT,
    screenshots TEXT,
    videos TEXT,
    app_version TEXT,
    platform TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    device_info TEXT,
    steps_to_reproduce TEXT,
    status TEXT DEFAULT 'new' CHECK (status IN ('new', 'in_progress', 'resolved', 'closed')),
    attachment_urls TEXT[] DEFAULT '{}'
);

-- Enable RLS
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

-- Users can insert their own reports
DROP POLICY IF EXISTS "Users can insert own reports" ON public.reports;
CREATE POLICY "Users can insert own reports" ON public.reports
    FOR INSERT WITH CHECK (
        auth.uid() = user_id 
        OR (auth.uid() IS NULL AND user_id IS NULL)
    );

-- Users can view their own reports
DROP POLICY IF EXISTS "Users can view own reports" ON public.reports;
CREATE POLICY "Users can view own reports" ON public.reports
    FOR SELECT USING (auth.uid() = user_id);

-- Admins can view all reports (uses auth_role helper to avoid recursion)
DROP POLICY IF EXISTS "Admins can view all reports" ON public.reports;
CREATE POLICY "Admins can view all reports" ON public.reports
    FOR SELECT TO public
    USING (public.auth_role() = 'admin');

-- Add indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_reports_user_id ON public.reports(user_id);
CREATE INDEX IF NOT EXISTS idx_reports_created_at ON public.reports(created_at);

-- Partial index for leaderboard queries (excludes bad-tagged users from fast path)
CREATE INDEX IF NOT EXISTS idx_profiles_leaderboard ON public.profiles (id) WHERE has_bad_tag = false;

-- SECURITY DEFINER function to check if a random name already exists (bypasses RLS)
CREATE OR REPLACE FUNCTION public.check_random_name_exists(name TEXT)
RETURNS BOOLEAN
SECURITY DEFINER
SET search_path = public
LANGUAGE sql
AS $$
  SELECT EXISTS (SELECT 1 FROM public.profiles WHERE random_name = name);
$$;

-- ============================================
-- Updated_at trigger for exam_results
-- ============================================

CREATE OR REPLACE FUNCTION public.update_exam_results_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_exam_results_update ON public.exam_results;
CREATE TRIGGER on_exam_results_update
    BEFORE UPDATE ON public.exam_results
    FOR EACH ROW
    EXECUTE FUNCTION public.update_exam_results_updated_at();

-- ============================================
-- Utility Functions
-- ============================================

-- RPC to sync role from auth.users metadata into public.profiles
CREATE OR REPLACE FUNCTION public.sync_user_role_to_profiles()
RETURNS TABLE(user_id uuid, old_role text, new_role text)
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  UPDATE public.profiles p
  SET role = COALESCE(u.raw_user_meta_data->>'role', 'student')
  FROM auth.users u
  WHERE p.id = u.id
    AND COALESCE(u.raw_user_meta_data->>'role', 'student') != p.role
  RETURNING p.id, p.role AS old_role, COALESCE(u.raw_user_meta_data->>'role', 'student') AS new_role;
END;
$$;

-- Function to reset image violations older than 7 days
CREATE OR REPLACE FUNCTION public.reset_old_image_violations()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.profiles
  SET image_violation_count = 0,
      last_violation_at = NULL
  WHERE last_violation_at IS NOT NULL
    AND last_violation_at < NOW() - INTERVAL '7 days'
    AND has_bad_tag = false;
END;
$$;

-- ============================================
-- Leaderboard RPC
-- ============================================

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

-- ============================================
-- Points Adjustments Table (Instructor-managed points ledger)
-- ============================================

CREATE TABLE IF NOT EXISTS public.points_adjustments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    amount INTEGER NOT NULL,
    performed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.points_adjustments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Teachers view all adjustments" ON public.points_adjustments;
CREATE POLICY "Teachers view all adjustments"
    ON public.points_adjustments
    FOR SELECT TO authenticated
    USING (public.auth_role() = ANY (ARRAY['teacher', 'admin']));

DROP POLICY IF EXISTS "Students view own adjustments" ON public.points_adjustments;
CREATE POLICY "Students view own adjustments"
    ON public.points_adjustments
    FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Teachers insert adjustments" ON public.points_adjustments;
CREATE POLICY "Teachers insert adjustments"
    ON public.points_adjustments
    FOR INSERT TO authenticated
    WITH CHECK (public.auth_role() = ANY (ARRAY['teacher', 'admin']));

CREATE INDEX IF NOT EXISTS idx_points_adjustments_user_id
    ON public.points_adjustments(user_id);
CREATE INDEX IF NOT EXISTS idx_points_adjustments_created_at
    ON public.points_adjustments(created_at DESC);

-- ============================================
-- adjust_student_points RPC
-- ============================================

CREATE OR REPLACE FUNCTION public.adjust_student_points(
    p_user_id UUID,
    p_amount INTEGER,
    p_action TEXT
)
RETURNS TABLE(new_balance BIGINT, change_amount INTEGER)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_current_balance BIGINT;
    v_change INTEGER;
    v_actor UUID;
    v_target_exists BOOLEAN;
BEGIN
    IF public.auth_role() NOT IN ('teacher', 'admin') THEN
        RAISE EXCEPTION 'غير مصرح لك بتعديل النقاط'
            USING ERRCODE = 'insufficient_privilege';
    END IF;

    SELECT EXISTS(
        SELECT 1 FROM public.profiles
        WHERE id = p_user_id AND role = 'student'
    ) INTO v_target_exists;

    IF NOT v_target_exists THEN
        RAISE EXCEPTION 'الطالب غير موجود'
            USING ERRCODE = 'no_data_found';
    END IF;

    IF p_action NOT IN ('increment', 'decrement', 'reset') THEN
        RAISE EXCEPTION 'إجراء غير صالح'
            USING ERRCODE = 'invalid_parameter_value';
    END IF;

    v_actor := auth.uid();

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
$$;

-- ============================================
-- get_students_with_balances RPC
-- ============================================

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