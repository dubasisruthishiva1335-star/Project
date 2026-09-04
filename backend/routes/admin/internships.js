const express = require("express");
const crypto = require("crypto");
const { pool } = require("../../services/db");
const { adminAuth } = require("../../middleware/adminAuth");
const { createPresignedUploadUrl } = require("../../services/s3.service");

const router = express.Router();

// Admin authentication middleware (disabled by default for developer ease, optionally enabled)
// router.use(adminAuth);

function generateId(prefix) {
  return `${prefix}_${Date.now()}_${crypto.randomBytes(5).toString("hex")}`;
}

/**
 * GET /admin/internships
 */
router.get("/", async (req, res) => {
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
      CREATE TABLE IF NOT EXISTS internship_enrollments (
        id            VARCHAR(100) PRIMARY KEY,
        student_id    VARCHAR(100) NOT NULL,
        internship_id VARCHAR(100) NOT NULL REFERENCES internships(id) ON DELETE CASCADE,
        enrolled_at   TIMESTAMP NOT NULL DEFAULT NOW(),
        UNIQUE (student_id, internship_id)
      );
    `);

    const result = await pool.query(`
      SELECT
        i.*,
        COUNT(DISTINCT e.id)::int AS enrollment_count,
        COUNT(DISTINCT m.id)::int AS module_count,
        COUNT(DISTINCT l.id)::int AS lesson_count
      FROM internships i
      LEFT JOIN internship_enrollments e ON e.internship_id = i.id
      LEFT JOIN internship_modules m ON m.internship_id = i.id
      LEFT JOIN internship_lessons l ON l.module_id = m.id
      GROUP BY i.id
      ORDER BY i.posted_at DESC
    `);
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to load internships" });
  }
});

/**
 * GET /admin/internships/:id
 * Full course tree for editor.
 */
router.get("/:id", async (req, res) => {
  try {
    const course = await pool.query(`SELECT * FROM internships WHERE id = $1`, [req.params.id]);
    if (!course.rows.length) {
      return res.status(404).json({ error: "Internship/course not found" });
    }

    const modules = await pool.query(
      `SELECT * FROM internship_modules WHERE internship_id = $1 ORDER BY sort_order ASC, created_at ASC`,
      [req.params.id]
    );

    const moduleIds = modules.rows.map((m) => m.id);
    let lessonsByModule = {};

    if (moduleIds.length) {
      const lessons = await pool.query(
        `SELECT * FROM internship_lessons WHERE module_id = ANY($1::text[]) ORDER BY sort_order ASC, created_at ASC`,
        [moduleIds]
      );
      lessonsByModule = lessons.rows.reduce((acc, lesson) => {
        (acc[lesson.module_id] ||= []).push(lesson);
        return acc;
      }, {});
    }

    const result = modules.rows.map((m) => ({
      ...m,
      lessons: lessonsByModule[m.id] || [],
    }));

    res.json({ ...course.rows[0], modules: result });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to load course" });
  }
});

/**
 * POST /admin/internships/upload-url
 * Presigned S3 upload URL.
 */
router.post("/upload-url", async (req, res) => {
  try {
    const { filename, contentType, folder } = req.body;
    const result = await createPresignedUploadUrl({ filename, contentType, folder });
    res.json(result);
  } catch (err) {
    console.error("Presign error:", err);
    res.status(500).json({ error: "Could not create upload URL" });
  }
});

/**
 * POST /admin/internships/confirm
 * Create or update course/internship.
 */
router.post("/confirm", async (req, res) => {
  const {
    id: bodyId,
    title,
    company,
    type = "INTERNSHIP",
    isLmsEnabled = false,
    certificateEnabled = false,
    branch = "All Branches",
    stipend,
    location,
    deadline,
    description,
    applyUrl,
    fileUrl,
    s3Key,
    publicUrl,
    duration,
    maxStudents,
  } = req.body;

  const courseId = bodyId || generateId("course");
  const finalDeadline = (deadline && String(deadline).trim() !== "") ? new Date(deadline) : null;

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
    `);

    await pool.query(
      `
      INSERT INTO internships (
        id, title, company, type, is_lms_enabled, certificate_enabled,
        branch, stipend, location, deadline, description, apply_url,
        file_url, s3_key, duration, max_students, status, posted_at
      )
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,'PUBLISHED',NOW())
      ON CONFLICT (id) DO UPDATE SET
        title = EXCLUDED.title,
        company = EXCLUDED.company,
        type = EXCLUDED.type,
        is_lms_enabled = EXCLUDED.is_lms_enabled,
        certificate_enabled = EXCLUDED.certificate_enabled,
        branch = EXCLUDED.branch,
        stipend = EXCLUDED.stipend,
        location = EXCLUDED.location,
        deadline = EXCLUDED.deadline,
        description = EXCLUDED.description,
        apply_url = EXCLUDED.apply_url,
        file_url = EXCLUDED.file_url,
        s3_key = EXCLUDED.s3_key,
        duration = EXCLUDED.duration,
        max_students = EXCLUDED.max_students,
        status = 'PUBLISHED'
      `,
      [
        courseId,
        title || "New Internship Opportunity",
        company || "Organization",
        type || "INTERNSHIP",
        Boolean(isLmsEnabled === true || isLmsEnabled === "true"),
        Boolean(certificateEnabled === true || certificateEnabled === "true"),
        branch || "All Branches",
        stipend || null,
        location || null,
        finalDeadline,
        description || null,
        applyUrl || null,
        publicUrl || fileUrl || null,
        s3Key || null,
        duration || null,
        maxStudents ? Number(maxStudents) : null,
      ]
    );

    const result = await pool.query(`SELECT * FROM internships WHERE id = $1`, [courseId]);
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error("Course save error:", err);
    res.status(500).json({ error: "Failed to save internship/course", details: err.message });
  }
});

