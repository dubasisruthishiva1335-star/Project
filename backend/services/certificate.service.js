const PDFDocument = require("pdfkit");
const QRCode = require("qrcode");
const crypto = require("crypto");
const { S3Client, PutObjectCommand } = require("@aws-sdk/client-s3");
const { Pool } = require("pg");

const pool = new Pool({
  connectionString: process.env.DATABASE_URL || "postgresql://postgres:postgres@localhost:5432/myvault",
  ssl: process.env.DATABASE_URL ? { rejectUnauthorized: false } : false,
});

const REGION = process.env.AWS_REGION || "eu-north-1";
const BUCKET = process.env.S3_BUCKET_NAME || "myvault-files-app";

const s3 = new S3Client({
  region: REGION,
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID || "",
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || "",
  },
});

function randomCode(length = 12) {
  return crypto.randomBytes(length).toString("hex").toUpperCase();
}

function generateCertificateNo() {
  const year = new Date().getFullYear();
  return `MV-${year}-${Date.now()}-${crypto.randomBytes(3).toString("hex").toUpperCase()}`;
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

    // Background
    doc.rect(0, 0, width, height).fill("#08111f");

    // Outer Cyan Border
    doc.lineWidth(4).strokeColor("#22d3ee").rect(35, 35, width - 70, height - 70).stroke();

    // Inner White Border
    doc.lineWidth(1).strokeColor("#ffffff").opacity(0.25).rect(48, 48, width - 96, height - 96).stroke();
    doc.opacity(1);

    // Header Branding
    doc.font("Helvetica-Bold").fontSize(18).fillColor("#22d3ee").text("MYVAULT HUB", 0, 90, { align: "center" });
    doc.font("Helvetica-Bold").fontSize(34).fillColor("#ffffff").text("CERTIFICATE", 0, 145, { align: "center" });
    doc.font("Helvetica").fontSize(16).fillColor("#94a3b8").text("OF COMPLETION", 0, 188, { align: "center" });

    // Recipient Section
    doc.font("Helvetica").fontSize(14).fillColor("#cbd5e1").text("This certificate is proudly presented to", 0, 260, { align: "center" });
    doc.font("Helvetica-Bold").fontSize(30).fillColor("#ffffff").text(studentName || "Student", 70, 300, { width: width - 140, align: "center" });

    // Decorative Divider Line
    doc.lineWidth(1).strokeColor("#22d3ee").moveTo(150, 350).lineTo(width - 150, 350).stroke();

    doc.font("Helvetica").fontSize(14).fillColor("#cbd5e1").text("has successfully completed the industrial course", 0, 385, { align: "center" });
    doc.font("Helvetica-Bold").fontSize(23).fillColor("#22d3ee").text(courseTitle || "Internship Course", 80, 425, { width: width - 160, align: "center" });
    doc.font("Helvetica").fontSize(13).fillColor("#94a3b8").text("All required learning modules, assessments, and projects have been verified.", 70, 475, { width: width - 140, align: "center" });

    // Metadata & Verification
    doc.font("Helvetica").fontSize(12).fillColor("#cbd5e1").text(`Issued Date: ${issuedAt}`, 70, 555, { width: 220, align: "left" });
    doc.font("Helvetica").fontSize(11).fillColor("#94a3b8").text(`Certificate No: ${certificateNo}`, 70, 580, { width: 350 });

    // QR Code
    if (qrBuffer) {
      doc.image(qrBuffer, width - 190, 535, { width: 100, height: 100 });
      doc.font("Helvetica").fontSize(9).fillColor("#94a3b8").text("Scan to verify", width - 205, 642, { width: 130, align: "center" });
    }

    // Footer
    doc.font("Helvetica").fontSize(10).fillColor("#64748b").text("MyVault Hub • Verified Industrial Learning & Internship Platform", 0, height - 80, { align: "center" });

    doc.end();
  });
}

async function generateCertificate({ internshipId, studentId, studentName = null }) {
  // Check if certificate already exists
  const existing = await pool.query(
    `SELECT * FROM internship_certificates WHERE internship_id = $1 AND student_id = $2 LIMIT 1`,
    [internshipId, studentId]
  );
  if (existing.rows.length) {
    return existing.rows[0];
  }

  // Fetch course detail
  const courseResult = await pool.query(`SELECT id, title, company FROM internships WHERE id = $1`, [internshipId]);
  if (!courseResult.rows.length) {
    throw new Error("Course not found");
  }
  const course = courseResult.rows[0];

  const certificateNo = generateCertificateNo();
  const verificationCode = randomCode(12);
  const issuedDate = new Date();
  const issuedAt = issuedDate.toLocaleDateString("en-IN");
  const verifyBase = process.env.CERTIFICATE_VERIFY_URL || "https://myvault-project.vercel.app/verify";
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
  await s3.send(
    new PutObjectCommand({
      Bucket: BUCKET,
      Key: key,
      Body: pdfBuffer,
      ContentType: "application/pdf",
      ContentDisposition: `inline; filename="${certificateNo}.pdf"`,
    })
  );

  const certificateUrl = `https://${BUCKET}.s3.${REGION}.amazonaws.com/${key}`;
  const certificateId = `cert_${Date.now()}_${crypto.randomBytes(5).toString("hex")}`;

  const inserted = await pool.query(
    `INSERT INTO internship_certificates (id, internship_id, student_id, certificate_url, issued_at)
     VALUES ($1, $2, $3, $4, NOW())
     RETURNING *`,
    [certificateId, internshipId, studentId, certificateUrl]
  );

  return inserted.rows[0];
}

module.exports = { generateCertificate };
