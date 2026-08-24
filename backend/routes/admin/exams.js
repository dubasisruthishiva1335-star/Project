const express = require("express");
const crypto = require("crypto");
const { Pool } = require("pg");

const router = express.Router();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.DATABASE_URL ? { rejectUnauthorized: false } : false,
});

function generateId(prefix) {
  return `${prefix}_${Date.now()}_${crypto.randomBytes(5).toString("hex")}`;
}

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
      title: row.title,
      subject: row.subject,
      unit: row.unit,
      contentType: row.content_type,
      fileUrl: row.file_url,
      s3Key: row.s3_key,
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
    examId = "upsc-cse-2026",
    title,
    subject = "General",
    unit = "1",
    contentType = "NOTES",
    fileUrl,
    publicUrl,
    s3Key,
    key,
  } = req.body;

  const examRecordId = bodyId || generateId("exam_res");
  const finalKey = s3Key || key || `exams/${examId}/${Date.now()}_material.pdf`;
  const finalFileUrl = publicUrl || fileUrl || `https://myvault-files-app.s3.eu-north-1.amazonaws.com/${finalKey}`;

  try {
    await ensureExamsTable();

    await pool.query(
      `
      INSERT INTO competitive_exams (
        id, exam_id, title, subject, unit, content_type, file_url, s3_key, uploaded_at
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW())
      ON CONFLICT (id) DO UPDATE SET
        exam_id = EXCLUDED.exam_id,
        title = EXCLUDED.title,
        subject = EXCLUDED.subject,
        unit = EXCLUDED.unit,
        content_type = EXCLUDED.content_type,
        file_url = EXCLUDED.file_url,
        s3_key = EXCLUDED.s3_key
      `,
      [
        examRecordId,
        examId,
        title || "Preparation Material",
        subject || "General",
        String(unit) || "1",
        contentType || "NOTES",
        finalFileUrl,
        finalKey,
      ]
    );

    const result = await pool.query(`SELECT * FROM competitive_exams WHERE id = $1`, [examRecordId]);
    const row = result.rows[0];

    res.status(201).json({
      id: row.id,
      examId: row.exam_id,
      title: row.title,
      subject: row.subject,
      unit: row.unit,
      contentType: row.content_type,
      fileUrl: row.file_url,
      s3Key: row.s3_key,
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
