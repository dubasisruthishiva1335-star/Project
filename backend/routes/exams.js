const express = require("express");
const { pool } = require("../services/db");

const router = express.Router();

async function ensureExamsTable() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS competitive_exams (
      id            VARCHAR(100) PRIMARY KEY,
      exam_id       VARCHAR(100) NOT NULL DEFAULT 'upsc-cse-2026',
      title         VARCHAR(255) NOT NULL,
      subject       VARCHAR(100) NOT NULL DEFAULT 'General',
      unit          VARCHAR(50) NOT NULL DEFAULT '1',
      content_type  VARCHAR(64) NOT NULL DEFAULT 'NOTES',
      file_url      TEXT NOT NULL,
      s3_key        TEXT,
      uploaded_at   TIMESTAMP NOT NULL DEFAULT NOW()
    );
  `);
}

/**
 * GET /exams (and /competitive-exams)
 * Query parameters: examId, subject, contentType
 */
router.get("/", async (req, res) => {
  const { examId, subject, contentType } = req.query;

  try {
    await ensureExamsTable();

    let query = `SELECT * FROM competitive_exams WHERE 1=1`;
    const params = [];

    if (examId && examId !== "ALL" && examId !== "All") {
      params.push(examId);
      query += ` AND LOWER(exam_id) LIKE LOWER($${params.length})`;
    }

    if (subject && subject !== "ALL" && subject !== "All") {
      params.push(subject);
      query += ` AND LOWER(subject) LIKE LOWER($${params.length})`;
    }

    if (contentType && contentType !== "ALL") {
      params.push(String(contentType).toUpperCase());
      query += ` AND UPPER(content_type) = $${params.length}`;
    }

    query += ` ORDER BY uploaded_at DESC`;

    const result = await pool.query(query, params);

    const formatted = result.rows.map((row) => ({
      id: row.id,
      examId: row.exam_id,
      title: row.title,
      subject: row.subject,
      unit: row.unit,
      contentType: row.content_type,
      fileUrl: row.file_url,
      s3Key: row.s3_key,
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
