-- =========================================================
-- MyVault LMS Internship Hub — Database Schema
-- =========================================================
-- Run this against your PostgreSQL database.
-- Safe to re-run: uses IF NOT EXISTS / ADD COLUMN IF NOT EXISTS
-- =========================================================

-- ---------------------------------------------------------
-- Core course / internship table
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS internships (
  id                   VARCHAR(100) PRIMARY KEY,
  title                VARCHAR(255) NOT NULL,
  company              VARCHAR(255) NOT NULL,
  type                 VARCHAR(32)  NOT NULL DEFAULT 'INTERNSHIP', -- INTERNSHIP | COURSE
  is_lms_enabled       BOOLEAN      NOT NULL DEFAULT FALSE,
  branch               VARCHAR(100) DEFAULT 'All Branches',
  stipend              VARCHAR(100),
  location             VARCHAR(255),
  deadline             TIMESTAMP,
  description          TEXT,
  apply_url            TEXT,
  file_url             TEXT,
  s3_key               TEXT,
  duration             VARCHAR(64),
  certificate_enabled  BOOLEAN      NOT NULL DEFAULT FALSE,
  status               VARCHAR(32)  NOT NULL DEFAULT 'DRAFT', -- DRAFT | PUBLISHED | ARCHIVED
  max_students         INTEGER,
  posted_at            TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- Backfill columns for tables created by earlier versions of this schema
ALTER TABLE internships ADD COLUMN IF NOT EXISTS duration VARCHAR(64);
ALTER TABLE internships ADD COLUMN IF NOT EXISTS certificate_enabled BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE internships ADD COLUMN IF NOT EXISTS status VARCHAR(32) NOT NULL DEFAULT 'DRAFT';
ALTER TABLE internships ADD COLUMN IF NOT EXISTS max_students INTEGER;

-- ---------------------------------------------------------
-- Modules (belong to a course/internship)
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS internship_modules (
  id             VARCHAR(100) PRIMARY KEY,
  internship_id  VARCHAR(100) NOT NULL REFERENCES internships(id) ON DELETE CASCADE,
  title          VARCHAR(255) NOT NULL,
  sort_order     INTEGER NOT NULL DEFAULT 1,
  created_at     TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_modules_internship ON internship_modules(internship_id);

-- ---------------------------------------------------------
-- Lessons (belong to a module)
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS internship_lessons (
  id            VARCHAR(100) PRIMARY KEY,
  module_id     VARCHAR(100) NOT NULL REFERENCES internship_modules(id) ON DELETE CASCADE,
  title         VARCHAR(255) NOT NULL,
  content_type  VARCHAR(32)  NOT NULL DEFAULT 'VIDEO', -- VIDEO | PDF | TEXT | QUIZ | ASSIGNMENT | LINK
  video_url     TEXT,
  pdf_url       TEXT,
  description   TEXT,
  duration      VARCHAR(64),
  sort_order    INTEGER NOT NULL DEFAULT 1,
  is_required   BOOLEAN NOT NULL DEFAULT TRUE,
  created_at    TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_lessons_module ON internship_lessons(module_id);

-- ---------------------------------------------------------
-- Enrollments
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS internship_enrollments (
  id             VARCHAR(100) PRIMARY KEY,
  internship_id  VARCHAR(100) NOT NULL REFERENCES internships(id) ON DELETE CASCADE,
  student_id     VARCHAR(100) NOT NULL,
  enrolled_at    TIMESTAMP NOT NULL DEFAULT NOW(),
  UNIQUE (internship_id, student_id)
);

CREATE INDEX IF NOT EXISTS idx_enrollments_internship ON internship_enrollments(internship_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_student ON internship_enrollments(student_id);

-- ---------------------------------------------------------
-- Lesson progress (one row = one student completed one lesson)
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS internship_lesson_progress (
  id            VARCHAR(100) PRIMARY KEY,
  lesson_id     VARCHAR(100) NOT NULL REFERENCES internship_lessons(id) ON DELETE CASCADE,
  student_id    VARCHAR(100) NOT NULL,
  watch_percent INTEGER DEFAULT 100,
  completed_at  TIMESTAMP NOT NULL DEFAULT NOW(),
  UNIQUE (lesson_id, student_id)
);

CREATE INDEX IF NOT EXISTS idx_progress_student ON internship_lesson_progress(student_id);

-- ---------------------------------------------------------
-- Certificates
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS internship_certificates (
  id                     VARCHAR(100) PRIMARY KEY,
  internship_id          VARCHAR(100) NOT NULL REFERENCES internships(id) ON DELETE CASCADE,
  student_id             VARCHAR(100) NOT NULL,
  certificate_url        TEXT,
  issued_at              TIMESTAMP NOT NULL DEFAULT NOW(),
  certificate_number     VARCHAR(100) UNIQUE,
  verification_code      VARCHAR(100) UNIQUE,
  student_name           VARCHAR(255),
  course_title           VARCHAR(255),
  certificate_file_key   TEXT,
  UNIQUE (internship_id, student_id)
);

CREATE INDEX IF NOT EXISTS idx_certificates_student ON internship_certificates(student_id);

-- Backfill columns for tables created by earlier versions of this schema
ALTER TABLE internship_certificates ADD COLUMN IF NOT EXISTS certificate_number VARCHAR(100) UNIQUE;
ALTER TABLE internship_certificates ADD COLUMN IF NOT EXISTS verification_code VARCHAR(100) UNIQUE;
ALTER TABLE internship_certificates ADD COLUMN IF NOT EXISTS student_name VARCHAR(255);
ALTER TABLE internship_certificates ADD COLUMN IF NOT EXISTS course_title VARCHAR(255);
ALTER TABLE internship_certificates ADD COLUMN IF NOT EXISTS certificate_file_key TEXT;

-- ---------------------------------------------------------
-- Admin users (for real admin authentication)
-- ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS admin_users (
  id             VARCHAR(100) PRIMARY KEY,
  email          VARCHAR(255) UNIQUE NOT NULL,
  password_hash  TEXT NOT NULL,
  name           VARCHAR(255),
  role           VARCHAR(32) NOT NULL DEFAULT 'ADMIN', -- ADMIN | MENTOR
  created_at     TIMESTAMP NOT NULL DEFAULT NOW()
);
