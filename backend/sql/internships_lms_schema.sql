-- =================================================================
-- PostgreSQL Schema for Two-Mode Internships & Jobs LMS Platform
-- =================================================================

-- 1. Main Internships Table (Supports both Plain Listings & Full LMS Courses)
CREATE TABLE IF NOT EXISTS internships (
  id VARCHAR(64) PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  company VARCHAR(255) NOT NULL,
  type VARCHAR(32) NOT NULL DEFAULT 'INTERNSHIP', -- 'INTERNSHIP' | 'PLACEMENT' | 'GOVT_JOB'
  is_lms_enabled BOOLEAN NOT NULL DEFAULT FALSE,  -- false = Plain Apply Link, true = Full LMS Course
  branch VARCHAR(64) DEFAULT 'All Branches',
  stipend VARCHAR(128),
  location VARCHAR(128),
  deadline DATE,
  description TEXT,
  apply_url TEXT,
  file_url TEXT,
  s3_key TEXT,
  posted_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. LMS Course Modules
CREATE TABLE IF NOT EXISTS internship_modules (
  id VARCHAR(64) PRIMARY KEY,
  internship_id VARCHAR(64) NOT NULL REFERENCES internships(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  sort_order INT NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. LMS Module Lessons
CREATE TABLE IF NOT EXISTS internship_lessons (
  id VARCHAR(64) PRIMARY KEY,
  module_id VARCHAR(64) NOT NULL REFERENCES internship_modules(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  content_type VARCHAR(32) NOT NULL DEFAULT 'VIDEO', -- 'VIDEO' | 'PDF' | 'ARTICLE' | 'QUIZ' | 'ASSIGNMENT'
  video_url TEXT,
  pdf_url TEXT,
  description TEXT,
  duration VARCHAR(32) DEFAULT '15 mins',
  sort_order INT NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. Student Course Enrollments
CREATE TABLE IF NOT EXISTS internship_enrollments (
  id VARCHAR(64) PRIMARY KEY,
  internship_id VARCHAR(64) NOT NULL REFERENCES internships(id) ON DELETE CASCADE,
  student_id VARCHAR(64) NOT NULL,
  enrolled_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(internship_id, student_id)
);

-- 5. Lesson Progress & Completion Tracking
CREATE TABLE IF NOT EXISTS internship_lesson_progress (
  id VARCHAR(64) PRIMARY KEY,
  lesson_id VARCHAR(64) NOT NULL REFERENCES internship_lessons(id) ON DELETE CASCADE,
  student_id VARCHAR(64) NOT NULL,
  completed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(lesson_id, student_id)
);

-- 6. Issued Industrial Certificates
CREATE TABLE IF NOT EXISTS internship_certificates (
  id VARCHAR(64) PRIMARY KEY,
  internship_id VARCHAR(64) NOT NULL REFERENCES internships(id) ON DELETE CASCADE,
  student_id VARCHAR(64) NOT NULL,
  certificate_url TEXT NOT NULL,
  issued_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(internship_id, student_id)
);
