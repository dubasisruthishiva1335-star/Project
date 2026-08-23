const express = require("express");
const { Pool } = require("pg");

const router = express.Router();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.DATABASE_URL ? { rejectUnauthorized: false } : false,
});

/**
 * GET /notes (and /academic/content and /subjects)
 * Query parameters: branch, semester, unit, contentType
 */
router.get("/", async (req, res) => {
  const { branch, semester, unit, contentType } = req.query;

  try {
    let query = `SELECT * FROM academic_materials WHERE 1=1`;
    const params = [];

    if (branch && branch !== "ALL" && branch !== "General") {
      params.push(branch);
      query += ` AND (branch = $${params.length} OR branch = 'GENERAL')`;
    }

    if (semester) {
      params.push(Number(semester));
      query += ` AND semester = $${params.length}`;
    }

    if (unit) {
      params.push(Number(unit));
      query += ` AND unit = $${params.length}`;
    }

    if (contentType) {
      params.push(String(contentType).toUpperCase());
      query += ` AND UPPER(content_type) = $${params.length}`;
    }

    query += ` ORDER BY uploaded_at DESC`;

    const result = await pool.query(query, params);

    // Group materials by subject (title or branch)
    const groupedMap = new Map();

    result.rows.forEach((row) => {
      const subjectName = row.title.split('—')[0].split('-')[0].trim() || "Academic Resources";
      const groupKey = `${row.branch}_${row.semester}_${subjectName}`;

      if (!groupedMap.has(groupKey)) {
        groupedMap.set(groupKey, {
          id: `subj_${row.id}`,
          name: subjectName,
          code: row.branch,
          branch: row.branch,
          semester: row.semester,
          contents: [],
        });
      }

      groupedMap.get(groupKey).contents.push({
        id: row.id,
        title: row.title,
        contentType: row.content_type,
        unit: row.unit,
        fileUrl: row.file_url,
        s3Key: row.s3_key,
        uploadedAt: row.uploaded_at,
      });
    });

    res.json(Array.from(groupedMap.values()));
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to fetch academic materials" });
  }
});

module.exports = router;
