-- Create lectures table
CREATE TABLE lectures (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  course_id TEXT NOT NULL REFERENCES categories(id),
  youtube_url TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  quiz_id TEXT REFERENCES exams(id) ON DELETE SET NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  grade INTEGER NOT NULL DEFAULT 1,
  is_published BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- RLS
ALTER TABLE lectures ENABLE ROW LEVEL SECURITY;

-- Students see published lectures matching their grade
CREATE POLICY "Students view published lectures"
  ON lectures FOR SELECT
  USING (
    is_published = true
    AND (
      grade = (
        CASE
          WHEN (SELECT grade FROM profiles WHERE id = auth.uid()) BETWEEN 10 AND 12
          THEN (SELECT grade FROM profiles WHERE id = auth.uid()) - 9
          ELSE grade
        END
      )
      OR EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid()
        AND role IN ('teacher', 'admin')
      )
    )
  );

-- Teachers/admins can manage all lectures
CREATE POLICY "Teachers manage lectures"
  ON lectures FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND role IN ('teacher', 'admin')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND role IN ('teacher', 'admin')
    )
  );

-- Indexes
CREATE INDEX idx_lectures_course_id ON lectures(course_id);
CREATE INDEX idx_lectures_grade ON lectures(grade);
CREATE INDEX idx_lectures_sort_order ON lectures(sort_order);
