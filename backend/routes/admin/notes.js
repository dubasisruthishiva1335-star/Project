const express = require("express");
const crypto = require("crypto");
const { Pool } = require("pg");
const { createPresignedUploadUrl } = require("../../services/s3.service");

const router = express.Router();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.DATABASE_URL ? { rejectUnauthorized: false } : false,
});

// Ensure academic_materials table exists
pool.query(`
  CREATE TABLE IF NOT EXISTS academic_materials (
    id            VARCHAR(100) PRIMARY KEY,
    title         VARCHAR(255) NOT NULL,
    branch        VARCHAR(100) NOT NULL DEFAULT 'GENERAL',
    semester      INTEGER NOT NULL DEFAULT 1,
    unit          INTEGER NOT NULL DEFAULT 1,
    content_type  VARCHAR(64) NOT NULL DEFAULT 'NOTES',
    file_url      TEXT NOT NULL,
    s3_key        TEXT,
    uploaded_at   TIMESTAMP NOT NULL DEFAULT NOW()
  );
`).catch(console.error);

function generateId(prefix) {
  return `${prefix}_${Date.now()}_${crypto.randomBytes(5).toString("hex")}`;
}

/**
 * GET /admin/notes
 */
router.get("/", async (req, res) => {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS academic_materials (
        id            VARCHAR(100) PRIMARY KEY,
        title         VARCHAR(255) NOT NULL,
        branch        VARCHAR(100) NOT NULL DEFAULT 'GENERAL',
        semester      INTEGER NOT NULL DEFAULT 1,
        unit          INTEGER NOT NULL DEFAULT 1,
        content_type  VARCHAR(64) NOT NULL DEFAULT 'NOTES',
        file_url      TEXT NOT NULL,
        s3_key        TEXT,
        uploaded_at   TIMESTAMP NOT NULL DEFAULT NOW()
      );
    `);
    const result = await pool.query(
      `SELECT * FROM academic_materials ORDER BY uploaded_at DESC`
    );
    res.json(result.rows);
  } catch (err) {
    console.error("Fetch academic materials error:", err);
    res.status(500).json({ error: "Failed to fetch academic materials" });
  }
});

/**
 * POST /admin/notes/confirm
 * Create or save an academic note/material record after S3 upload
 */
router.post("/confirm", async (req, res) => {
  const {
    id: bodyId,
    title,
    branch = "GENERAL",
    semester = 1,
    unit = 1,
    contentType = "NOTES",
    fileUrl,
    publicUrl,
    s3Key,
    key,
  } = req.body;

  const noteId = bodyId || generateId("note");
  const finalFileUrl = publicUrl || fileUrl || "";

  try {
    await pool.query(
      `
      INSERT INTO academic_materials (
        id, title, branch, semester, unit, content_type, file_url, s3_key, uploaded_at
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW())
      ON CONFLICT (id) DO UPDATE SET
        title = EXCLUDED.title,
        branch = EXCLUDED.branch,
        semester = EXCLUDED.semester,
        unit = EXCLUDED.unit,
        content_type = EXCLUDED.content_type,
        file_url = EXCLUDED.file_url,
        s3_key = EXCLUDED.s3_key
      `,
      [
        noteId,
        title || "Academic Resource",
        branch || "GENERAL",
        Number(semester) || 1,
        Number(unit) || 1,
        contentType || "NOTES",
        finalFileUrl,
        s3Key || key || null,
      ]
    );

    const result = await pool.query(`SELECT * FROM academic_materials WHERE id = $1`, [noteId]);
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error("Notes confirm error:", err);
    res.status(500).json({ error: "Failed to save academic material", details: err.message });
  }
});

/**
 * DELETE /admin/notes/:id
 */
router.delete("/:id", async (req, res) => {
  try {
    await pool.query(`DELETE FROM academic_materials WHERE id = $1`, [req.params.id]);
    res.json({ success: true, id: req.params.id });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to delete academic material" });
  }
});

module.exports = router;