/**
 * POST /admin/internships/:id/publish
 */
router.post("/:id/publish", async (req, res) => {
  try {
    const result = await pool.query(
      `UPDATE internships SET status = 'PUBLISHED' WHERE id = $1 RETURNING *`,
      [req.params.id]
    );
    if (!result.rows.length) return res.status(404).json({ error: "Course not found" });
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to publish course" });
  }
});

/**
 * POST /admin/internships/:id/modules
 */
router.post("/:id/modules", async (req, res) => {
  try {
    const moduleId = generateId("mod");
    const { title = "New Module", sortOrder = 1 } = req.body;

    const course = await pool.query(`SELECT id FROM internships WHERE id = $1`, [req.params.id]);
    if (!course.rows.length) return res.status(404).json({ error: "Course not found" });

    await pool.query(
      `INSERT INTO internship_modules (id, internship_id, title, sort_order, created_at) VALUES ($1,$2,$3,$4,NOW())`,
      [moduleId, req.params.id, title, Number(sortOrder)]
    );

    res.status(201).json({ id: moduleId, internshipId: req.params.id, title, sortOrder: Number(sortOrder) });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to create module" });
  }
});

/**
 * PUT /admin/internships/modules/:moduleId
 */
router.put("/modules/:moduleId", async (req, res) => {
  try {
    const { title, sortOrder } = req.body;
    const result = await pool.query(
      `UPDATE internship_modules SET title = COALESCE($1, title), sort_order = COALESCE($2, sort_order) WHERE id = $3 RETURNING *`,
      [title || null, sortOrder !== undefined ? Number(sortOrder) : null, req.params.moduleId]
    );
    if (!result.rows.length) return res.status(404).json({ error: "Module not found" });
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to update module" });
  }
});

/**
 * DELETE /admin/internships/modules/:moduleId
 */
