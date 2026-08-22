/**
 * Campus App Backend — Node/Express (AWS RDS + S3 backed)
 * -----------------------------------------------------------
 * Powers Admin Dashboard & Mobile App:
 *   1. Job & Internship Listings (Placement & Industrial Opportunities)
 *   2. Academic Resources & Notes
 *   3. Circulars & Push Notifications
 *   4. Results & AI Performance Analyzer
 *   5. Structured Competitive Exams Preparation Hub (CMS-Driven S3 Presign Pipeline)
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
// In-Memory Cache for Base Job Listings
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

// ---------------------------------------------------------------
// Structured Competitive Exams Base Categories & Storage
// ---------------------------------------------------------------
let globalExams = [
  {
    id: "exam_upsc",
    name: "UPSC Civil Services (IAS / IPS / IFS)",
    cat: "Government",
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
    id: "exam_ssc",
    name: "SSC CGL (Staff Selection Commission)",
    cat: "Government",
    icon: "🏛️",
    description: "Combined Graduate Level Examination for Group B & C central government posts.",
    eligibility: "Bachelor's Degree in any stream",
    ageLimit: "18 - 30 Years",
    selectionProcess: "Tier-1 CBT ➔ Tier-2 CBT & Speed Test",
    syllabusSummary: "Quantitative Aptitude, Reasoning, English & General Awareness",
    videos: [],
    pdfNotes: [],
  },
  {
    id: "exam_banking",
    name: "SBI PO / IBPS PO & Clerk",
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
    id: "exam_rrb",
    name: "RRB NTPC & Railway JE",
    cat: "Railways",
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
    id: "exam_jee",
    name: "JEE Main / Advanced (Engineering)",
    cat: "Higher Education",
    icon: "🎓",
    description: "Premier national engineering entrance examination for IITs, NITs, IIITs, and CFTIs.",
    eligibility: "Class 12 Passed (PCM)",
    ageLimit: "No Age Limit",
    selectionProcess: "JEE Main CBT ➔ Advanced CBT",
    syllabusSummary: "Physics (Mechanics), Chemistry, Math (Calculus)",
    videos: [],
    pdfNotes: [],
  },
  {
    id: "exam_neet",
    name: "NEET-UG (Medical Entrance)",
    cat: "Higher Education",
    icon: "🩺",
    description: "National entrance examination for MBBS, BDS, BAMS, BHMS, and medical admissions.",
    eligibility: "Class 12 Passed (PCB)",
    ageLimit: "Minimum 17 Years",
    selectionProcess: "OMR Pen & Paper Exam (720 Marks)",
    syllabusSummary: "NCERT Biology, Chemistry & Physics",
    videos: [],
    pdfNotes: [],
  },
  {
    id: "exam_gate",
    name: "GATE (Engineering & PSUs)",
    cat: "Higher Education",
    icon: "⚡",
    description: "Graduate Aptitude Test in Engineering for M.Tech & Direct PSU Recruitment.",
    eligibility: "B.Tech / B.E. / M.Sc / MCA",
    ageLimit: "No Age Limit",
    selectionProcess: "CBT Exam (100 Marks)",
    syllabusSummary: "Engineering Math, Aptitude & Core Engineering Subjects",
    videos: [],
    pdfNotes: [],
  },
  {
    id: "exam_cat",
    name: "CAT / XAT (Management)",
    cat: "Management",
    icon: "💼",
    description: "Common Admission Test for MBA & PGDM programs at IIMs & top B-schools.",
    eligibility: "Bachelor's Degree",
    ageLimit: "No Age Limit",
    selectionProcess: "CAT Exam ➔ WAT / GD ➔ Interview",
    syllabusSummary: "VARC, DILR & Quantitative Ability",
    videos: [],
    pdfNotes: [],
  },
  {
    id: "exam_ca",
    name: "CA (Chartered Accountant)",
    cat: "Professional",
    icon: "📊",
    description: "ICAI Professional Qualification for Foundation, Intermediate & Final stages.",
    eligibility: "12th Passed / Graduate",
    ageLimit: "No Age Limit",
    selectionProcess: "Foundation ➔ Inter ➔ Articleship ➔ Final",
    syllabusSummary: "Accounting, Law, Costing, Taxation, Auditing",
    videos: [],
    pdfNotes: [],
  },
];

let globalUserProgress = {};

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
      CREATE TABLE IF NOT EXISTS competitive_exams (
        id TEXT PRIMARY KEY, name TEXT NOT NULL, cat TEXT NOT NULL,
        icon TEXT DEFAULT '🏛️', description TEXT, eligibility TEXT,
        age_limit TEXT, selection_process TEXT, syllabus_summary TEXT,
        created_at TIMESTAMPTZ DEFAULT NOW()
      );
      CREATE TABLE IF NOT EXISTS exam_contents (
        id BIGSERIAL PRIMARY KEY, key TEXT NOT NULL, exam_id TEXT NOT NULL,
        subject TEXT DEFAULT 'general', title TEXT NOT NULL, content_type TEXT DEFAULT 'PDF',
        file_url TEXT NOT NULL, uploaded_by TEXT DEFAULT 'unknown', created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
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
// STEP 1: PRESIGNED S3 UPLOAD URL GENERATOR
// S3 Key Format: competitive-exams/{category}/{examId}/{type}/{timestamp}_{filename}
// =================================================================
app.post(["/api/uploads/presign", "/admin/uploads/presign"], async (req, res) => {
  try {
    const { fileName, fileType, contentType, examId, subject, domain } = req.body;
    const folderType = contentType === "VIDEO" ? "videos" : contentType === "SYLLABUS" ? "syllabus" : "pdfs";
    const targetDomain = domain || (examId ? `competitive-exams/${examId}/${folderType}` : "competitive-exams/general");
    const cleanFileName = (fileName || `file_${Date.now()}.bin`).replace(/[^a-zA-Z0-9._-]/g, "_");
    const key = `${targetDomain}/${Date.now()}_${cleanFileName}`;
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
    const fallbackKey = `competitive-exams/general/${Date.now()}_file.pdf`;
    res.json({
      uploadUrl: `https://${S3_BUCKET}.s3.eu-north-1.amazonaws.com/${fallbackKey}`,
      key: fallbackKey,
      s3Key: fallbackKey,
      publicUrl: s3PublicUrl(fallbackKey),
    });
  }
});

// =================================================================
// STEP 2: CONFIRM UPLOAD SUCCESS & SAVE METADATA TO DATABASE
// =================================================================
app.post(["/api/uploads/confirm", "/admin/exams/confirm"], async (req, res) => {
  const { key, s3Key, examId, examName, subject, title, uploadedBy, contentType, publicUrl, duration } = req.body;
  const targetKey = key || s3Key || `competitive-exams/general/${Date.now()}_file.bin`;
  const targetExamId = examId || (examName ? examName.toLowerCase().replace(/[^a-z0-9]/g, "_") : "exam_upsc");
  const fileUrl = publicUrl || s3PublicUrl(targetKey);
  const type = contentType || (fileUrl.endsWith(".mp4") ? "VIDEO" : "PDF");

  const record = {
    id: Date.now(),
    key: targetKey,
    examId: targetExamId,
    subject: subject || "general",
    title: title || targetKey.split("/").pop(),
    contentType: type,
    url: fileUrl,
    uploadedBy: uploadedBy || "admin",
    createdAt: new Date().toISOString(),
  };

  try {
    await pool.query(
      `INSERT INTO exam_contents (key, exam_id, subject, title, content_type, file_url, uploaded_by, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, NOW())`,
      [record.key, record.examId, record.subject, record.title, record.contentType, record.url, record.uploadedBy]
    );
  } catch (_) {}

  // Sync with globalExams memory object cleanly (WITHOUT polluting job_listings!)
  const targetExam = globalExams.find(
    (e) => e.id.toLowerCase() === targetExamId.toLowerCase() || e.name.toLowerCase().includes((examName || "").toLowerCase())
  ) || globalExams[0];

  if (type === "PDF" || fileUrl.endsWith(".pdf")) {
    if (!targetExam.pdfNotes) targetExam.pdfNotes = [];
    targetExam.pdfNotes.unshift({
      id: `pdf_${Date.now()}`,
      title: record.title,
      subject: record.subject,
      fileUrl: record.url,
    });
  } else {
    if (!targetExam.videos) targetExam.videos = [];
    targetExam.videos.unshift({
      id: `v_${Date.now()}`,
      title: record.title,
      subject: record.subject,
      duration: duration || "20:00",
      s3Url: record.url,
      pdfUrl: record.url,
    });
  }

  res.status(201).json({ success: true, item: record });
});

// =================================================================
// STEP 3: LIST CONTENT FOR GIVEN EXAM WITH S3 URLS
// =================================================================
app.get("/api/exams/:examId/content", async (req, res) => {
  const { examId } = req.params;
  try {
    const { rows } = await pool.query(
      `SELECT id, key, exam_id AS "examId", subject, title, content_type AS "contentType",
              file_url AS "url", uploaded_by AS "uploadedBy", created_at AS "createdAt"
       FROM exam_contents WHERE exam_id = $1 ORDER BY created_at DESC`,
      [examId]
    );
    if (rows.length > 0) return res.json(rows);
  } catch (_) {}

  const exam = globalExams.find((e) => e.id === examId || e.name.toLowerCase().includes(examId.toLowerCase()));
  res.json(exam ? [...(exam.videos || []), ...(exam.pdfNotes || [])] : []);
});

// =================================================================
// STEP 4: DELETE CONTENT FROM S3 & DATABASE
// =================================================================
app.delete("/api/content/:key", async (req, res) => {
  try {
    const key = decodeURIComponent(req.params.key);
    await s3.send(new DeleteObjectCommand({ Bucket: S3_BUCKET, Key: key }));
    try {
      await pool.query(`DELETE FROM exam_contents WHERE key = $1`, [key]);
    } catch (_) {}
    res.json({ deleted: key });
  } catch (err) {
    res.status(500).json({ error: "Failed to delete" });
  }
});

// ADMIN OVERVIEW & ANALYTICS
app.get(["/admin/analytics/overview", "/api/admin/analytics/overview"], async (req, res) => {
  res.json({
    students: 1,
    notes: 1,
    jobListings: globalJobListings.length,
    examsCount: globalExams.length,
    results: 1,
  });
});

app.get(["/admin/analytics/recent-uploads", "/api/admin/analytics/recent-uploads"], async (req, res) => {
  res.json({
    recentNotes: [{ id: "n1", title: "Data Structures Lecture Notes", contentType: "PDF", fileUrl: "https://myvault-files-app.s3.eu-north-1.amazonaws.com/app-arm64-v8a-release.apk", uploadedAt: new Date().toISOString() }],
    recentJobs: globalJobListings,
    recentExams: globalExams,
    recentResults: [{ id: "r1", hallTicket: "21A91A0501", semester: 6, fileUrl: "https://myvault-files-app.s3.eu-north-1.amazonaws.com/app-arm64-v8a-release.apk", uploadedAt: new Date().toISOString() }],
    allStudents: [{ id: "s1", hallTicket: "21A91A0501", fullName: "Rahul Kumar", branch: "CSE", semester: 6, createdAt: new Date().toISOString() }],
  });
});

// JOB & INTERNSHIP LISTINGS
app.get(["/job-listings", "/api/job-listings", "/admin/job-listings"], async (req, res) => {
  const { type } = req.query;
  let items = [...globalJobListings];

  try {
    const { rows } = await pool.query(
      `SELECT id, title, company, type, branch, apply_url AS "applyUrl", file_url AS "fileUrl",
              stipend, location, deadline, description, posted_at AS "postedAt"
       FROM job_listings ORDER BY posted_at DESC`
    );
    if (rows.length > 0) items = rows;
  } catch (_) {}

  if (type) {
    items = items.filter((j) => j.type.toUpperCase() === String(type).toUpperCase());
  }

  res.json(items);
});

app.post(["/admin/job-listings/confirm", "/api/admin/job-listings/confirm"], async (req, res) => {
  const { title, company, type = "INTERNSHIP", applyUrl, branch, fileUrl, stipend, location, deadline, description, publicUrl } = req.body;
  const newJob = {
    id: `job_${Date.now()}`,
    title: title || "Full Stack Developer Intern",
    company: company || "MyVault Partner",
    type: type || "INTERNSHIP",
    applyUrl: applyUrl || publicUrl || "https://myvault-project.vercel.app",
    branch: branch || "All Branches",
    fileUrl: fileUrl || publicUrl || null,
    stipend: stipend || "₹20,000 / month",
    location: location || "Hyderabad / Remote",
    deadline: deadline || null,
    description: description || null,
    postedAt: new Date().toISOString(),
  };

  globalJobListings.unshift(newJob);

  try {
    await pool.query(
      `INSERT INTO job_listings (id, title, company, type, branch, apply_url, file_url, stipend, location, deadline, description, posted_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, NOW())`,
      [newJob.id, newJob.title, newJob.company, newJob.type, newJob.branch, newJob.applyUrl, newJob.fileUrl, newJob.stipend, newJob.location, newJob.deadline, newJob.description]
    );
  } catch (_) {}

  res.status(201).json(newJob);
});

// COMPETITIVE EXAMS API
app.get(["/api/exams", "/admin/exams"], (req, res) => {
  res.json(globalExams);
});

app.get("/api/exams/:examId", (req, res) => {
  const { examId } = req.params;
  const exam = globalExams.find(
    (e) => e.id.toLowerCase() === examId.toLowerCase() || e.name.toLowerCase().includes(examId.toLowerCase())
  );
  if (exam) {
    return res.json(exam);
  }
  res.json(globalExams[0]);
});

// CERTIFICATES GENERATOR (PDFKit + QRCode to AWS S3)
app.post("/api/exams/certificate", async (req, res) => {
  const { userId = "user123", userName = "Rahul Kumar", examName = "UPSC Civil Services" } = req.body;

  const token = `MV-VERIFY-${crypto.randomBytes(4).toString("hex").toUpperCase()}`;
  const certNumber = `MV-EXAM-2026-${Math.floor(100000 + Math.random() * 900000)}`;

  try {
    const doc = new PDFDocument({ layout: "landscape", size: "A4", margin: 40 });
    const chunks = [];
    doc.on("data", (chunk) => chunks.push(chunk));

    doc.rect(20, 20, doc.page.width - 40, doc.page.height - 40).lineWidth(4).strokeColor("#3E7BFF").stroke();
    doc.rect(26, 26, doc.page.width - 52, doc.page.height - 52).lineWidth(1).strokeColor("#00C48C").stroke();

    doc.fontSize(30).fillColor("#3E7BFF").text("CERTIFICATE OF EXCELLENCE", { align: "center" });
    doc.moveDown(0.4);
    doc.fontSize(14).fillColor("#555555").text("This is proudly presented to", { align: "center" });
    doc.moveDown(0.4);

    doc.fontSize(28).fillColor("#000000").text(userName.toUpperCase(), { align: "center" });
    doc.moveDown(0.4);

    doc.fontSize(14).fillColor("#555555").text("for successfully completing the preparation syllabus & examination series for", { align: "center" });
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
    doc.fontSize(11).fillColor("#3E7BFF").text("Powered by MyVault Competitive Exam Engine — AWS S3 Certified", 0, 520, { align: "center" });

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

    const pdfUrl = s3PublicUrl(s3Key);

    res.status(201).json({
      success: true,
      certificateUrl: pdfUrl,
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
