/**
 * Campus App Backend — Node/Express (AWS RDS + S3 backed)
 * -----------------------------------------------------------
 * Powers Admin Dashboard & Mobile App:
 *   1. Job & Internship Opportunities (Placements, Stipends, Hiring Drives)
 *   2. Academic Resources & Notes
 *   3. Results & AI Performance Analyzer
 *   4. Competitive Exam Preparation Hub
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

// Mount Two-Mode Internships & Jobs LMS Routes
try {
  app.use('/internships', require('./routes/internships'));
  app.use('/admin/internships', require('./routes/admin/internships'));
  app.use('/certificates', require('./routes/certificates'));
} catch (e) {
  console.warn('Routes mount notice:', e.message);
}

// ---------------------------------------------------------------
// In-Memory Global Store for Published Opportunities
// ---------------------------------------------------------------
let globalJobListings = [];

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
    `);

    // Load existing database listings into memory on startup
    const dbRes = await pool.query(`SELECT * FROM job_listings ORDER BY posted_at DESC`);
    if (dbRes.rows && dbRes.rows.length > 0) {
      globalJobListings = dbRes.rows.map((j) => ({
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
      }));
    }
    console.log(`Database initialized. ${globalJobListings.length} job listings loaded.`);
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
  let count = globalJobListings.length;
  try {
    const dbRes = await pool.query(`SELECT COUNT(*) FROM job_listings`);
    if (dbRes.rows[0]?.count) count = parseInt(dbRes.rows[0].count, 10);
  } catch (_) {}

  res.json({ students: 1, notes: 0, jobListings: count, examsCount: 0, results: 0 });
});

app.get(["/admin/analytics/recent-uploads", "/api/admin/analytics/recent-uploads"], async (req, res) => {
  let items = [...globalJobListings];
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
      }));
    }
  } catch (_) {}

  res.json({
    recentNotes: [],
    recentJobs: items,
    recentExams: [],
    recentResults: [],
    allStudents: [{ id: "s1", hallTicket: "21A91A0501", fullName: "Rahul Kumar", branch: "CSE", semester: 6, createdAt: new Date().toISOString() }],
  });
});

// =================================================================
// JOB & INTERNSHIP LISTINGS APIs (Direct Admin Upload & Display)
// =================================================================

app.get(["/job-listings", "/api/job-listings", "/admin/job-listings", "/api/internship-hub/opportunities"], async (req, res) => {
  const { type } = req.query;
  let items = [...globalJobListings];

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
      }));
    }
  } catch (_) {}

  if (type) {
    items = items.filter((j) => String(j.type).toUpperCase() === String(type).toUpperCase());
  }

  res.json(items);
});

app.post(["/admin/job-listings/confirm", "/api/admin/job-listings/confirm"], async (req, res) => {
  const { title, company, type = "INTERNSHIP", applyUrl, branch, fileUrl, stipend, location, deadline, description, s3Key, key, publicUrl } = req.body;
  
  const finalFileUrl = publicUrl || fileUrl || (s3Key || key ? s3PublicUrl(s3Key || key) : null);

  const newJob = {
    id: `job_${Date.now()}_${Math.floor(Math.random() * 1000)}`,
    title: title || "New Opportunity",
    company: company || "Organization",
    type,
    applyUrl: applyUrl || "https://myvault-project.vercel.app",
    branch: branch || "All Branches",
    fileUrl: finalFileUrl,
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
  } catch (err) {
    console.error("DB Insert Error:", err.message);
  }

  res.status(201).json(newJob);
});

// Clear ALL dummy/test listings endpoint
app.delete(["/admin/job-listings", "/api/job-listings", "/api/admin/job-listings"], async (req, res) => {
  globalJobListings = [];
  try {
    await pool.query(`TRUNCATE TABLE job_listings CASCADE`);
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
