const express = require("express");
const { Pool } = require("pg");

const router = express.Router();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.DATABASE_URL ? { rejectUnauthorized: false } : false,
});

/**
 * GET /admin/analytics/overview
 */
router.get("/overview", async (req, res) => {
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

    const jobsRes = await pool.query(`SELECT COUNT(*)::int AS count FROM internships`);
    const enrollRes = await pool.query(`SELECT COUNT(DISTINCT student_id)::int AS count FROM internship_enrollments`);
    const notesRes = await pool.query(`SELECT COUNT(*)::int AS count FROM academic_materials`);

    const jobListings = jobsRes.rows[0]?.count || 0;
    const students = enrollRes.rows[0]?.count || 0;
    const notes = notesRes.rows[0]?.count || 0;

    res.json({
      students,
      notes,
      jobListings,
      examsCount: 0,
      results: 0,
    });
  } catch (err) {
    console.error("Overview error:", err);
    res.json({
      students: 0,
      notes: 0,
      jobListings: 0,
      examsCount: 0,
      results: 0,
    });
  }
});

/**
 * GET /admin/analytics/recent-uploads
 */
router.get("/recent-uploads", async (req, res) => {
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
    const notesRes = await pool.query(`
      SELECT id, title, content_type AS "contentType", unit, file_url AS "fileUrl", uploaded_at AS "uploadedAt", branch, semester
      FROM academic_materials
      ORDER BY uploaded_at DESC
    `);

    const jobsRes = await pool.query(`
      SELECT
        id, title, company, type, branch, apply_url AS "applyUrl",
        file_url AS "fileUrl", posted_at AS "postedAt"
      FROM internships
      ORDER BY posted_at DESC
    `);

    const studentsRes = await pool.query(`
      SELECT DISTINCT student_id AS id, student_id AS "hallTicket", student_id AS "fullName",
      'All' AS branch, 1 AS semester, enrolled_at AS "createdAt"
      FROM internship_enrollments
      ORDER BY enrolled_at DESC
    `);

    res.json({
      recentNotes: notesRes.rows.map(n => ({
        id: n.id,
        title: n.title,
        contentType: n.contentType,
        unit: n.unit,
        fileUrl: n.fileUrl,
        uploadedAt: n.uploadedAt ? new Date(n.uploadedAt).toISOString() : new Date().toISOString(),
        subject: {
          name: n.title,
          code: n.branch,
          branch: n.branch,
          semester: n.semester,
        },
      })),
      recentJobs: jobsRes.rows.map(j => ({
        ...j,
        postedAt: j.postedAt ? new Date(j.postedAt).toISOString() : new Date().toISOString()
      })),
      recentExams: [],
      recentResults: [],
      allStudents: studentsRes.rows.map(s => ({
        ...s,
        createdAt: s.createdAt ? new Date(s.createdAt).toISOString() : new Date().toISOString()
      })),
    });
  } catch (err) {
    console.error("Recent uploads error:", err);
    res.json({
      recentNotes: [],
      recentJobs: [],
      recentExams: [],
      recentResults: [],
      allStudents: [],
    });
  }
});

module.exports = router;
