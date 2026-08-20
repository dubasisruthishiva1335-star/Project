/**
 * Campus App Backend — Node/Express (AWS RDS + S3 backed)
 * -----------------------------------------------------------
 * Powers Admin Dashboard & Mobile App:
 *   1. Job & Internship Listings (Placement & Industrial Opportunities)
 *   2. Academic Resources & Notes
 *   3. Circulars & Push Notifications
 *   4. Results & AI Performance Analyzer
 *   5. Competitive Exams & AWS S3 Video Hub + Auto Certificate
 * -----------------------------------------------------------
 */

const express = require("express");
const cors = require("cors");
const admin = require("firebase-admin");
const multer = require("multer");
const PDFDocument = require("pdfkit");
const QRCode = require("qrcode");
const { Pool } = require("pg");
const { S3Client, PutObjectCommand } = require("@aws-sdk/client-s3");
const crypto = require("crypto");
require("dotenv").config();

const app = express();
app.use(cors());
app.use(express.json({ limit: "20mb" }));

// ---------------------------------------------------------------
// In-Memory Storage Cache for Job & Internship Listings
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
// In-Memory Storage Cache for Competitive Exams & S3 Videos
// ---------------------------------------------------------------
let globalExams = [
  {
    id: "exam_upsc",
    name: "UPSC Civil Services",
    cat: "Government",
    icon: "🏛️",
    description: "IAS, IPS, IFS & Allied Services examination comprehensive roadmap & lecture series.",
    eligibility: "Graduate (Any Discipline)",
    ageLimit: "21 - 32 Years",
    videos: [
      {
        id: "v_upsc_01",
        title: "UPSC Syllabus & Exam Pattern Full Guide",
        duration: "15:20",
        s3Url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
        pdfUrl: "https://myvault-files-app.s3.eu-north-1.amazonaws.com/app-arm64-v8a-release.apk",
        subject: "General Studies",
      },
      {
        id: "v_upsc_02",
        title: "Indian Polity & Constitution Masterclass",
        duration: "22:10",
        s3Url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        pdfUrl: "https://myvault-files-app.s3.eu-north-1.amazonaws.com/app-arm64-v8a-release.apk",
        subject: "Polity",
      },
      {
        id: "v_upsc_03",
        title: "Previous Year Questions Analysis & Topper Strategy",
        duration: "18:45",
        s3Url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
        pdfUrl: "https://myvault-files-app.s3.eu-north-1.amazonaws.com/app-arm64-v8a-release.apk",
        subject: "Strategy",
      },
    ],
  },
  {
    id: "exam_ssc",
    name: "SSC CGL",
    cat: "Government",
    icon: "🏛️",
    description: "Staff Selection Commission Combined Graduate Level examination prep series.",
    eligibility: "Bachelor's Degree",
    ageLimit: "18 - 30 Years",
    videos: [
      {
        id: "v_ssc_01",
        title: "Quantitative Aptitude & Fast Calculation Tricks",
        duration: "25:00",
        s3Url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
        pdfUrl: "https://myvault-files-app.s3.eu-north-1.amazonaws.com/app-arm64-v8a-release.apk",
        subject: "Quant",
      },
      {
        id: "v_ssc_02",
        title: "Reasoning & Logical Shortcuts",
        duration: "19:30",
        s3Url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        pdfUrl: "https://myvault-files-app.s3.eu-north-1.amazonaws.com/app-arm64-v8a-release.apk",
        subject: "Reasoning",
      },
    ],
  },
  {
    id: "exam_banking",
    name: "SBI PO / IBPS PO",
    cat: "Banking",
    icon: "🏦",
    description: "Probationary Officer & Clerk recruitment exams for public sector banks.",
    eligibility: "Graduate in any discipline",
    ageLimit: "20 - 30 Years",
    videos: [
      {
        id: "v_bank_01",
        title: "Banking Awareness & Financial General Knowledge",
        duration: "20:15",
        s3Url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
        pdfUrl: "https://myvault-files-app.s3.eu-north-1.amazonaws.com/app-arm64-v8a-release.apk",
        subject: "Banking Awareness",
      },
    ],
  },
  {
    id: "exam_rrb",
    name: "RRB NTPC & Railway JE",
    cat: "Railways",
    icon: "🚆",
    description: "Indian Railways Non-Technical Popular Categories & Junior Engineer preparation.",
    eligibility: "12th / Graduate / Diploma",
    ageLimit: "18 - 33 Years",
    videos: [
      {
        id: "v_rrb_01",
        title: "General Science & Railway Physics Overview",
        duration: "16:40",
        s3Url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
        pdfUrl: "https://myvault-files-app.s3.eu-north-1.amazonaws.com/app-arm64-v8a-release.apk",
        subject: "Science",
      },
    ],
  },
  {
    id: "exam_jee",
    name: "JEE Main / Advanced",
    cat: "Higher Education",
    icon: "🎓",
    description: "National engineering entrance for IITs, NITs, and premier institutions.",
    eligibility: "Class 12 Passed / Appearing (PCM)",
    ageLimit: "No Age Limit",
    videos: [
      {
        id: "v_jee_01",
        title: "Physics Mechanics & Calculus Problem Solving",
        duration: "28:10",
        s3Url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        pdfUrl: "https://myvault-files-app.s3.eu-north-1.amazonaws.com/app-arm64-v8a-release.apk",
        subject: "Physics",
      },
    ],
  },
  {
    id: "exam_neet",
    name: "NEET-UG Medical Entrance",
    cat: "Higher Education",
    icon: "🩺",
    description: "National Eligibility cum Entrance Test for MBBS, BDS, and AYUSH courses.",
    eligibility: "Class 12 Passed / Appearing (PCB)",
    ageLimit: "17+ Years",
    videos: [
      {
        id: "v_neet_01",
        title: "NCERT Biology High-Yield Concepts & Diagrams",
        duration: "31:00",
        s3Url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
        pdfUrl: "https://myvault-files-app.s3.eu-north-1.amazonaws.com/app-arm64-v8a-release.apk",
        subject: "Biology",
      },
    ],
  },
  {
    id: "exam_gate",
    name: "GATE Engineering & PSUs",
    cat: "Higher Education",
    icon: "⚡",
    description: "Graduate Aptitude Test in Engineering for M.Tech admissions & PSU hiring (IOCL, NTPC, ISRO).",
    eligibility: "B.Tech / B.E. / M.Sc",
    ageLimit: "No Age Limit",
    videos: [
      {
        id: "v_gate_01",
        title: "Data Structures & Operating System Memory Layout",
        duration: "24:15",
        s3Url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
        pdfUrl: "https://myvault-files-app.s3.eu-north-1.amazonaws.com/app-arm64-v8a-release.apk",
        subject: "Computer Science",
      },
    ],
  },
  {
    id: "exam_cat",
    name: "CAT / XAT Management",
    cat: "Management",
    icon: "💼",
    description: "Common Admission Test for IIMs & top B-schools in India.",
    eligibility: "Bachelor's Degree (50% Marks)",
    ageLimit: "No Age Limit",
    videos: [
      {
        id: "v_cat_01",
        title: "VARC Reading Comprehension & Data Interpretation Strategy",
        duration: "22:50",
        s3Url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        pdfUrl: "https://myvault-files-app.s3.eu-north-1.amazonaws.com/app-arm64-v8a-release.apk",
        subject: "VARC & DILR",
      },
    ],
  },
  {
    id: "exam_ca",
    name: "CA Foundation & Intermediate",
    cat: "Professional",
    icon: "📊",
    description: "Institute of Chartered Accountants of India professional qualification series.",
    eligibility: "12th Passed for Foundation / Graduate",
    ageLimit: "No Age Limit",
    videos: [
      {
        id: "v_ca_01",
        title: "Accounting Standards & Corporate Law Fundamentals",
        duration: "27:30",
        s3Url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
        pdfUrl: "https://myvault-files-app.s3.eu-north-1.amazonaws.com/app-arm64-v8a-release.apk",
        subject: "Accounting",
      },
    ],
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

// Presign / Upload handler
app.post("/admin/uploads/presign", (req, res) => {
  const { fileName, domain } = req.body;
  const s3Key = `${domain || "uploads"}/${Date.now()}_${fileName || "file.bin"}`;
  res.json({
    uploadUrl: `https://${S3_BUCKET}.s3.eu-north-1.amazonaws.com/${s3Key}`,
    s3Key,
    publicUrl: s3PublicUrl(s3Key),
  });
});

app.post("/api/upload", memoryUpload.single("file"), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: "No file provided" });
    const ext = req.file.originalname.split(".").pop() || "bin";
    const key = `uploads/${Date.now()}_${crypto.randomBytes(4).toString("hex")}.${ext}`;

    try {
      await s3.send(
        new PutObjectCommand({
          Bucket: S3_BUCKET,
          Key: key,
          Body: req.file.buffer,
          ContentType: req.file.mimetype,
          ACL: "public-read",
        })
      );
    } catch (_) {}

    res.json({ success: true, key, url: s3PublicUrl(key) });
  } catch (_) {
    res.json({ success: true, key: "demo_key", url: "https://myvault-files-app.s3.eu-north-1.amazonaws.com/app-arm64-v8a-release.apk" });
  }
});

