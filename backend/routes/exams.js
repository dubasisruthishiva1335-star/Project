const express = require("express");
const { pool } = require("../services/db");

const router = express.Router();

async function ensureExamsTable() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS competitive_exams (
      id            VARCHAR(100) PRIMARY KEY,
      exam_id       VARCHAR(100) NOT NULL DEFAULT 'gate-cs-2026',
      exam_name     VARCHAR(255) DEFAULT 'GATE Computer Science & IT',
      category      VARCHAR(100) DEFAULT 'ENGINEERING',
      title         VARCHAR(255) NOT NULL,
      subject       VARCHAR(100) NOT NULL DEFAULT 'General',
      unit          VARCHAR(50) NOT NULL DEFAULT '1',
      content_type  VARCHAR(64) NOT NULL DEFAULT 'NOTES',
      year          INTEGER DEFAULT 2026,
      difficulty    VARCHAR(50) DEFAULT 'ALL_LEVELS',
      file_url      TEXT NOT NULL,
      s3_key        TEXT,
      file_size     VARCHAR(50) DEFAULT '2.4 MB',
      description   TEXT,
      author        VARCHAR(255) DEFAULT 'MyVault Academic Team',
      syllabus_url  TEXT,
      exam_date     VARCHAR(100),
      is_featured   BOOLEAN DEFAULT false,
      downloads_count INTEGER DEFAULT 0,
      uploaded_at   TIMESTAMP NOT NULL DEFAULT NOW()
    );
    ALTER TABLE competitive_exams ADD COLUMN IF NOT EXISTS exam_name VARCHAR(255) DEFAULT 'GATE Computer Science & IT';
    ALTER TABLE competitive_exams ADD COLUMN IF NOT EXISTS category VARCHAR(100) DEFAULT 'ENGINEERING';
    ALTER TABLE competitive_exams ADD COLUMN IF NOT EXISTS year INTEGER DEFAULT 2026;
    ALTER TABLE competitive_exams ADD COLUMN IF NOT EXISTS difficulty VARCHAR(50) DEFAULT 'ALL_LEVELS';
    ALTER TABLE competitive_exams ADD COLUMN IF NOT EXISTS file_size VARCHAR(50) DEFAULT '2.4 MB';
    ALTER TABLE competitive_exams ADD COLUMN IF NOT EXISTS description TEXT;
    ALTER TABLE competitive_exams ADD COLUMN IF NOT EXISTS author VARCHAR(255) DEFAULT 'MyVault Academic Team';
    ALTER TABLE competitive_exams ADD COLUMN IF NOT EXISTS syllabus_url TEXT;
    ALTER TABLE competitive_exams ADD COLUMN IF NOT EXISTS exam_date VARCHAR(100);
    ALTER TABLE competitive_exams ADD COLUMN IF NOT EXISTS is_featured BOOLEAN DEFAULT false;
    ALTER TABLE competitive_exams ADD COLUMN IF NOT EXISTS downloads_count INTEGER DEFAULT 0;
  `);
}

/**
 * GET /exams (and /competitive-exams)
 * Query parameters: examId, category, subject, contentType, search
 */
router.get("/", async (req, res) => {
  const { examId, category, subject, contentType, search } = req.query;

  try {
    await ensureExamsTable();

    let query = `SELECT * FROM competitive_exams WHERE 1=1`;
    const params = [];

    if (examId && examId !== "ALL" && examId !== "All") {
      params.push(examId);
      query += ` AND LOWER(exam_id) = LOWER($${params.length})`;
    }

    if (category && category !== "ALL" && category !== "All") {
      params.push(category);
      query += ` AND UPPER(category) = UPPER($${params.length})`;
    }

    if (subject && subject !== "ALL" && subject !== "All") {
      params.push(`%${subject}%`);
      query += ` AND LOWER(subject) LIKE LOWER($${params.length})`;
    }

    if (contentType && contentType !== "ALL" && contentType !== "All") {
      params.push(String(contentType).toUpperCase());
      query += ` AND UPPER(content_type) = $${params.length}`;
    }

    if (search && String(search).trim() !== '') {
      params.push(`%${search.trim()}%`);
      query += ` AND (LOWER(title) LIKE LOWER($${params.length}) OR LOWER(exam_name) LIKE LOWER($${params.length}) OR LOWER(subject) LIKE LOWER($${params.length}))`;
    }

    query += ` ORDER BY is_featured DESC, uploaded_at DESC`;

    const result = await pool.query(query, params);

    const formatted = result.rows.map((row) => ({
      id: row.id,
      examId: row.exam_id,
      examName: row.exam_name || row.exam_id,
      category: row.category || 'ENGINEERING',
      title: row.title,
      subject: row.subject,
      unit: row.unit,
      contentType: row.content_type,
      year: row.year || 2026,
      difficulty: row.difficulty || 'ALL_LEVELS',
      fileUrl: row.file_url,
      s3Key: row.s3_key,
      fileSize: row.file_size || '2.4 MB',
      description: row.description || '',
      author: row.author || 'MyVault Academic Team',
      syllabusUrl: row.syllabus_url || '',
      examDate: row.exam_date || '',
      isFeatured: Boolean(row.is_featured),
      downloadsCount: row.downloads_count || 0,
      uploadedAt: row.uploaded_at,
      createdAt: row.uploaded_at,
    }));

    res.json(formatted);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to fetch exam preparation materials" });
  }
});

module.exports = router;
