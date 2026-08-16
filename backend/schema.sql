-- Run once against your RDS PostgreSQL database:
--   psql "$DATABASE_URL" -f schema.sql

-- 1) Circulars table
CREATE TABLE IF NOT EXISTS circulars (
  id          BIGSERIAL PRIMARY KEY,
  title       TEXT NOT NULL,
  body        TEXT NOT NULL,
  category    TEXT NOT NULL DEFAULT 'General',
  file_url    TEXT,
  posted_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_circulars_posted_at ON circulars (posted_at DESC);

-- 2) Results AI table
CREATE TABLE IF NOT EXISTS results (
  id          BIGSERIAL PRIMARY KEY,
  student_id  TEXT,
  title       TEXT NOT NULL,
  analysis    JSONB NOT NULL,
  pdf_url     TEXT NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_results_student_id ON results (student_id);
CREATE INDEX IF NOT EXISTS idx_results_created_at ON results (created_at DESC);

-- 3) Dynamic Internship LMS Engine tables
CREATE TABLE IF NOT EXISTS internships (
  id                      TEXT PRIMARY KEY,
  title                   TEXT NOT NULL,
  description             TEXT NOT NULL,
  duration                TEXT NOT NULL,
  level                   TEXT NOT NULL DEFAULT 'Beginner',
  category                TEXT NOT NULL DEFAULT 'Development',
  thumbnail_url           TEXT,
  skills                  JSONB NOT NULL DEFAULT '[]'::jsonb,
  is_certificate_enabled BOOLEAN NOT NULL DEFAULT true,
  certificate_rules       JSONB NOT NULL DEFAULT '{"minVideoPercent": 80, "quizPassPercent": 70, "requireAssignments": true, "requireProject": true}'::jsonb,
  status                  TEXT NOT NULL DEFAULT 'published', -- 'draft' | 'published'
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS internship_modules (
  id             TEXT PRIMARY KEY,
  internship_id  TEXT NOT NULL REFERENCES internships(id) ON DELETE CASCADE,
  title          TEXT NOT NULL,
  description    TEXT,
  order_index    INT NOT NULL DEFAULT 1,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_modules_internship ON internship_modules (internship_id, order_index);

CREATE TABLE IF NOT EXISTS internship_lessons (
  id                 TEXT PRIMARY KEY,
  module_id          TEXT NOT NULL REFERENCES internship_modules(id) ON DELETE CASCADE,
  title              TEXT NOT NULL,
  description        TEXT,
  type               TEXT NOT NULL DEFAULT 'video', -- 'video' | 'pdf' | 'article' | 'quiz' | 'assignment' | 'project'
  video_url          TEXT,
  thumbnail_url      TEXT,
  pdf_url            TEXT,
  duration_seconds   INT NOT NULL DEFAULT 0,
  order_index        INT NOT NULL DEFAULT 1,
  is_required        BOOLEAN NOT NULL DEFAULT true,
  is_published       BOOLEAN NOT NULL DEFAULT true,
  quiz_questions     JSONB DEFAULT '[]'::jsonb,
  assignment_details JSONB DEFAULT '{}'::jsonb,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_lessons_module ON internship_lessons (module_id, order_index);

CREATE TABLE IF NOT EXISTS video_progress (
  id               BIGSERIAL PRIMARY KEY,
  student_id       TEXT NOT NULL,
  lesson_id        TEXT NOT NULL REFERENCES internship_lessons(id) ON DELETE CASCADE,
  watched_seconds  INT NOT NULL DEFAULT 0,
  total_seconds    INT NOT NULL DEFAULT 0,
  percentage       NUMERIC(5,2) NOT NULL DEFAULT 0,
  completed        BOOLEAN NOT NULL DEFAULT false,
  last_position    INT NOT NULL DEFAULT 0,
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (student_id, lesson_id)
);
CREATE INDEX IF NOT EXISTS idx_video_progress_student ON video_progress (student_id);

CREATE TABLE IF NOT EXISTS internship_submissions (
  id             TEXT PRIMARY KEY,
  student_id     TEXT NOT NULL,
  internship_id  TEXT NOT NULL REFERENCES internships(id) ON DELETE CASCADE,
  lesson_id      TEXT NOT NULL REFERENCES internship_lessons(id) ON DELETE CASCADE,
  type           TEXT NOT NULL DEFAULT 'assignment', -- 'assignment' | 'project'
  github_url     TEXT,
  live_url       TEXT,
  file_url       TEXT,
  report_url     TEXT,
  screenshots    JSONB DEFAULT '[]'::jsonb,
  status         TEXT NOT NULL DEFAULT 'pending', -- 'pending' | 'approved' | 'rejected'
  score          INT,
  feedback       TEXT,
  submitted_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  reviewed_at    TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_submissions_student ON internship_submissions (student_id);
CREATE INDEX IF NOT EXISTS idx_submissions_internship ON internship_submissions (internship_id);

CREATE TABLE IF NOT EXISTS student_certificates (
  id                 TEXT PRIMARY KEY,
  student_id         TEXT NOT NULL,
  internship_id      TEXT NOT NULL REFERENCES internships(id) ON DELETE CASCADE,
  certificate_number TEXT NOT NULL UNIQUE,
  pdf_url            TEXT NOT NULL,
  verification_token TEXT NOT NULL UNIQUE,
  issued_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (student_id, internship_id)
);
CREATE INDEX IF NOT EXISTS idx_certificates_student ON student_certificates (student_id);
