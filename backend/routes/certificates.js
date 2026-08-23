const express = require("express");
const { Pool } = require("pg");
const { generateCertificate } = require("../services/certificate.service");

const router = express.Router();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL || "postgresql://postgres:postgres@localhost:5432/myvault",
  ssl: process.env.DATABASE_URL ? { rejectUnauthorized: false } : false,
});

// POST /certificates/generate — Generate certificate on course completion
router.post("/generate", async (req, res) => {
  try {
    const { internshipId, studentId, studentName } = req.body;
    if (!internshipId || !studentId) {
      return res.status(400).json({ error: "internshipId and studentId are required" });
    }

    const certificate = await generateCertificate({
      internshipId,
      studentId,
      studentName,
    });

    res.json({ success: true, certificate });
  } catch (error) {
    console.error("Certificate generation error:", error);
    res.status(400).json({ success: false, error: error.message });
  }
});

// GET /certificates/:certificateNumber — Public QR verification
router.get("/:certificateNumber", async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT id, internship_id, student_id, certificate_url, issued_at FROM internship_certificates WHERE id = $1 OR certificate_url LIKE $2 LIMIT 1`,
      [req.params.certificateNumber, `%${req.params.certificateNumber}%`]
    );

    if (!result.rows.length) {
      return res.status(404).json({ valid: false, error: "Certificate not found" });
    }

    const cert = result.rows[0];
    res.json({
      valid: true,
      certificate: {
        certificateId: cert.id,
        studentId: cert.student_id,
        certificateUrl: cert.certificate_url,
        issuedAt: cert.issued_at,
      },
    });
  } catch (error) {
    res.status(500).json({ valid: false, error: "Verification failed" });
  }
});

module.exports = router;
