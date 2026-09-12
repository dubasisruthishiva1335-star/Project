const express = require("express");
const { Pool } = require("pg");

const router = express.Router();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.DATABASE_URL ? { rejectUnauthorized: false } : false,
});

/**
 * GET /certificates/all
 * List all earned / pending certificates for admin gradebook.
 */
router.get("/all", async (req, res) => {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS internship_certificates (
        id                 VARCHAR(100) PRIMARY KEY,
        certificate_number VARCHAR(100) UNIQUE NOT NULL,
        student_id         VARCHAR(100) NOT NULL,
        student_name       VARCHAR(255) NOT NULL,
        internship_id      VARCHAR(100) NOT NULL,
        course_title       VARCHAR(255) NOT NULL,
        college            VARCHAR(255),
        email              VARCHAR(255),
        score              INTEGER NOT NULL DEFAULT 85,
        issued_at          TIMESTAMP NOT NULL DEFAULT NOW(),
        ready_at           TIMESTAMP NOT NULL DEFAULT NOW() + INTERVAL '24 hours',
        status             VARCHAR(50) NOT NULL DEFAULT 'PENDING_24H_REVIEW',
        certificate_url    TEXT,
        is_valid           BOOLEAN NOT NULL DEFAULT true
      );
    `);

    const result = await pool.query(`
      SELECT
        id,
        certificate_number AS "certNumber",
        student_name AS "studentName",
        course_title AS "courseTitle",
        college,
        email,
        score AS "overallScore",
        score AS "finalExamScore",
        85 AS "quizScore",
        100 AS "lessonProgress",
        status AS "certStatus",
        issued_at AS "submittedAt",
        certificate_url AS "certificateUrl"
      FROM internship_certificates
      ORDER BY issued_at DESC
    `);

    res.json(result.rows);
  } catch (err) {
    console.error("Certificates all error:", err);
    res.json([]);
  }
});

/**
 * GET /certificates/:certificateNumber
 * Public verification — QR code verification page endpoint.
 */
router.get("/:certificateNumber", async (req, res) => {
  const certNum = req.params.certificateNumber;
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS internship_certificates (
        id                 VARCHAR(100) PRIMARY KEY,
        certificate_number VARCHAR(100) UNIQUE NOT NULL,
        student_id         VARCHAR(100) NOT NULL,
        student_name       VARCHAR(255) NOT NULL,
        internship_id      VARCHAR(100) NOT NULL,
        course_title       VARCHAR(255) NOT NULL,
        score              INTEGER NOT NULL DEFAULT 85,
        issued_at          TIMESTAMP NOT NULL DEFAULT NOW(),
        certificate_url    TEXT,
        is_valid           BOOLEAN NOT NULL DEFAULT true
      );
    `);

    const result = await pool.query(
      `
      SELECT certificate_number, student_name, course_title, issued_at, internship_id, certificate_url
      FROM internship_certificates
      WHERE certificate_number = $1 OR id = $1
      LIMIT 1
      `,
      [certNum]
    );

    if (result.rows.length) {
      const c = result.rows[0];
      return res.json({
        valid: true,
        certificate: {
          certificateNumber: c.certificate_number,
          studentName: c.student_name,
          courseTitle: c.course_title,
          issuedAt: c.issued_at,
          internshipId: c.internship_id,
          certificateUrl: c.certificate_url,
        },
      });
    }

    return res.status(404).json({ valid: false, error: "Certificate not found" });
  } catch (err) {
    console.error("Certificate route error:", err);
    res.status(500).json({ valid: false, error: "Verification failed" });
  }
});

module.exports = router;
