-- Migrate legacy grade values (10/11/12) to grades.id (1/2/3).
-- The `grades` table is now the single source of truth for grade values
-- (stored in profiles.grade, exams.grade, and auth.users user_metadata).

UPDATE public.profiles
SET grade = CASE grade
    WHEN 10 THEN 1
    WHEN 11 THEN 2
    WHEN 12 THEN 3
    ELSE grade
  END
WHERE grade IN (10, 11, 12);

-- Keep user_metadata in sync so handle_new_user / sync_profile_from_metadata
-- write the new values on future updates.
UPDATE auth.users
SET raw_user_meta_data = raw_user_meta_data || jsonb_build_object(
    'grade',
    CASE (raw_user_meta_data->>'grade')::int
      WHEN 10 THEN 1
      WHEN 11 THEN 2
      WHEN 12 THEN 3
      ELSE (raw_user_meta_data->>'grade')::int
    END
  )
WHERE raw_user_meta_data->>'grade' IN ('10', '11', '12');