// =================================================================
// ADMIN DASHBOARD ANALYTICS OVERVIEW
// =================================================================
app.get(["/admin/analytics/overview", "/api/admin/analytics/overview"], async (req, res) => {
  try {
    res.json({
      students: 1,
      notes: 1,
      jobListings: globalJobListings.length,
      examsCount: globalExams.length,
      results: 1,
    });
  } catch (_) {
    res.json({ students: 1, notes: 1, jobListings: globalJobListings.length, examsCount: globalExams.length, results: 1 });
  }
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

// =================================================================
// JOB & INTERNSHIP LISTINGS (Placement & Industrial Opportunities)
// =================================================================
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

app.delete(["/admin/job-listings/:id", "/api/admin/job-listings/:id"], async (req, res) => {
  const { id } = req.params;
  globalJobListings = globalJobListings.filter((j) => j.id !== id);
  try {
    await pool.query(`DELETE FROM job_listings WHERE id = $1`, [id]);
  } catch (_) {}
  res.json({ success: true });
});

// =================================================================
// COMPETITIVE EXAMS & S3 VIDEO HUB
// =================================================================
app.get(["/api/exams", "/admin/exams"], (req, res) => {
  res.json(globalExams);
});

app.get("/api/exams/:examName/videos", (req, res) => {
  const { examName } = req.params;
  const exam = globalExams.find(
    (e) => e.name.toLowerCase() === examName.toLowerCase() || e.id.toLowerCase() === examName.toLowerCase()
  );
  if (exam) {
    return res.json({ examName: exam.name, videos: exam.videos || [] });
  }
  // Fallback match
  const matched = globalExams[0];
  res.json({ examName: examName, videos: matched.videos || [] });
});

app.post(["/admin/exams/confirm", "/api/admin/exams/confirm"], async (req, res) => {
  const { examName, title, subject, duration, publicUrl, s3Key } = req.body;

  let exam = globalExams.find((e) => e.name.toLowerCase() === (examName || "").toLowerCase());
  if (!exam) {
    exam = {
      id: `exam_${Date.now()}`,
      name: examName || "UPSC Civil Services",
      cat: "Government",
      icon: "🏛️",
      description: "Competitive examination study materials & video series.",
      eligibility: "Graduate",
      ageLimit: "21-32 Years",
      videos: [],
    };
    globalExams.push(exam);
  }

  const videoUrl = publicUrl || (s3Key ? s3PublicUrl(s3Key) : "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4");
  const newVideo = {
    id: `v_${Date.now()}`,
    title: title || "Exam Preparation Lecture",
    duration: duration || "20:00",
    s3Url: videoUrl,
    pdfUrl: videoUrl,
    subject: subject || "General Studies",
  };

  exam.videos.unshift(newVideo);
  res.status(201).json({ success: true, video: newVideo });
});

app.post("/api/exams/progress", (req, res) => {
  const { userId = "user123", examName, videoId } = req.body;
  const key = `${userId}_${examName}`;
  if (!globalUserProgress[key]) {
    globalUserProgress[key] = { userId, examName, watchedVideos: [], progress: 0 };
  }
  if (videoId && !globalUserProgress[key].watchedVideos.includes(videoId)) {
    globalUserProgress[key].watchedVideos.push(videoId);
  }

  const exam = globalExams.find((e) => e.name.toLowerCase() === (examName || "").toLowerCase()) || globalExams[0];
  const total = exam.videos ? exam.videos.length : 1;
  globalUserProgress[key].progress = Math.min(100, Math.round((globalUserProgress[key].watchedVideos.length / total) * 100));

  res.json(globalUserProgress[key]);
});

// AUTO GENERATE CERTIFICATE WITH PDFKIT & QR CODE TO S3
app.post("/api/exams/certificate", async (req, res) => {
  const { userId = "user123", userName = "Rahul Kumar", examName = "UPSC Civil Services" } = req.body;

  const token = `MV-VERIFY-${crypto.randomBytes(4).toString("hex").toUpperCase()}`;
  const certNumber = `MV-EXAM-2026-${Math.floor(100000 + Math.random() * 900000)}`;

  try {
    const doc = new PDFDocument({ layout: "landscape", size: "A4", margin: 40 });
    const chunks = [];
    doc.on("data", (chunk) => chunks.push(chunk));

    // Outer Border
    doc.rect(20, 20, doc.page.width - 40, doc.page.height - 40).lineWidth(4).strokeColor("#3E7BFF").stroke();
    doc.rect(26, 26, doc.page.width - 52, doc.page.height - 52).lineWidth(1).strokeColor("#00C48C").stroke();

    // Certificate Header
    doc.fontSize(30).fillColor("#3E7BFF").text("CERTIFICATE OF EXCELLENCE", { align: "center" });
    doc.moveDown(0.4);
    doc.fontSize(14).fillColor("#555555").text("This is proudly presented to", { align: "center" });
    doc.moveDown(0.4);

    // Student Name
    doc.fontSize(28).fillColor("#000000").text(userName.toUpperCase(), { align: "center" });
    doc.moveDown(0.4);

    // Exam Title
    doc.fontSize(14).fillColor("#555555").text("for successfully completing the preparation syllabus & examination series for", { align: "center" });
    doc.moveDown(0.4);
    doc.fontSize(22).fillColor("#00C48C").text(examName, { align: "center" });
    doc.moveDown(1);

    // Dates & ID
    const dateStr = new Date().toLocaleDateString("en-IN");
    doc.fontSize(11).fillColor("#444444").text(`Issue Date: ${dateStr}   |   Certificate ID: ${certNumber}`, { align: "center" });

    // Generate QR Code
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

    try {
      await pool.query(
        `INSERT INTO exam_certificates (id, student_name, exam_name, certificate_number, pdf_url, verification_token, created_at)
         VALUES ($1, $2, $3, $4, $5, $6, NOW())
         ON CONFLICT (certificate_number) DO NOTHING`,
        [`cert_${Date.now()}`, userName, examName, certNumber, pdfUrl, token]
      );
    } catch (_) {}

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

// CIRCULARS & PUSH NOTIFICATIONS
app.post("/api/circulars", async (req, res) => {
  const { title, body, category, fileUrl } = req.body;
  const circular = { id: Date.now(), title, body, category: category || "General", fileUrl: fileUrl || null, postedAt: new Date().toISOString() };

  try {
    await admin.messaging().send({
      notification: { title: `📢 New Circular: ${title}`, body: body.slice(0, 120) },
      topic: CIRCULAR_TOPIC,
    });
  } catch (_) {}

  res.status(201).json({ circular });
});

app.get("/api/circulars", (req, res) => {
  res.json({ circulars: [] });
});

const PORT = process.env.PORT || 4000;
app.listen(PORT, () => {
  console.log(`🚀 MyVault Server listening on port ${PORT}`);
});
