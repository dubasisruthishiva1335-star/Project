const express = require("express");
const crypto = require("crypto");
const { pool } = require("../../services/db");

const router = express.Router();

function generateId(prefix) {
  return `${prefix}_${Date.now()}_${crypto.randomBytes(5).toString("hex")}`;
}

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
 * GET /admin/exams (and /admin/preparation)
 */
router.get("/", async (req, res) => {
  try {
    await ensureExamsTable();
    const result = await pool.query(
      `SELECT * FROM competitive_exams ORDER BY uploaded_at DESC`
    );

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

    res.json({ success: true, data: formatted });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to fetch exam preparation materials" });
  }
});

/**
 * POST /admin/exams/confirm (and /admin/preparation/confirm)
 */
router.post("/confirm", async (req, res) => {
  const {
    id: bodyId,
    examId = "gate-cs-2026",
    examName = "GATE Computer Science & IT",
    category = "ENGINEERING",
    title,
    subject = "General",
    unit = "1",
    contentType = "NOTES",
    year = 2026,
    difficulty = "ALL_LEVELS",
    fileUrl,
    publicUrl,
    s3Key,
    key,
    fileSize = "2.5 MB",
    description = "",
    author = "MyVault Academic Team",
    syllabusUrl = "",
    examDate = "Feb 2026",
    isFeatured = false,
  } = req.body;

  const examRecordId = bodyId || generateId("exam_res");
  const finalKey = s3Key || key || `exams/${examId}/${Date.now()}_material.pdf`;
  const finalFileUrl = publicUrl || fileUrl || `https://myvault-files-app.s3.eu-north-1.amazonaws.com/${finalKey}`;

  try {
    await ensureExamsTable();

    await pool.query(
      `
      INSERT INTO competitive_exams (
        id, exam_id, exam_name, category, title, subject, unit, content_type,
        year, difficulty, file_url, s3_key, file_size, description, author,
        syllabus_url, exam_date, is_featured, uploaded_at
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, NOW())
      ON CONFLICT (id) DO UPDATE SET
        exam_id = EXCLUDED.exam_id,
        exam_name = EXCLUDED.exam_name,
        category = EXCLUDED.category,
        title = EXCLUDED.title,
        subject = EXCLUDED.subject,
        unit = EXCLUDED.unit,
        content_type = EXCLUDED.content_type,
        year = EXCLUDED.year,
        difficulty = EXCLUDED.difficulty,
        file_url = EXCLUDED.file_url,
        s3_key = EXCLUDED.s3_key,
        file_size = EXCLUDED.file_size,
        description = EXCLUDED.description,
        author = EXCLUDED.author,
        syllabus_url = EXCLUDED.syllabus_url,
        exam_date = EXCLUDED.exam_date,
        is_featured = EXCLUDED.is_featured
      `,
      [
        examRecordId,
        examId,
        examName,
        category,
        title || "Preparation Material",
        subject || "General",
        String(unit) || "1",
        contentType || "NOTES",
        Number(year) || 2026,
        difficulty || "ALL_LEVELS",
        finalFileUrl,
        finalKey,
        fileSize,
        description,
        author,
        syllabusUrl,
        examDate,
        Boolean(isFeatured),
      ]
    );

    const result = await pool.query(`SELECT * FROM competitive_exams WHERE id = $1`, [examRecordId]);
    const row = result.rows[0];

    res.status(201).json({
      id: row.id,
      examId: row.exam_id,
      examName: row.exam_name,
      category: row.category,
      title: row.title,
      subject: row.subject,
      unit: row.unit,
      contentType: row.content_type,
      year: row.year,
      difficulty: row.difficulty,
      fileUrl: row.file_url,
      s3Key: row.s3_key,
      fileSize: row.file_size,
      description: row.description,
      author: row.author,
      syllabusUrl: row.syllabus_url,
      examDate: row.exam_date,
      isFeatured: row.is_featured,
      uploadedAt: row.uploaded_at,
    });
  } catch (err) {
    console.error("Exams confirm error:", err);
    res.status(500).json({ error: "Failed to save exam preparation material", details: err.message });
  }
});

/**
 * DELETE /admin/exams/:id
 */
router.delete("/:id", async (req, res) => {
  try {
    await ensureExamsTable();
    await pool.query(`DELETE FROM competitive_exams WHERE id = $1`, [req.params.id]);
    res.json({ success: true, id: req.params.id });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to delete exam preparation material" });
  }
});

module.exports = router;
