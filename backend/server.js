/**
 * Campus App Backend — Node/Express (AWS RDS + S3 backed)
 * -----------------------------------------------------------
 * Powers Admin Dashboard & Mobile App:
 *   1. Job & Internship Opportunities (Placements, Stipends, Hiring Drives)
 *   2. Internship Learning Hub (Free Courses, S3 Lessons, Quizzes, Assignments, Final Exams & Certificates)
 *   3. Academic Resources & Notes
 *   4. Results & AI Performance Analyzer
 *   5. Competitive Exam Preparation Hub
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
const { getSignedUrl } = require("@aws-sdk/s3-request-presigner");
const crypto = require("crypto");
require("dotenv").config();

const app = express();
app.use(cors());
app.use(express.json({ limit: "50mb" }));

// ---------------------------------------------------------------
// In-Memory Global Stores (Clean — Starts with 0 job listings)
// ---------------------------------------------------------------
let globalJobListings = [];

function isTestListing(job) {
  if (!job) return true;
  const title = (job.title || "").toLowerCase();
  const company = (job.company || "").toLowerCase();
  const url = (job.applyUrl || job.apply_url || "").toLowerCase();
  return (
    title.includes("tspsc") ||
    title.includes("frontend") ||
    title.includes("acme") ||
    title.includes("html") ||
    title.includes("jhbb") ||
    company.includes("acme") ||
    company.includes("tspsc") ||
    url.includes("example.com")
  );
}

let globalCourses = [
  {
    id: "course_flutter_dev",
    title: "Flutter Mobile App Development",
    category: "Mobile",
    level: "Beginner to Advanced",
    duration: "8 Hours",
    lessonsCount: 6,
    isFree: true,
    thumbnailUrl: "https://myvault-files-app.s3.eu-north-1.amazonaws.com/internships/courses/flutter/thumbnail.jpg",
    description: "Build real-world Android and iOS apps from scratch using Flutter and Dart. Master state management, REST APIs, and AWS S3 integration.",
    learnings: [
      "Flutter fundamentals & Dart syntax",
      "Building responsive Material 3 UIs",
      "GoRouter navigation & state management",
      "Connecting Node.js & AWS S3 REST APIs",
      "Building a complete production app",
    ],
    modules: [
      {
        title: "Module 1: Flutter Fundamentals",
        lessons: [
          { id: "les_101", title: "01. Flutter Architecture & Dart Intro", duration: "25:00", videoUrl: "https://myvault-files-app.s3.eu-north-1.amazonaws.com/app-arm64-v8a-release.apk", pdfUrl: "https://myvault-files-app.s3.eu-north-1.amazonaws.com/app-arm64-v8a-release.apk" },
          { id: "les_102", title: "02. Widgets, Layouts & Material UI", duration: "32:15", videoUrl: "https://myvault-files-app.s3.eu-north-1.amazonaws.com/app-arm64-v8a-release.apk", pdfUrl: "https://myvault-files-app.s3.eu-north-1.amazonaws.com/app-arm64-v8a-release.apk" },
        ],
      },
      {
        title: "Module 2: APIs & State Management",
        lessons: [
          { id: "les_103", title: "03. Dio REST APIs & State Management", duration: "40:10", videoUrl: "https://myvault-files-app.s3.eu-north-1.amazonaws.com/app-arm64-v8a-release.apk", pdfUrl: "https://myvault-files-app.s3.eu-north-1.amazonaws.com/app-arm64-v8a-release.apk" },
          { id: "les_104", title: "04. AWS S3 Direct Upload Integration", duration: "35:00", videoUrl: "https://myvault-files-app.s3.eu-north-1.amazonaws.com/app-arm64-v8a-release.apk", pdfUrl: "https://myvault-files-app.s3.eu-north-1.amazonaws.com/app-arm64-v8a-release.apk" },
        ],
      },
    ],
    quiz: {
      id: "quiz_flt_01",
      title: "Flutter Mastery Quiz",
      questions: [
        { id: 1, question: "Which widget is commonly used for a vertically scrolling list?", options: ["Column", "Row", "ListView", "Stack"], answer: 2 },
        { id: 2, question: "Which HTTP client library is used for advanced Flutter networking?", options: ["http", "Dio", "Fetch", "Axios"], answer: 1 },
      ],
    },
    assignment: {
      id: "assign_flt_01",
      title: "Build a Custom Student Dashboard Screen",
      instructions: "Create a responsive Flutter dashboard containing user avatar, metric cards, and a dynamic list view with action buttons.",
    },
    finalExam: {
      id: "exam_flt_01",
      title: "Flutter Certification Final Exam",
      timeMinutes: 30,
      passingScore: 70,
    },
  },
  {
    id: "course_python_ai",
    title: "Python AI & Machine Learning Foundations",
    category: "AI",
    level: "Beginner",
    duration: "10 Hours",
    lessonsCount: 8,
    isFree: true,
    thumbnailUrl: "https://myvault-files-app.s3.eu-north-1.amazonaws.com/internships/courses/python/thumbnail.jpg",
    description: "Learn Python programming, NumPy, Pandas, and build intelligent machine learning models for real-world projects.",
    learnings: [
      "Python data structures & OOP",
      "Data analysis with Pandas & NumPy",
      "Supervised machine learning algorithms",
      "Deploying AI models to REST API backends",
    ],
    modules: [],
    quiz: { id: "quiz_py_01", title: "Python Basics Quiz", questions: [] },
    assignment: { id: "assign_py_01", title: "Build a Data Cleaning Script", instructions: "Clean CSV dataset using Pandas" },
    finalExam: { id: "exam_py_01", title: "Python AI Certification Exam", timeMinutes: 30, passingScore: 70 },
  },
];

let globalEnrollments = {};
let globalSubmissions = {};
let globalCertificates = [];

// AWS RDS PostgreSQL pool
const pool = new Pool({
  connectionString: process.env.DATABASE_URL || "postgresql://postgres:postgres@localhost:5432/myvault",
  ssl: process.env.DATABASE_URL ? { rejectUnauthorized: false } : false,
});

async function initDb() {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS job_listings (
        id TEXT PRIMARY KEY, title TEXT NOT NULL, company TEXT NOT NULL,
        type TEXT NOT NULL, category TEXT, apply_url TEXT, branch TEXT,
        stipend TEXT, location TEXT, deadline DATE, description TEXT,
        posted_at TIMESTAMPTZ DEFAULT NOW()
      );
      CREATE TABLE IF NOT EXISTS internship_courses (
        id TEXT PRIMARY KEY, title TEXT NOT NULL, category TEXT NOT NULL,
        level TEXT, duration TEXT, is_free BOOLEAN DEFAULT TRUE,
        data JSONB NOT NULL, created_at TIMESTAMPTZ DEFAULT NOW()
      );
      CREATE TABLE IF NOT EXISTS student_course_enrollments (
        id BIGSERIAL PRIMARY KEY, student_id TEXT NOT NULL, course_id TEXT NOT NULL,
        completed_lessons JSONB DEFAULT '[]', is_completed BOOLEAN DEFAULT FALSE,
        enrolled_at TIMESTAMPTZ DEFAULT NOW(), UNIQUE(student_id, course_id)
      );
      CREATE TABLE IF NOT EXISTS student_certificates (
        id TEXT PRIMARY KEY, student_name TEXT NOT NULL, title TEXT NOT NULL,
        certificate_number TEXT NOT NULL UNIQUE, pdf_url TEXT NOT NULL,
        issued_at TIMESTAMPTZ DEFAULT NOW()
      );
    `);

    // Purge test listings from database on startup
    await pool.query(`DELETE FROM job_listings WHERE title ILIKE '%TSPSC%' OR title ILIKE '%Frontend%' OR title ILIKE '%html%' OR title ILIKE '%jhbb%' OR apply_url ILIKE '%example.com%'`);
    console.log("Database initialized & purged test listings.");
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

// =================================================================
// ADMIN ANALYTICS ENDPOINTS
// =================================================================

app.get(["/admin/analytics/overview", "/api/admin/analytics/overview"], async (req, res) => {
  let cleanJobs = globalJobListings.filter((j) => !isTestListing(j));
  try {
    const dbRes = await pool.query(`SELECT * FROM job_listings`);
    const validDbJobs = dbRes.rows.filter((j) => !isTestListing(j));
    cleanJobs = validDbJobs;
  } catch (_) {}

  res.json({ students: 1, notes: 0, jobListings: cleanJobs.length, examsCount: 0, results: 0 });
});

app.get(["/admin/analytics/recent-uploads", "/api/admin/analytics/recent-uploads"], async (req, res) => {
  let cleanJobs = globalJobListings.filter((j) => !isTestListing(j));
  try {
    const dbRes = await pool.query(`SELECT * FROM job_listings ORDER BY posted_at DESC`);
    cleanJobs = dbRes.rows.filter((j) => !isTestListing(j)).map((j) => ({
      id: j.id,
      title: j.title,
      company: j.company,
      type: j.type,
      branch: j.branch,
      applyUrl: j.apply_url || j.applyUrl,
      fileUrl: j.file_url || j.fileUrl,
      postedAt: j.posted_at || j.postedAt,
    }));
  } catch (_) {}

  res.json({
    recentNotes: [],
    recentJobs: cleanJobs,
    recentExams: [],
    recentResults: [],
    allStudents: [{ id: "s1", hallTicket: "21A91A0501", fullName: "Rahul Kumar", branch: "CSE", semester: 6, createdAt: new Date().toISOString() }],
  });
});

// =================================================================
// INTERNSHIP LEARNING HUB: COURSE APIs
// =================================================================

app.get(["/api/courses", "/admin/courses"], (req, res) => {
  const { category } = req.query;
  let items = [...globalCourses];
  if (category && category !== "All") {
    items = items.filter((c) => c.category.toLowerCase() === category.toLowerCase());
  }
  res.json({ success: true, data: items });
});

app.get("/api/courses/:courseId", (req, res) => {
  const { courseId } = req.params;
  const course = globalCourses.find((c) => c.id.toLowerCase() === courseId.toLowerCase());
  res.json({ success: true, data: course || globalCourses[0] });
});

app.post("/api/courses/:courseId/enroll", (req, res) => {
  const { courseId } = req.params;
  const { studentId = "student_1" } = req.body;
  const key = `${studentId}_${courseId}`;

  if (!globalEnrollments[key]) {
    globalEnrollments[key] = {
      studentId,
      courseId,
      completedLessons: [],
      isCompleted: false,
      enrolledAt: new Date().toISOString(),
    };
  }

  res.json({ success: true, enrollment: globalEnrollments[key] });
});

app.post("/api/lessons/:lessonId/complete", (req, res) => {
  const { lessonId } = req.params;
  const { studentId = "student_1", courseId = "course_flutter_dev" } = req.body;
  const key = `${studentId}_${courseId}`;

  if (!globalEnrollments[key]) {
    globalEnrollments[key] = { studentId, courseId, completedLessons: [], isCompleted: false, enrolledAt: new Date().toISOString() };
  }

  if (!globalEnrollments[key].completedLessons.includes(lessonId)) {
    globalEnrollments[key].completedLessons.push(lessonId);
  }

  res.json({ success: true, completedLessons: globalEnrollments[key].completedLessons });
});

app.post("/api/assignments/:assignmentId/submit", (req, res) => {
  const { assignmentId } = req.params;
  const { studentId = "student_1", submissionUrl = "", repoUrl = "" } = req.body;

  globalSubmissions[`${studentId}_${assignmentId}`] = {
    studentId,
    assignmentId,
    submissionUrl,
    repoUrl,
    status: "PASSED",
    submittedAt: new Date().toISOString(),
  };

  res.json({ success: true, status: "PASSED" });
});

app.post("/api/courses/:courseId/final-exam/submit", async (req, res) => {
  const { courseId } = req.params;
  const { studentId = "student_1", studentName = "Rahul Kumar", score = 85 } = req.body;

  const course = globalCourses.find((c) => c.id === courseId) || globalCourses[0];
  const certNumber = `IH-CERT-${Math.floor(100000 + Math.random() * 900000)}`;

  try {
    const doc = new PDFDocument({ layout: "landscape", size: "A4", margin: 40 });
    const chunks = [];
    doc.on("data", (chunk) => chunks.push(chunk));

    doc.rect(20, 20, doc.page.width - 40, doc.page.height - 40).lineWidth(4).strokeColor("#00C48C").stroke();
    doc.rect(26, 26, doc.page.width - 52, doc.page.height - 52).lineWidth(1).strokeColor("#3E7BFF").stroke();

    doc.fontSize(28).fillColor("#3E7BFF").text("INTERNSHIP HUB CERTIFICATE OF COMPLETION", { align: "center" });
    doc.moveDown(0.5);
    doc.fontSize(14).fillColor("#555555").text("This is to certify that", { align: "center" });
    doc.moveDown(0.4);

    doc.fontSize(26).fillColor("#000000").text(studentName.toUpperCase(), { align: "center" });
    doc.moveDown(0.4);

    doc.fontSize(14).fillColor("#555555").text("has successfully completed the industrial internship course & exam for", { align: "center" });
    doc.moveDown(0.4);
    doc.fontSize(22).fillColor("#00C48C").text(course.title, { align: "center" });
    doc.moveDown(1);

    const dateStr = new Date().toLocaleDateString("en-IN");
    doc.fontSize(11).fillColor("#444444").text(`Issued On: ${dateStr}   |   Certificate ID: ${certNumber}`, { align: "center" });

    const qrDataUrl = await QRCode.toDataURL(`https://myvault-project.vercel.app/verify/${certNumber}`);
    const qrImageBuffer = Buffer.from(qrDataUrl.split(",")[1], "base64");
    doc.image(qrImageBuffer, doc.page.width / 2 - 40, 410, { width: 80 });

    doc.end();
    await new Promise((resolve) => doc.on("end", resolve));

    const pdfBuffer = Buffer.concat(chunks);
    const s3Key = `internships/certificates/${certNumber}.pdf`;

    try {
      await s3.send(new PutObjectCommand({ Bucket: S3_BUCKET, Key: s3Key, Body: pdfBuffer, ContentType: "application/pdf", ACL: "public-read" }));
    } catch (_) {}

    const certRecord = {
      id: certNumber,
      studentName,
      title: course.title,
      certificateNumber: certNumber,
      pdfUrl: s3PublicUrl(s3Key),
      issuedAt: new Date().toISOString(),
    };

    globalCertificates.unshift(certRecord);
    res.status(201).json({ success: true, certificate: certRecord });
  } catch (err) {
    res.status(500).json({ error: "Certificate generation failed: " + err.message });
  }
});

app.get("/api/students/:studentId/certificates", (req, res) => {
  res.json({ success: true, data: globalCertificates });
});

// =================================================================
// JOB & INTERNSHIP LISTINGS APIs (Clean, Admin-driven)
// =================================================================

app.get(["/job-listings", "/api/job-listings", "/admin/job-listings"], async (req, res) => {
  const { type } = req.query;
  let items = globalJobListings.filter((j) => !isTestListing(j));
  try {
    const dbRes = await pool.query(`SELECT * FROM job_listings ORDER BY posted_at DESC`);
    if (dbRes.rows && dbRes.rows.length > 0) {
      items = dbRes.rows.map((j) => ({
        id: j.id,
        title: j.title,
        company: j.company,
        type: j.type,
        applyUrl: j.apply_url || j.applyUrl,
        branch: j.branch,
        fileUrl: j.file_url || j.fileUrl,
        stipend: j.stipend,
        location: j.location,
        deadline: j.deadline,
        description: j.description,
        postedAt: j.posted_at || j.postedAt,
      })).filter((j) => !isTestListing(j));
    }
  } catch (_) {}

  if (type) items = items.filter((j) => j.type.toUpperCase() === String(type).toUpperCase());
  res.json(items);
});

app.post(["/admin/job-listings/confirm", "/api/admin/job-listings/confirm"], async (req, res) => {
  const { title, company, type = "INTERNSHIP", applyUrl, branch, fileUrl, stipend, location, deadline, description } = req.body;
  const newJob = {
    id: `job_${Date.now()}_${Math.floor(Math.random() * 1000)}`,
    title: title || "New Opportunity",
    company: company || "Organization",
    type,
    applyUrl: applyUrl || "https://myvault-project.vercel.app",
    branch: branch || "All Branches",
    fileUrl: fileUrl || null,
    stipend: stipend || null,
    location: location || null,
    deadline: deadline || null,
    description: description || null,
    postedAt: new Date().toISOString(),
  };

  globalJobListings.unshift(newJob);

  try {
    await pool.query(
      `INSERT INTO job_listings (id, title, company, type, apply_url, branch, file_url, stipend, location, deadline, description, posted_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, NOW())`,
      [newJob.id, newJob.title, newJob.company, newJob.type, newJob.applyUrl, newJob.branch, newJob.fileUrl, newJob.stipend, newJob.location, newJob.deadline, newJob.description]
    );
  } catch (_) {}

  res.status(201).json(newJob);
});

// Clear ALL dummy/test listings endpoint (MUST BE BEFORE :id)
app.delete(["/admin/job-listings", "/api/job-listings", "/api/admin/job-listings"], async (req, res) => {
  globalJobListings = [];
  try {
    await pool.query(`TRUNCATE TABLE job_listings`);
  } catch (_) {}
  res.json({ success: true, message: "All job listings cleared cleanly." });
});

// Delete single job listing by ID
app.delete(["/admin/job-listings/:id", "/api/job-listings/:id", "/api/admin/job-listings/:id"], async (req, res) => {
  const { id } = req.params;
  globalJobListings = globalJobListings.filter((j) => String(j.id) !== String(id));
  try {
    await pool.query(`DELETE FROM job_listings WHERE id = $1`, [id]);
  } catch (_) {}
  res.json({ success: true, id });
});

const PORT = process.env.PORT || 4000;
app.listen(PORT, () => {
  console.log(`🚀 MyVault Server listening on port ${PORT}`);
});
