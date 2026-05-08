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
    grade_updated_at TIMESTAMPTZ DEFAULT (NOW() - INTERVAL '4 days')
);

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

-- Teachers/admins can view all profiles
DROP POLICY IF EXISTS "Teachers can view profiles" ON public.profiles;
CREATE POLICY "Teachers can view profiles" ON public.profiles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles p2
            WHERE p2.id = auth.uid()
            AND p2.role IN ('teacher', 'admin')
        )
    );

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
    days_since_update INT;
BEGIN
    -- Only check if grade is being changed
    IF NEW.grade IS NOT NULL AND (OLD.grade IS NULL OR NEW.grade <> OLD.grade) THEN
        -- Get last update time or use created_at if never updated
        last_update := COALESCE(
            OLD.grade_updated_at,
            OLD.created_at
        );
        
        days_since_update := EXTRACT(EPOCH FROM (NOW() - last_update)) / 86400;
        
        IF days_since_update < 3 THEN
            RAISE EXCEPTION 'لا يمكنك تغيير الصف الدراسي إلا بعد % أيام',
                3 - floor(days_since_update)::INT
                USING ERRCODE = 'check_violation';
        END IF;
        
        -- Update the timestamp
        NEW.grade_updated_at := NOW();
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

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
    exam_id TEXT NOT NULL,
    subject TEXT,
    score DOUBLE PRECISION NOT NULL,
    wrong_answers TEXT[] DEFAULT '{}',
    status TEXT CHECK (status IN ('completed', 'abandoned')) DEFAULT 'completed',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

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

-- Teachers/admins can view all exam results
DROP POLICY IF EXISTS "Teachers can view all exam results" ON public.exam_results;
CREATE POLICY "Teachers can view all exam results" ON public.exam_results
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles p2
            WHERE p2.id = auth.uid()
            AND p2.role IN ('teacher', 'admin')
        )
    );

-- Create index for faster queries by exam_id
CREATE INDEX IF NOT EXISTS idx_exam_results_exam_id ON public.exam_results(exam_id);
CREATE INDEX IF NOT EXISTS idx_exam_results_user_id ON public.exam_results(user_id);

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

-- Admins can view all reports
DROP POLICY IF EXISTS "Admins can view all reports" ON public.reports;
CREATE POLICY "Admins can view all reports" ON public.reports
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role IN ('admin')
        )
    );

-- Add indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_reports_user_id ON public.reports(user_id);
CREATE INDEX IF NOT EXISTS idx_reports_created_at ON public.reports(created_at);

-- SECURITY DEFINER function to check if a random name already exists (bypasses RLS)
CREATE OR REPLACE FUNCTION public.check_random_name_exists(name TEXT)
RETURNS BOOLEAN
SECURITY DEFINER
LANGUAGE sql
AS $$
  SELECT EXISTS (SELECT 1 FROM public.profiles WHERE random_name = name);
$$;