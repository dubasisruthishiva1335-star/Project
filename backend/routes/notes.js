const express = require("express");
const { pool } = require("../services/db");

const router = express.Router();

/**
 * GET /notes (and /academic/content and /subjects)
 * Query parameters: branch, semester, unit, contentType
 * STRICTLY returns only uploaded materials from the website admin portal.
 */
router.get("/", async (req, res) => {
  const { branch, semester, unit, contentType } = req.query;

  try {
    const result = await pool.query(`SELECT * FROM academic_materials ORDER BY uploaded_at DESC`);
    let rows = result.rows || [];

    // Filter by branch
    if (branch && branch !== "ALL" && branch !== "General" && branch !== "GENERAL") {
      const bNorm = branch.toUpperCase().replace(/\s+/g, "");
      rows = rows.filter((r) => {
        const rowBNorm = (r.branch || "GENERAL").toUpperCase().replace(/\s+/g, "");
        return rowBNorm === bNorm || rowBNorm === "GENERAL" || (bNorm.includes("CSE") && rowBNorm.includes("CSE")) || (bNorm.includes("ECE") && rowBNorm.includes("ECE"));
      });
    }

    // Filter by semester
    if (semester) {
      rows = rows.filter((r) => Number(r.semester) === Number(semester));
    }

    // Filter by unit
    if (unit && Number(unit) > 0) {
      rows = rows.filter((r) => Number(r.unit) === Number(unit));
    }

    // Filter by contentType
    if (contentType && contentType !== "ALL") {
      rows = rows.filter((r) => String(r.content_type).toUpperCase() === String(contentType).toUpperCase());
    }

    // Group uploaded materials by subject name
    const groupedMap = new Map();

    rows.forEach((row) => {
      const subjectName = (row.title || "").split('—')[0].split('-')[0].trim() || "Academic Materials";
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
    console.error("Notes fetch error:", err.message);
    res.json([]);
  }
});

module.exports = router;