router.delete("/modules/:moduleId", async (req, res) => {
  try {
    await pool.query(`DELETE FROM internship_modules WHERE id = $1`, [req.params.moduleId]);
    res.json({ success: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to delete module" });
  }
});

/**
 * POST /admin/internships/modules/:moduleId/lessons
 */
router.post("/modules/:moduleId/lessons", async (req, res) => {
  try {
    const lessonId = generateId("lesson");
    const {
      title = "New Lesson",
      contentType = "VIDEO",
      videoUrl = null,
      pdfUrl = null,
      description = null,
      duration = "15 mins",
      sortOrder = 1,
      isRequired = true,
    } = req.body;

    const moduleRow = await pool.query(`SELECT id FROM internship_modules WHERE id = $1`, [req.params.moduleId]);
    if (!moduleRow.rows.length) return res.status(404).json({ error: "Module not found" });

    await pool.query(
      `
      INSERT INTO internship_lessons (
        id, module_id, title, content_type, video_url, pdf_url,
        description, duration, sort_order, is_required, created_at
      )
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,NOW())
      `,
      [
        lessonId,
        req.params.moduleId,
        title,
        contentType,
        videoUrl,
        pdfUrl,
        description,
        duration,
        Number(sortOrder),
        Boolean(isRequired),
      ]
    );

    const result = await pool.query(`SELECT * FROM internship_lessons WHERE id = $1`, [lessonId]);
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to create lesson" });
  }
});

/**
 * PUT /admin/internships/lessons/:lessonId
 */
router.put("/lessons/:lessonId", async (req, res) => {
  try {
    const { title, contentType, videoUrl, pdfUrl, description, duration, sortOrder, isRequired } = req.body;

    const result = await pool.query(
      `
      UPDATE internship_lessons SET
        title = COALESCE($1,title),
        content_type = COALESCE($2,content_type),
        video_url = COALESCE($3,video_url),
        pdf_url = COALESCE($4,pdf_url),
        description = COALESCE($5,description),
        duration = COALESCE($6,duration),
        sort_order = COALESCE($7,sort_order),
        is_required = COALESCE($8,is_required)
      WHERE id = $9
      RETURNING *
      `,
      [
        title || null,
        contentType || null,
        videoUrl || null,
        pdfUrl || null,
        description || null,
        duration || null,
        sortOrder !== undefined ? Number(sortOrder) : null,
        isRequired !== undefined ? Boolean(isRequired) : null,
        req.params.lessonId,
      ]
    );

    if (!result.rows.length) return res.status(404).json({ error: "Lesson not found" });
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to update lesson" });
  }
});

/**
 * DELETE /admin/internships/lessons/:lessonId
 */
router.delete("/lessons/:lessonId", async (req, res) => {
  try {
    await pool.query(`DELETE FROM internship_lessons WHERE id = $1`, [req.params.lessonId]);
    res.json({ success: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to delete lesson" });
  }
});

/**
 * GET /admin/internships/:id/students
 */
router.get("/:id/students", async (req, res) => {
  try {
    const result = await pool.query(
      `
      SELECT
        e.id AS enrollment_id, e.student_id, e.enrolled_at,
        COUNT(DISTINCT l.id)::int AS total_lessons,
        COUNT(DISTINCT CASE WHEN lp.student_id IS NOT NULL THEN l.id END)::int AS completed_lessons
      FROM internship_enrollments e
      LEFT JOIN internship_modules m ON m.internship_id = e.internship_id
      LEFT JOIN internship_lessons l ON l.module_id = m.id
      LEFT JOIN internship_lesson_progress lp ON lp.lesson_id = l.id AND lp.student_id = e.student_id
      WHERE e.internship_id = $1
      GROUP BY e.id, e.student_id, e.enrolled_at
      ORDER BY e.enrolled_at DESC
      `,
      [req.params.id]
    );

    const students = result.rows.map((s) => ({
      ...s,
      progressPercentage: s.total_lessons > 0 ? Math.round((s.completed_lessons / s.total_lessons) * 100) : 0,
    }));

    res.json(students);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to load students" });
  }
});

/**
 * DELETE /admin/internships/:id
 */
router.delete("/:id", async (req, res) => {
  try {
    const result = await pool.query(`DELETE FROM internships WHERE id = $1 RETURNING id`, [req.params.id]);
    if (!result.rows.length) return res.status(404).json({ error: "Course not found" });
    res.json({ success: true, id: req.params.id });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to delete course" });
  }
});

module.exports = router;
