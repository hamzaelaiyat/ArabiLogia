-- Migration: Schema hardening part 2
-- 1. Add updated_at trigger on exam_results
-- 2. Fix check_random_name_exists with search_path
-- 3. Simplify grade rate-limiting logic in check_grade_update_limit()

-- ============================================
-- 1. updated_at trigger for exam_results
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
-- 2. Fix check_random_name_exists with search_path
-- ============================================

CREATE OR REPLACE FUNCTION public.check_random_name_exists(name TEXT)
RETURNS BOOLEAN
SECURITY DEFINER
SET search_path = public
LANGUAGE sql
AS $$
  SELECT EXISTS (SELECT 1 FROM public.profiles WHERE random_name = name);
$$;

-- ============================================
-- 3. Simplify grade rate-limiting logic
-- ============================================

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
