const express = require("express");
const { pool } = require("../../services/db");

const router = express.Router();

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

    let jobListings = 0;
    let students = 0;
    let notes = 0;
    let examsCount = 0;

    try {
      const jobsRes = await pool.query(`SELECT COUNT(*)::int AS count FROM internships`);
      jobListings = Number(jobsRes.rows[0]?.count) || 0;
    } catch (_) {}

    try {
      const enrollRes = await pool.query(`SELECT COUNT(DISTINCT student_id)::int AS count FROM internship_enrollments`);
      students = Number(enrollRes.rows[0]?.count) || 0;
    } catch (_) {}

    try {
      const notesRes = await pool.query(`SELECT COUNT(*)::int AS count FROM academic_materials`);
      notes = Number(notesRes.rows[0]?.count) || 0;
    } catch (_) {}

    try {
      const examsRes = await pool.query(`SELECT COUNT(*)::int AS count FROM competitive_exams`);
      examsCount = Number(examsRes.rows[0]?.count) || 0;
    } catch (_) {}

    res.json({
      students,
      notes,
      jobListings,
      examsCount,
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
  let recentNotes = [];
  let recentJobs = [];
  let recentExams = [];
  let allStudents = [];

  try {
    const notesRes = await pool.query(`
      SELECT id, title, content_type AS "contentType", unit, file_url AS "fileUrl", uploaded_at AS "uploadedAt", branch, semester
      FROM academic_materials
      ORDER BY uploaded_at DESC
    `);
    recentNotes = notesRes.rows.map(n => ({
      id: n.id,
      title: n.title,
      contentType: n.contentType,
      unit: n.unit,
      fileUrl: n.fileUrl,
      uploadedAt: n.uploadedAt ? new Date(n.uploadedAt).toISOString() : new Date().toISOString(),
      subject: {
        name: n.title,
        code: n.branch || "GEN",
        branch: n.branch || "GEN",
        semester: n.semester || 1,
      },
    }));
  } catch (err) {}

  try {
    const jobsRes = await pool.query(`
      SELECT
        id, title, company, type, branch, apply_url AS "applyUrl",
        file_url AS "fileUrl", posted_at AS "postedAt"
      FROM internships
      ORDER BY posted_at DESC
    `);
    recentJobs = jobsRes.rows.map(j => ({
      ...j,
      postedAt: j.postedAt ? new Date(j.postedAt).toISOString() : new Date().toISOString()
    }));
  } catch (err) {}

  try {
    const examsRes = await pool.query(`
      SELECT id, exam_id AS "examId", title, subject, unit, content_type AS "contentType", file_url AS "fileUrl", uploaded_at AS "uploadedAt"
      FROM competitive_exams
      ORDER BY uploaded_at DESC
    `);
    recentExams = examsRes.rows.map(e => ({
      id: e.id,
      name: e.title,
      cat: e.examId,
      subject: e.subject,
      unit: e.unit,
      videos: e.contentType === "VIDEO_LECTURE" ? [{ id: e.id, title: e.title, subject: e.subject, s3Url: e.fileUrl }] : [],
      pdfNotes: e.contentType !== "VIDEO_LECTURE" ? [{ id: e.id, title: e.title, subject: e.subject, fileUrl: e.fileUrl }] : [],
    }));
  } catch (err) {}

  try {
    const studentsRes = await pool.query(`
      SELECT DISTINCT student_id AS id, student_id AS "hallTicket", student_id AS "fullName",
      'All' AS branch, 1 AS semester, enrolled_at AS "createdAt"
      FROM internship_enrollments
      ORDER BY enrolled_at DESC
    `);
    allStudents = studentsRes.rows.map(s => ({
      ...s,
      createdAt: s.createdAt ? new Date(s.createdAt).toISOString() : new Date().toISOString()
    }));
  } catch (err) {}

  res.json({
    recentNotes,
    recentJobs,
    recentExams,
    recentResults: [],
    allStudents,
  });
});

module.exports = router;
