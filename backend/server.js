require("dotenv").config();

const express = require("express");
const cors = require("cors");
const { Pool } = require("pg");

const app = express();

app.use(cors());
app.use(express.json({ limit: "2mb" }));

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.DATABASE_URL ? { rejectUnauthorized: false } : false,
});

app.get("/", (req, res) => {
  res.json({ success: true, service: "MyVault LMS Backend", status: "online" });
});

app.get("/health", async (req, res) => {
  try {
    await pool.query("SELECT 1");
    res.json({ success: true, database: "connected", status: "healthy" });
  } catch (error) {
    res.status(500).json({ success: false, database: "disconnected", status: "unhealthy" });
  }
});

app.use("/auth", require("./routes/auth"));
app.use("/notes", require("./routes/notes"));
app.use("/academic/content", require("./routes/notes"));
app.use("/subjects", require("./routes/notes"));
app.use("/internships", require("./routes/internships"));
app.use("/job-listings", require("./routes/internships"));
app.use("/admin/notes", require("./routes/admin/notes"));
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

if (!process.env.JWT_SECRET) {
  console.error("Refusing to start: JWT_SECRET is not set in the environment.");
  process.exit(1);
}

app.listen(PORT, () => {
  console.log(`MyVault LMS backend listening on port ${PORT}`);
});
