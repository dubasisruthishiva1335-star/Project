require("dotenv").config();

const express = require("express");
const cors = require("cors");
const { Pool } = require("pg");

const app = express();

app.use(cors());
app.use(express.json({ limit: "2mb" }));

const { pool, isRemote } = require("./services/db");

// Auto-initialize DB tables on startup (non-blocking)
if (isRemote) {
  pool.query(`
    CREATE TABLE IF NOT EXISTS academic_materials (
      id            VARCHAR(100) PRIMARY KEY,
      title         VARCHAR(255) NOT NULL,
      branch        VARCHAR(100) NOT NULL DEFAULT 'GENERAL',
      semester      INTEGER NOT NULL DEFAULT 1,
      unit          INTEGER NOT NULL DEFAULT 1,
      content_type  VARCHAR(64) NOT NULL DEFAULT 'NOTES',
      file_url      TEXT NOT NULL,
      s3_key        TEXT,
      uploaded_at   TIMESTAMP NOT NULL DEFAULT NOW()
    );
  `).catch((err) => {
    console.warn("Notice: Database initialization deferred:", err.message);
  });
}

app.get("/", (req, res) => {
  res.status(200).json({ success: true, service: "MyVault LMS Backend", status: "online" });
});

app.get("/health", async (req, res) => {
  let dbStatus = "disconnected";
  try {
    if (isRemote) {
      await pool.query("SELECT 1");
      dbStatus = "connected";
    }
  } catch (_) {}
  res.status(200).json({ success: true, database: dbStatus, status: "healthy" });
});

app.use("/auth", require("./routes/auth"));
app.use("/notes", require("./routes/notes"));
app.use("/academic/content", require("./routes/notes"));
app.use("/subjects", require("./routes/notes"));
app.use("/exams", require("./routes/exams"));
app.use("/competitive-exams", require("./routes/exams"));
app.use("/internships", require("./routes/admin/internships"));
app.use("/job-listings", require("./routes/admin/internships"));
app.use("/admin/notes", require("./routes/admin/notes"));
app.use("/admin/exams", require("./routes/admin/exams"));
app.use("/admin/preparation", require("./routes/admin/exams"));
app.use("/admin/internships", require("./routes/admin/internships"));
app.use("/admin/job-listings", require("./routes/admin/internships"));
app.use("/admin/analytics", require("./routes/admin/analytics"));
app.use("/certificates", require("./routes/certificates"));

// Centralized error handler — keeps stray thrown errors from crashing the process
// and from leaking stack traces to clients.
app.use((err, req, res, next) => {
  console.error("Unhandled error:", err);
  res.status(500).json({ error: "Internal server error" });
});

const PORT = process.env.PORT || 4000;
const JWT_SECRET = process.env.JWT_SECRET || "myvault_jwt_secret_key_production_2026";
process.env.JWT_SECRET = JWT_SECRET;

app.listen(PORT, "0.0.0.0", () => {
  console.log(`MyVault LMS backend listening on port ${PORT}`);
});
