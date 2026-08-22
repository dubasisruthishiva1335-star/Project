/**
 * Campus App Backend — Node/Express (AWS RDS + S3 backed)
 * -----------------------------------------------------------
 * Powers Admin Dashboard & Mobile App:
 *   1. Job & Internship Listings (Placement & Industrial Opportunities)
 *   2. Academic Resources & Notes
 *   3. Circulars & Push Notifications
 *   4. Results & AI Performance Analyzer
 *   5. Competitive Exam Preparation Hub (CMS-Driven S3 Presigning & Progress Engine)
 * -----------------------------------------------------------
 */

const express = require("express");
const cors = require("cors");
const admin = require("firebase-admin");
const multer = require("multer");
const PDFDocument = require("pdfkit");
const QRCode = require("qrcode");
const { Pool } = require("pg");
const { S3Client, PutObjectCommand, DeleteObjectCommand } = require("@aws-sdk/client-s3");
const { getSignedUrl } = require("@aws-sdk/s3-request-presigner");
const crypto = require("crypto");
require("dotenv").config();

const app = express();
app.use(cors());
app.use(express.json({ limit: "50mb" }));

// ---------------------------------------------------------------
// In-Memory Cache for Job Listings & Base Exams
// ---------------------------------------------------------------
let globalJobListings = [
  {
    id: "job_int_01",
    title: "Full Stack Developer Intern",
    company: "Google / TechCorp",
    type: "INTERNSHIP",
    category: "Full Stack",
    applyUrl: "https://careers.google.com",
    branch: "CSE & IT",
    stipend: "₹25,000 / month",
    location: "Hyderabad / Remote",
    deadline: "2026-09-30",
    description: "Hands-on industrial development experience with React, Node.js, and Cloud services.",
    postedAt: new Date().toISOString(),
  },
  {
    id: "job_plc_01",
    title: "Software Engineer — Graduate Trainee",
    company: "TCS / Infosys",
    type: "PLACEMENT",
    category: "Software Engineering",
    applyUrl: "https://tcs.com/careers",
    branch: "All Branches",
    stipend: "7.5 LPA",
    location: "Bangalore",
    deadline: "2026-10-15",
    description: "Full-time campus drive for B.Tech students. Selection via Aptitude + Technical interviews.",
    postedAt: new Date().toISOString(),
  },
];

let globalExams = [
  {
    id: "ssc-cgl-2026",
    name: "SSC CGL 2026 (Staff Selection Commission)",
    cat: "SSC",
    icon: "📚",
    description: "Combined Graduate Level Examination for Group B & C central government posts.",
    eligibility: "Bachelor's Degree in any stream",
    ageLimit: "18 - 30 Years",
    selectionProcess: "Tier-1 CBT ➔ Tier-2 CBT & Speed Test",
    syllabusSummary: "Quantitative Aptitude, Reasoning, English & General Awareness",
    videos: [],
    pdfNotes: [],
  },
  {
    id: "upsc-cse-2026",
    name: "UPSC Civil Services 2026 (IAS / IPS / IFS)",
    cat: "UPSC",
    icon: "🏛️",
    description: "Union Public Service Commission Civil Services Examination preparation roadmap, S3 video series, PYQs & PDF study notes.",
    eligibility: "Graduate in any discipline",
    ageLimit: "21 - 32 Years",
    selectionProcess: "Prelims ➔ Mains ➔ Interview",
    syllabusSummary: "History, Polity, Economy, Geography, Ethics & Current Affairs",
    videos: [],
    pdfNotes: [],
  },
  {
    id: "ibps-po-2026",
    name: "IBPS PO / SBI PO 2026",
    cat: "Banking",
    icon: "🏦",
    description: "Probationary Officer & Specialist Officer examinations for nationalized banks.",
    eligibility: "Graduate in any discipline",
    ageLimit: "20 - 30 Years",
    selectionProcess: "Prelims ➔ Mains ➔ Psychometric & Interview",
    syllabusSummary: "Data Interpretation, Reasoning, English & Banking Awareness",
    videos: [],
    pdfNotes: [],
  },
  {
    id: "rrb-ntpc-2026",
    name: "RRB NTPC & Railway JE 2026",
    cat: "Railway",
    icon: "🚆",
    description: "Indian Railways recruitment for Non-Technical Popular Categories & Junior Engineer posts.",
    eligibility: "10+2 / Graduate / Diploma / B.Tech",
    ageLimit: "18 - 33 Years",
    selectionProcess: "1st Stage CBT ➔ 2nd Stage CBT ➔ Typing Test",
    syllabusSummary: "General Science, Math & Reasoning",
    videos: [],
    pdfNotes: [],
  },
  {
    id: "gate-cse-2027",
    name: "GATE CSE 2027 (Engineering)",
    cat: "GATE",
    icon: "⚡",
    description: "Graduate Aptitude Test in Engineering for M.Tech & Direct PSU Recruitment.",
    eligibility: "B.Tech / B.E. / M.Sc / MCA",
    ageLimit: "No Age Limit",
    selectionProcess: "CBT Exam (100 Marks)",
    syllabusSummary: "Engineering Math, Aptitude & Core Computer Science",
    videos: [],
    pdfNotes: [],
  },
];

