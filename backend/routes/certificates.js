const express = require("express");
const { Pool } = require("pg");

const router = express.Router();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.DATABASE_URL ? { rejectUnauthorized: false } : false,
});

/**
 * GET /certificates/:certificateNumber
 * Public verification — QR code verification page endpoint.
 */
router.get("/:certificateNumber", async (req, res) => {
  try {
    const result = await pool.query(
      `
      SELECT certificate_number, student_name, course_title, issued_at, internship_id, certificate_url
      FROM internship_certificates
      WHERE certificate_number = $1 OR id = $1
      LIMIT 1
      `,
      [req.params.certificateNumber]
    );

    if (!result.rows.length) {
      return res.status(404).json({ valid: false, error: "Certificate not found" });
    }

    const c = result.rows[0];

    res.json({
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
  } catch (err) {
    console.error(err);
    res.status(500).json({ valid: false, error: "Verification failed" });
  }
});

module.exports = router;
