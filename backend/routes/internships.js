const express = require("express");
const crypto = require("crypto");
const { Pool } = require("pg");
const { studentAuth } = require("../middleware/adminAuth");
const { generateCertificate } = require("../services/certificate.service");

const router = express.Router();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.DATABASE_URL ? { rejectUnauthorized: false } : false,
});

function generateId(prefix) {
  return `${prefix}_${Date.now()}_${crypto.randomBytes(5).toString("hex")}`;
}

/**
 * GET /internships (and /job-listings)
 * Public listing — supports type and branch filtering with dual camelCase & snake_case formatting.
 */
router.get("/", async (req, res) => {
  const { type, branch, isLmsEnabled } = req.query;
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS internships (
        id                   VARCHAR(100) PRIMARY KEY,
        title                VARCHAR(255) NOT NULL,
        company              VARCHAR(255) NOT NULL DEFAULT 'Organization',
        type                 VARCHAR(64) NOT NULL DEFAULT 'INTERNSHIP',
        is_lms_enabled       BOOLEAN NOT NULL DEFAULT false,
        certificate_enabled BOOLEAN NOT NULL DEFAULT false,
        branch               VARCHAR(100) NOT NULL DEFAULT 'All Branches',
        stipend              VARCHAR(100),
        location             VARCHAR(255),
        deadline             TIMESTAMP,
        description          TEXT,
        apply_url            TEXT,
        file_url             TEXT,
        s3_key               TEXT,
        duration             VARCHAR(100),
        max_students         INTEGER,
        status               VARCHAR(64) NOT NULL DEFAULT 'PUBLISHED',
        posted_at            TIMESTAMP NOT NULL DEFAULT NOW()
      );
      CREATE TABLE IF NOT EXISTS internship_modules (
        id            VARCHAR(100) PRIMARY KEY,
        internship_id VARCHAR(100) NOT NULL REFERENCES internships(id) ON DELETE CASCADE,
        title         VARCHAR(255) NOT NULL,
        order_index   INTEGER NOT NULL DEFAULT 1,
        created_at    TIMESTAMP NOT NULL DEFAULT NOW()
      );
      CREATE TABLE IF NOT EXISTS internship_lessons (
        id            VARCHAR(100) PRIMARY KEY,
        module_id     VARCHAR(100) NOT NULL REFERENCES internship_modules(id) ON DELETE CASCADE,
        title         VARCHAR(255) NOT NULL,
        duration      VARCHAR(50),
        video_url     TEXT,
        pdf_url       TEXT,
        is_preview    BOOLEAN NOT NULL DEFAULT false,
        order_index   INTEGER NOT NULL DEFAULT 1,
        created_at    TIMESTAMP NOT NULL DEFAULT NOW()
      );
    `);

    let query = `
      SELECT
        i.*,
        COUNT(DISTINCT m.id)::int AS module_count,
        COUNT(DISTINCT l.id)::int AS lesson_count
      FROM internships i
      LEFT JOIN internship_modules m ON m.internship_id = i.id
      LEFT JOIN internship_lessons l ON l.module_id = m.id
      WHERE 1=1
    `;
    const params = [];

    if (type) {
      params.push(String(type).toUpperCase());
      query += ` AND UPPER(i.type) = $${params.length}`;
    }

    if (branch && branch !== 'ALL' && branch !== 'All Branches') {
      params.push(branch);
      query += ` AND (i.branch = $${params.length} OR i.branch = 'All Branches')`;
    }

    query += ` GROUP BY i.id ORDER BY i.posted_at DESC`;
    const result = await pool.query(query, params);

    const formatted = result.rows.map((j) => ({
      id: j.id,
      title: j.title,
      company: j.company,
      type: j.type,
      isLmsEnabled: Boolean(j.is_lms_enabled),
      is_lms_enabled: Boolean(j.is_lms_enabled),
      branch: j.branch,
      stipend: j.stipend,
      location: j.location,
      deadline: j.deadline,
      description: j.description,
      applyUrl: j.apply_url,
      apply_url: j.apply_url,
      fileUrl: j.file_url,
      file_url: j.file_url,
      s3Key: j.s3_key,
      postedAt: j.posted_at,
      posted_at: j.posted_at,
      moduleCount: j.module_count,
      lessonCount: j.lesson_count,
    }));

    res.json(formatted);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to load internships" });
  }
});

/**
 * GET /internships/:id
 * Course detail + modules/lessons.
 */
router.get("/:id", async (req, res) => {
  try {
    const course = await pool.query(
      `SELECT * FROM internships WHERE id = $1`,
      [req.params.id]
    );
    if (!course.rows.length) return res.status(404).json({ error: "Course not found" });

    const modules = await pool.query(
      `SELECT * FROM internship_modules WHERE internship_id = $1 ORDER BY sort_order ASC, created_at ASC`,
      [req.params.id]
    );

    const moduleIds = modules.rows.map((m) => m.id);
    let lessonsByModule = {};
    let completedLessonIds = new Set();

    if (moduleIds.length) {
      const lessons = await pool.query(
        `SELECT * FROM internship_lessons WHERE module_id = ANY($1::text[]) ORDER BY sort_order ASC, created_at ASC`,
        [moduleIds]
      );
      lessonsByModule = lessons.rows.reduce((acc, lesson) => {
        (acc[lesson.module_id] ||= []).push(lesson);
        return acc;
      }, {});

      const header = req.headers.authorization || "";
      const [scheme, token] = header.split(" ");
      if (scheme === "Bearer" && token) {
        try {
          const jwt = require("jsonwebtoken");
          const payload = jwt.verify(token, process.env.JWT_SECRET);
          const lessonIds = lessons.rows.map((l) => l.id);
          if (lessonIds.length) {
            const progress = await pool.query(
              `SELECT lesson_id FROM internship_lesson_progress WHERE student_id = $1 AND lesson_id = ANY($2::text[])`,
              [payload.id, lessonIds]
            );
            completedLessonIds = new Set(progress.rows.map((r) => r.lesson_id));
          }
        } catch {
          // Invalid token on public route — ignore
        }
      }
    }

    const result = modules.rows.map((m) => ({
      ...m,
      lessons: (lessonsByModule[m.id] || []).map((l) => ({
        ...l,
        completed: completedLessonIds.has(l.id),
      })),
    }));

    res.json({ ...course.rows[0], modules: result });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to load course" });
  }
});

/**
 * POST /internships/:id/enroll
 */
router.post("/:id/enroll", studentAuth, async (req, res) => {
  try {
    const studentId = req.student.id;

    const course = await pool.query(
      `SELECT id, max_students FROM internships WHERE id = $1`,
      [req.params.id]
    );
    if (!course.rows.length) return res.status(404).json({ error: "Course not found" });

    if (course.rows[0].max_students) {
      const count = await pool.query(
        `SELECT COUNT(*)::int AS n FROM internship_enrollments WHERE internship_id = $1`,
        [req.params.id]
      );
      if (count.rows[0].n >= course.rows[0].max_students) {
        return res.status(400).json({ error: "This course has reached its enrollment limit" });
      }
    }

    const enrollmentId = generateId("enroll");

    await pool.query(
      `
      INSERT INTO internship_enrollments (id, internship_id, student_id, enrolled_at)
      VALUES ($1,$2,$3,NOW())
      ON CONFLICT (internship_id, student_id) DO NOTHING
      `,
      [enrollmentId, req.params.id, studentId]
    );

    res.status(201).json({ success: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to enroll" });
  }
});

/**
 * POST /internships/lessons/:lessonId/complete
 */
router.post("/lessons/:lessonId/complete", studentAuth, async (req, res) => {
  const studentId = req.student.id;
  const studentName = req.student.name || null;
  const { watchPercent = 100 } = req.body;

  const client = await pool.connect();

  try {
    await client.query("BEGIN");

    const lessonRow = await client.query(
      `
      SELECT l.id, m.internship_id
      FROM internship_lessons l
      JOIN internship_modules m ON m.id = l.module_id
      WHERE l.id = $1
      `,
      [req.params.lessonId]
    );

    if (!lessonRow.rows.length) {
      await client.query("ROLLBACK");
      return res.status(404).json({ error: "Lesson not found" });
    }

    const internshipId = lessonRow.rows[0].internship_id;

    const enrollment = await client.query(
      `SELECT id FROM internship_enrollments WHERE internship_id = $1 AND student_id = $2`,
      [internshipId, studentId]
    );

    if (!enrollment.rows.length) {
      await client.query("ROLLBACK");
      return res.status(403).json({ error: "You are not enrolled in this course" });
    }

    await client.query(
      `
      INSERT INTO internship_lesson_progress (id, lesson_id, student_id, watch_percent, completed_at)
      VALUES ($1,$2,$3,$4,NOW())
      ON CONFLICT (lesson_id, student_id) DO UPDATE SET watch_percent = EXCLUDED.watch_percent
      `,
      [generateId("progress"), req.params.lessonId, studentId, Number(watchPercent)]
    );

    await client.query("COMMIT");

    const totalResult = await pool.query(
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

    const total = totalResult.rows[0].total;
    const completed = completedResult.rows[0].completed;
    const isComplete = total > 0 && completed >= total;

    let certificateIssued = false;
    let certUrl = null;

    if (isComplete) {
      try {
        const certificate = await generateCertificate({
          internshipId,
          studentId,
          studentName,
        });
        certificateIssued = true;
        certUrl = certificate.certificate_url;
      } catch (certErr) {
        console.warn("Certificate not issued:", certErr.message);
      }
    }

    res.json({
      success: true,
      completed: isComplete,
      progress: { completed, total },
      certificateIssued,
      certUrl,
    });
  } catch (err) {
    await client.query("ROLLBACK");
    console.error(err);
    res.status(500).json({ error: "Failed to mark lesson complete" });
  } finally {
    client.release();
  }
});

/**
 * GET /internships/:id/certificate
 */
router.get("/:id/certificate", studentAuth, async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT * FROM internship_certificates WHERE internship_id = $1 AND student_id = $2`,
      [req.params.id, req.student.id]
    );
    if (!result.rows.length) return res.status(404).json({ error: "Certificate not yet issued" });
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to load certificate" });
  }
});

module.exports = router;