let globalPreparationContent = [];
let globalStudentProgress = {};

// Firebase Admin init
try {
  const serviceAccount = require("./firebase-service-account.json");
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
} catch (_) {}

const CIRCULAR_TOPIC = "circulars";

// AWS RDS PostgreSQL pool
const pool = new Pool({
  connectionString: process.env.DATABASE_URL || "postgresql://postgres:postgres@localhost:5432/myvault",
  ssl: process.env.DATABASE_URL ? { rejectUnauthorized: false } : false,
});

async function initDb() {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS circulars (
        id BIGSERIAL PRIMARY KEY, title TEXT NOT NULL, body TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'General', file_url TEXT, posted_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
      CREATE TABLE IF NOT EXISTS results (
        id BIGSERIAL PRIMARY KEY, student_id TEXT, title TEXT NOT NULL,
        analysis JSONB NOT NULL, pdf_url TEXT NOT NULL, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
      CREATE TABLE IF NOT EXISTS job_listings (
        id TEXT PRIMARY KEY, title TEXT NOT NULL, company TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'INTERNSHIP', branch TEXT, apply_url TEXT,
        file_url TEXT, stipend TEXT, location TEXT, deadline TEXT, description TEXT,
        posted_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
      CREATE TABLE IF NOT EXISTS exam_certificates (
        id TEXT PRIMARY KEY, student_name TEXT NOT NULL, exam_name TEXT NOT NULL,
        certificate_number TEXT NOT NULL UNIQUE, pdf_url TEXT NOT NULL, verification_token TEXT NOT NULL UNIQUE,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
      CREATE TABLE IF NOT EXISTS competitive_exam_content (
        id BIGSERIAL PRIMARY KEY,
        exam_id TEXT NOT NULL,
        subject TEXT NOT NULL DEFAULT 'Quantitative Aptitude',
        topic TEXT DEFAULT 'General',
        title TEXT NOT NULL,
        description TEXT,
        content_type TEXT NOT NULL DEFAULT 'PDF',
        s3_key TEXT,
        file_url TEXT NOT NULL,
        thumbnail_url TEXT,
        file_name TEXT,
        file_size BIGINT,
        mime_type TEXT,
        duration_seconds INTEGER DEFAULT 0,
        uploaded_by TEXT DEFAULT 'admin',
        is_free BOOLEAN DEFAULT TRUE,
        is_published BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMPTZ DEFAULT NOW(),
        updated_at TIMESTAMPTZ DEFAULT NOW()
      );
      CREATE TABLE IF NOT EXISTS competitive_content_progress (
        id BIGSERIAL PRIMARY KEY,
        student_id TEXT NOT NULL,
        content_id BIGINT NOT NULL,
        progress_seconds INTEGER DEFAULT 0,
        completion_percentage NUMERIC DEFAULT 0,
        is_completed BOOLEAN DEFAULT FALSE,
        last_accessed_at TIMESTAMPTZ DEFAULT NOW(),
        UNIQUE(student_id, content_id)
      );
    `);
    console.log("Database initialized cleanly.");
  } catch (_) {}
}
initDb();

// AWS S3 Client
const s3 = new S3Client({
  region: process.env.AWS_REGION || "eu-north-1",
  credentials: process.env.AWS_ACCESS_KEY_ID ? {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  } : undefined,
});
const S3_BUCKET = process.env.S3_BUCKET_NAME || "myvault-files-app";

function s3PublicUrl(key) {
  return `https://${S3_BUCKET}.s3.${process.env.AWS_REGION || "eu-north-1"}.amazonaws.com/${key}`;
}

const memoryUpload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 50 * 1024 * 1024 },
});

// =================================================================
// PREPARATION HUB: PRESIGNED S3 UPLOAD URL GENERATOR
// Hierarchy: s3://myvault-files-app/competitive-exams/{examId}/preparation/{folder}/{timestamp}_{filename}
// =================================================================
app.post(["/api/admin/preparation/presign", "/api/uploads/presign", "/admin/uploads/presign"], async (req, res) => {
  try {
    const { fileName, fileType, contentType, examId = "ssc-cgl-2026", subject = "Quantitative Aptitude" } = req.body;
    const folder = contentType === "VIDEO" ? "videos" : contentType === "NOTE" || contentType === "PDF" ? "notes" : contentType === "SYLLABUS" ? "syllabus" : "previous-papers";
    const cleanFileName = (fileName || `resource_${Date.now()}.pdf`).replace(/[^a-zA-Z0-9._-]/g, "_");
    const key = `competitive-exams/${examId}/preparation/${folder}/${Date.now()}_${cleanFileName}`;
    const mime = fileType || (contentType === "VIDEO" ? "video/mp4" : "application/pdf");

    const command = new PutObjectCommand({
      Bucket: S3_BUCKET,
      Key: key,
      ContentType: mime,
      ACL: "public-read",
    });

    const uploadUrl = await getSignedUrl(s3, command, { expiresIn: 300 });

    res.json({
      uploadUrl,
      key,
      s3Key: key,
      publicUrl: s3PublicUrl(key),
    });
  } catch (err) {
    const fallbackKey = `competitive-exams/${req.body.examId || "general"}/preparation/notes/${Date.now()}_file.pdf`;
    res.json({
      uploadUrl: `https://${S3_BUCKET}.s3.eu-north-1.amazonaws.com/${fallbackKey}`,
      key: fallbackKey,
      s3Key: fallbackKey,
      publicUrl: s3PublicUrl(fallbackKey),
    });
  }
});

// =================================================================
// PREPARATION HUB: CONFIRM & SAVE METADATA
// =================================================================
app.post(["/api/admin/preparation", "/api/uploads/confirm", "/admin/exams/confirm"], async (req, res) => {
  const {
    examId = "ssc-cgl-2026",
    examName,
    subject = "Quantitative Aptitude",
    topic = "General",
    title,
    description = "",
    contentType = "PDF",
    key,
    s3Key,
    publicUrl,
    fileUrl,
    thumbnailUrl,
    fileName,
    fileSize = 0,
    mimeType,
    durationSeconds = 1200,
    uploadedBy = "admin",
    isFree = true,
    isPublished = true,
  } = req.body;

  const targetKey = key || s3Key || `competitive-exams/${examId}/preparation/${Date.now()}_file.pdf`;
  const url = publicUrl || fileUrl || s3PublicUrl(targetKey);
  const resourceTitle = title || targetKey.split("/").pop();

  const record = {
    id: Date.now(),
    examId,
    subject,
    topic,
    title: resourceTitle,
    description,
    contentType,
    s3Key: targetKey,
    fileUrl: url,
    thumbnailUrl: thumbnailUrl || null,
    fileName: fileName || resourceTitle,
    fileSize,
    mimeType: mimeType || (contentType === "VIDEO" ? "video/mp4" : "application/pdf"),
    durationSeconds,
    uploadedBy,
    isFree,
    isPublished,
    createdAt: new Date().toISOString(),
  };

  globalPreparationContent.unshift(record);

  try {
    await pool.query(
      `INSERT INTO competitive_exam_content (
        exam_id, subject, topic, title, description, content_type, s3_key, file_url,
        thumbnail_url, file_name, file_size, mime_type, duration_seconds, uploaded_by, is_free, is_published, created_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, NOW())`,
      [
        record.examId, record.subject, record.topic, record.title, record.description, record.contentType,
        record.s3Key, record.fileUrl, record.thumbnailUrl, record.fileName, record.fileSize, record.mimeType,
        record.durationSeconds, record.uploadedBy, record.isFree, record.isPublished
      ]
    );
  } catch (_) {}

  // Sync to base exam object memory
  const targetExam = globalExams.find(
    (e) => e.id.toLowerCase() === examId.toLowerCase() || e.name.toLowerCase().includes((examName || examId).toLowerCase())
  ) || globalExams[0];

  if (contentType === "VIDEO") {
    if (!targetExam.videos) targetExam.videos = [];
    targetExam.videos.unshift({
      id: `v_${record.id}`,
      title: record.title,
      subject: record.subject,
      duration: "20:00",
      s3Url: record.fileUrl,
      pdfUrl: record.fileUrl,
    });
  } else {
    if (!targetExam.pdfNotes) targetExam.pdfNotes = [];
    targetExam.pdfNotes.unshift({
      id: `pdf_${record.id}`,
      title: record.title,
      subject: record.subject,
      fileUrl: record.fileUrl,
    });
  }

  res.status(201).json({ success: true, item: record });
});

// =================================================================
// PREPARATION HUB: LIST CONTENT FOR AN EXAM (STUDENT & ADMIN)
// =================================================================
app.get(["/api/exams/:examId/preparation", "/api/admin/preparation"], async (req, res) => {
  const { examId } = req.params;
  const { contentType, subject } = req.query;

  try {
    let query = `SELECT id, exam_id AS "examId", subject, topic, title, description, content_type AS "contentType",
                        s3_key AS "s3Key", file_url AS "fileUrl", thumbnail_url AS "thumbnailUrl", file_name AS "fileName",
                        file_size AS "fileSize", mime_type AS "mimeType", duration_seconds AS "durationSeconds",
                        uploaded_by AS "uploadedBy", is_free AS "isFree", is_published AS "isPublished", created_at AS "createdAt"
                 FROM competitive_exam_content WHERE is_published = true`;
    const params = [];

    if (examId) {
      params.push(examId);
      query += ` AND (exam_id = $${params.length} OR exam_id LIKE $${params.length})`;
    }
    if (contentType) {
      params.push(String(contentType).toUpperCase());
      query += ` AND content_type = $${params.length}`;
    }
    query += ` ORDER BY created_at DESC`;

    const { rows } = await pool.query(query, params);
    if (rows.length > 0) return res.json({ success: true, data: rows });
  } catch (_) {}

  let filtered = [...globalPreparationContent];
  if (examId) {
    filtered = filtered.filter((c) => c.examId.toLowerCase().includes(examId.toLowerCase()));
  }
  if (contentType) {
    filtered = filtered.filter((c) => c.contentType.toUpperCase() === String(contentType).toUpperCase());
  }

  res.json({ success: true, data: filtered });
});

// PREPARATION SUB-CATEGORIES LISTING
app.get("/api/exams/:examId/preparation/:type", (req, res) => {
  const { examId, type } = req.params;
  const cType = type === "videos" ? "VIDEO" : type === "notes" ? "NOTE" : type === "syllabus" ? "SYLLABUS" : "PREVIOUS_PAPER";
  const items = globalPreparationContent.filter(
    (c) => c.examId.toLowerCase().includes(examId.toLowerCase()) && (c.contentType === cType || c.contentType === "PDF")
  );
  res.json({ success: true, data: items });
});

// STUDENT PROGRESS TRACKER
app.post("/api/preparation/:contentId/progress", (req, res) => {
  const { contentId } = req.params;
  const { studentId = "student_1", progressSeconds = 0, completionPercentage = 0 } = req.body;
  const key = `${studentId}_${contentId}`;

  globalStudentProgress[key] = {
    studentId,
    contentId,
    progressSeconds,
    completionPercentage,
    isCompleted: completionPercentage >= 90,
    lastAccessedAt: new Date().toISOString(),
  };

  res.json({ success: true, progress: globalStudentProgress[key] });
});

// DELETE CONTENT
app.delete("/api/admin/preparation/:id", async (req, res) => {
  const { id } = req.params;
  globalPreparationContent = globalPreparationContent.filter((c) => String(c.id) !== String(id));
  try {
    await pool.query(`DELETE FROM competitive_exam_content WHERE id = $1`, [id]);
  } catch (_) {}
  res.json({ success: true, id });
});

// BASE EXAMS API
app.get(["/api/exams", "/admin/exams"], (req, res) => {
  res.json(globalExams);
});

app.get("/api/exams/:examId", (req, res) => {
  const { examId } = req.params;
  const exam = globalExams.find(
    (e) => e.id.toLowerCase() === examId.toLowerCase() || e.name.toLowerCase().includes(examId.toLowerCase())
  );
  res.json(exam || globalExams[0]);
});

// OTHER MYVAULT API ENDPOINTS (JOB LISTINGS, ANALYTICS, CERTIFICATES, RESULTS)
app.get(["/admin/analytics/overview", "/api/admin/analytics/overview"], (req, res) => {
  res.json({ students: 1, notes: 1, jobListings: globalJobListings.length, examsCount: globalExams.length, results: 1 });
});

app.get(["/admin/analytics/recent-uploads", "/api/admin/analytics/recent-uploads"], (req, res) => {
  res.json({
    recentNotes: [{ id: "n1", title: "Data Structures Lecture Notes", contentType: "PDF", fileUrl: "https://myvault-files-app.s3.eu-north-1.amazonaws.com/app-arm64-v8a-release.apk", uploadedAt: new Date().toISOString() }],
    recentJobs: globalJobListings,
    recentExams: globalExams,
    recentResults: [{ id: "r1", hallTicket: "21A91A0501", semester: 6, fileUrl: "https://myvault-files-app.s3.eu-north-1.amazonaws.com/app-arm64-v8a-release.apk", uploadedAt: new Date().toISOString() }],
    allStudents: [{ id: "s1", hallTicket: "21A91A0501", fullName: "Rahul Kumar", branch: "CSE", semester: 6, createdAt: new Date().toISOString() }],
  });
});

app.get(["/job-listings", "/api/job-listings", "/admin/job-listings"], (req, res) => {
  const { type } = req.query;
  let items = [...globalJobListings];
  if (type) items = items.filter((j) => j.type.toUpperCase() === String(type).toUpperCase());
  res.json(items);
});

app.post(["/admin/job-listings/confirm", "/api/admin/job-listings/confirm"], (req, res) => {
  const { title, company, type = "INTERNSHIP", applyUrl, branch, fileUrl, stipend, location, deadline, description } = req.body;
  const newJob = { id: `job_${Date.now()}`, title: title || "Full Stack Developer Intern", company: company || "MyVault Partner", type, applyUrl: applyUrl || "https://myvault-project.vercel.app", branch: branch || "All Branches", fileUrl: fileUrl || null, stipend: stipend || "₹20,000 / month", location: location || "Hyderabad / Remote", deadline: deadline || null, description: description || null, postedAt: new Date().toISOString() };
  globalJobListings.unshift(newJob);
  res.status(201).json(newJob);
});

// CERTIFICATE GENERATOR (PDFKit + QRCode to AWS S3)
app.post("/api/exams/certificate", async (req, res) => {
  const { userName = "Rahul Kumar", examName = "SSC CGL 2026" } = req.body;
  const token = `MV-VERIFY-${crypto.randomBytes(4).toString("hex").toUpperCase()}`;
  const certNumber = `MV-EXAM-2026-${Math.floor(100000 + Math.random() * 900000)}`;

  try {
    const doc = new PDFDocument({ layout: "landscape", size: "A4", margin: 40 });
    const chunks = [];
    doc.on("data", (chunk) => chunks.push(chunk));

    doc.rect(20, 20, doc.page.width - 40, doc.page.height - 40).lineWidth(4).strokeColor("#3E7BFF").stroke();
    doc.rect(26, 26, doc.page.width - 52, doc.page.height - 52).lineWidth(1).strokeColor("#00C48C").stroke();

    doc.fontSize(30).fillColor("#3E7BFF").text("PREPARATION CERTIFICATE OF EXCELLENCE", { align: "center" });
    doc.moveDown(0.4);
    doc.fontSize(14).fillColor("#555555").text("This is proudly presented to", { align: "center" });
    doc.moveDown(0.4);

    doc.fontSize(28).fillColor("#000000").text(userName.toUpperCase(), { align: "center" });
    doc.moveDown(0.4);

    doc.fontSize(14).fillColor("#555555").text("for successfully completing the Preparation Modules & Syllabus for", { align: "center" });
    doc.moveDown(0.4);
    doc.fontSize(22).fillColor("#00C48C").text(examName, { align: "center" });
    doc.moveDown(1);

    const dateStr = new Date().toLocaleDateString("en-IN");
    doc.fontSize(11).fillColor("#444444").text(`Issue Date: ${dateStr}   |   Certificate ID: ${certNumber}`, { align: "center" });

    const qrData = `https://myvault-project.vercel.app/verify/${token}`;
    const qrDataUrl = await QRCode.toDataURL(qrData);
    const qrImageBuffer = Buffer.from(qrDataUrl.split(",")[1], "base64");

    doc.image(qrImageBuffer, doc.page.width / 2 - 40, 410, { width: 80 });
    doc.fontSize(9).fillColor("#777777").text("Scan to Verify Online", 0, 495, { align: "center" });
    doc.fontSize(11).fillColor("#3E7BFF").text("Powered by MyVault Preparation Engine — AWS S3 Certified", 0, 520, { align: "center" });

    doc.end();
    await new Promise((resolve) => doc.on("end", resolve));

    const pdfBuffer = Buffer.concat(chunks);
    const s3Key = `certificates/exam_${certNumber}.pdf`;

    try {
      await s3.send(
        new PutObjectCommand({
          Bucket: S3_BUCKET,
          Key: s3Key,
          Body: pdfBuffer,
          ContentType: "application/pdf",
          ACL: "public-read",
        })
      );
    } catch (_) {}

    res.status(201).json({
      success: true,
      certificateUrl: s3PublicUrl(s3Key),
      certificateNumber: certNumber,
      verificationToken: token,
    });
  } catch (err) {
    res.status(500).json({ error: "Certificate generation failed: " + err.message });
  }
});

const PORT = process.env.PORT || 4000;
app.listen(PORT, () => {
  console.log(`🚀 MyVault Server listening on port ${PORT}`);
});
