const PDFDocument = require("pdfkit");
const QRCode = require("qrcode");
const crypto = require("crypto");
const { Pool } = require("pg");
const { uploadBuffer, publicS3Url } = require("./s3.service");

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.DATABASE_URL ? { rejectUnauthorized: false } : false,
});

function randomCode(length = 12) {
  return crypto.randomBytes(length).toString("hex").toUpperCase();
}

function certificateNumber() {
  const year = new Date().getFullYear();
  return `MV-${year}-${Date.now()}-${crypto
    .randomBytes(3)
    .toString("hex")
    .toUpperCase()}`;
}

function createPdf({ studentName, courseTitle, certificateNo, issuedAt, qrBuffer }) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    const doc = new PDFDocument({ size: "A4", margin: 0 });

    doc.on("data", (chunk) => chunks.push(chunk));
    doc.on("end", () => resolve(Buffer.concat(chunks)));
    doc.on("error", reject);

    const width = doc.page.width;
    const height = doc.page.height;

    doc.rect(0, 0, width, height).fill("#08111f");

    doc.lineWidth(4).strokeColor("#22d3ee")
      .rect(35, 35, width - 70, height - 70).stroke();

    doc.lineWidth(1).strokeColor("#ffffff").opacity(0.25)
      .rect(48, 48, width - 96, height - 96).stroke();

    doc.opacity(1);

    doc.font("Helvetica-Bold").fontSize(18).fillColor("#22d3ee")
      .text("MYVAULT HUB", 0, 90, { align: "center" });

    doc.font("Helvetica-Bold").fontSize(34).fillColor("#ffffff")
      .text("CERTIFICATE", 0, 145, { align: "center" });

    doc.font("Helvetica").fontSize(16).fillColor("#94a3b8")
      .text("OF COMPLETION", 0, 188, { align: "center" });

    doc.font("Helvetica").fontSize(14).fillColor("#cbd5e1")
      .text("This certificate is proudly presented to", 0, 260, { align: "center" });

    doc.font("Helvetica-Bold").fontSize(30).fillColor("#ffffff")
      .text(studentName || "Student", 70, 300, { width: width - 140, align: "center" });

    doc.lineWidth(1).strokeColor("#22d3ee")
      .moveTo(150, 350).lineTo(width - 150, 350).stroke();

    doc.font("Helvetica").fontSize(14).fillColor("#cbd5e1")
      .text("has successfully completed", 0, 385, { align: "center" });

    doc.font("Helvetica-Bold").fontSize(23).fillColor("#22d3ee")
      .text(courseTitle || "Internship Course", 80, 425, { width: width - 160, align: "center" });

    doc.font("Helvetica").fontSize(13).fillColor("#94a3b8")
      .text("All required learning modules and lessons have been completed.", 70, 475, {
        width: width - 140,
        align: "center",
      });

    doc.font("Helvetica").fontSize(12).fillColor("#cbd5e1")
      .text(`Issued: ${issuedAt}`, 70, 555, { width: 220, align: "left" });

    doc.font("Helvetica").fontSize(11).fillColor("#94a3b8")
      .text(`Certificate No: ${certificateNo}`, 70, 580, { width: 350 });

    if (qrBuffer) {
      doc.image(qrBuffer, width - 190, 535, { width: 100, height: 100 });
      doc.font("Helvetica").fontSize(9).fillColor("#94a3b8")
        .text("Scan to verify", width - 205, 642, { width: 130, align: "center" });
    }

    doc.font("Helvetica").fontSize(10).fillColor("#64748b")
      .text("MyVault Hub • Internship & Learning Management System", 0, height - 80, {
        align: "center",
      });

    doc.end();
  });
}

/**
 * Generates (or returns the existing) certificate for a student on a course.
 * Idempotent: calling this twice for the same student+course returns the
 * same certificate rather than creating a duplicate.
 *
 * Throws if the course isn't found, has no lessons, or the student hasn't
 * completed every required lesson yet.
 */
async function generateCertificate({ internshipId, studentId, studentName = null }) {
  const existing = await pool.query(
    `SELECT * FROM internship_certificates WHERE internship_id = $1 AND student_id = $2 LIMIT 1`,
    [internshipId, studentId]
  );
  if (existing.rows.length) return existing.rows[0];

  const courseResult = await pool.query(
    `SELECT id, title, company, certificate_enabled FROM internships WHERE id = $1`,
    [internshipId]
  );
  if (!courseResult.rows.length) throw new Error("Course not found");

  const course = courseResult.rows[0];
  if (!course.certificate_enabled) {
    throw new Error("Certificates are not enabled for this course");
  }

  const lessonResult = await pool.query(
    `
    SELECT COUNT(*)::int AS total
    FROM internship_lessons l
    JOIN internship_modules m ON m.id = l.module_id
    WHERE m.internship_id = $1 AND l.is_required = TRUE
    `,
    [internshipId]
  );

  const completedResult = await pool.query(
    `
    SELECT COUNT(DISTINCT lp.lesson_id)::int AS completed
    FROM internship_lesson_progress lp
    JOIN internship_lessons l ON l.id = lp.lesson_id
    JOIN internship_modules m ON m.id = l.module_id
    WHERE m.internship_id = $1 AND lp.student_id = $2 AND l.is_required = TRUE
    `,
    [internshipId, studentId]
  );

  const total = lessonResult.rows[0].total;
  const completed = completedResult.rows[0].completed;

  if (total === 0) throw new Error("Course has no required lessons");
  if (completed < total) {
    throw new Error(`Course is not complete. ${completed}/${total} lessons completed.`);
  }

  const certificateNo = certificateNumber();
  const verificationCode = randomCode(12);
  const issuedAt = new Date().toLocaleDateString("en-IN");

  const verifyBase = process.env.CERTIFICATE_VERIFY_URL || "https://your-domain.com/verify";
  const verificationUrl = `${verifyBase}/${encodeURIComponent(certificateNo)}`;

  const qrBuffer = await QRCode.toBuffer(verificationUrl, {
    width: 300,
    margin: 2,
    color: { dark: "#08111f", light: "#ffffff" },
  });

  const pdfBuffer = await createPdf({
    studentName: studentName || studentId,
    courseTitle: course.title,
    certificateNo,
    issuedAt,
    qrBuffer,
  });

  const key = `certificates/${certificateNo}.pdf`;

  const certificateUrl = await uploadBuffer({
    key,
    body: pdfBuffer,
    contentType: "application/pdf",
    contentDisposition: `inline; filename="${certificateNo}.pdf"`,
  });

  const certificateId = `cert_${Date.now()}_${crypto.randomBytes(5).toString("hex")}`;

  const inserted = await pool.query(
    `
    INSERT INTO internship_certificates (
      id, internship_id, student_id, certificate_url, issued_at,
      certificate_number, verification_code, student_name, course_title, certificate_file_key
    )
    VALUES ($1,$2,$3,$4,NOW(),$5,$6,$7,$8,$9)
    ON CONFLICT (internship_id, student_id) DO NOTHING
    RETURNING *
    `,
    [
      certificateId,
      internshipId,
      studentId,
      certificateUrl,
      certificateNo,
      verificationCode,
      studentName || studentId,
      course.title,
      key,
    ]
  );

  if (inserted.rows.length) return inserted.rows[0];

  const winner = await pool.query(
    `SELECT * FROM internship_certificates WHERE internship_id = $1 AND student_id = $2 LIMIT 1`,
    [internshipId, studentId]
  );
  return winner.rows[0];
}

module.exports = { generateCertificate };
