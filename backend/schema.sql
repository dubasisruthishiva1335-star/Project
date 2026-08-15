-- Run once against your RDS PostgreSQL database:
--   psql "$DATABASE_URL" -f schema.sql

CREATE TABLE IF NOT EXISTS circulars (
  id          BIGSERIAL PRIMARY KEY,
  title       TEXT NOT NULL,
  body        TEXT NOT NULL,
  category    TEXT NOT NULL DEFAULT 'General',
  file_url    TEXT,
  posted_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_circulars_posted_at ON circulars (posted_at DESC);

CREATE TABLE IF NOT EXISTS results (
  id          BIGSERIAL PRIMARY KEY,
  student_id  TEXT,
  title       TEXT NOT NULL,
  analysis    JSONB NOT NULL,   -- full AI analysis object (subjects, sgpa, cgpa, summary, ...)
  pdf_url     TEXT NOT NULL,    -- S3 object URL of the generated styled PDF
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_results_student_id ON results (student_id);
CREATE INDEX IF NOT EXISTS idx_results_created_at ON results (created_at DESC);
