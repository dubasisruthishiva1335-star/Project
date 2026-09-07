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
      ALTER TABLE internships ADD COLUMN IF NOT EXISTS work_mode VARCHAR(64) DEFAULT 'HYBRID';
      ALTER TABLE internships ADD COLUMN IF NOT EXISTS category VARCHAR(100) DEFAULT 'Software Development';
      ALTER TABLE internships ADD COLUMN IF NOT EXISTS responsibilities TEXT;
      ALTER TABLE internships ADD COLUMN IF NOT EXISTS requirements TEXT;
      ALTER TABLE internships ADD COLUMN IF NOT EXISTS skills TEXT;
      ALTER TABLE internships ADD COLUMN IF NOT EXISTS min_cgpa NUMERIC(4,2) DEFAULT 6.5;
      ALTER TABLE internships ADD COLUMN IF NOT EXISTS perks TEXT;
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

    const formatted = result.rows.map((row) => {
      let respList = [];
      try {
        respList = row.responsibilities ? (row.responsibilities.startsWith('[') ? JSON.parse(row.responsibilities) : row.responsibilities.split('\n')) : [];
      } catch (_) {
        respList = row.responsibilities ? row.responsibilities.split('\n') : [];
      }

      let reqList = [];
      try {
        reqList = row.requirements ? (row.requirements.startsWith('[') ? JSON.parse(row.requirements) : row.requirements.split('\n')) : [];
      } catch (_) {
        reqList = row.requirements ? row.requirements.split('\n') : [];
      }

      let skillList = [];
      try {
        skillList = row.skills ? (row.skills.startsWith('[') ? JSON.parse(row.skills) : row.skills.split(',')) : [];
      } catch (_) {
        skillList = row.skills ? row.skills.split(',') : [];
      }

      let branchList = ['ALL', 'CSE', 'IT', 'ECE', 'EEE', 'MECH', 'CIVIL'];
      if (row.branch && row.branch !== 'All Branches') {
        branchList = row.branch.split(/[,/]/).map(b => b.trim());
      }

      return {
        ...row,
        workMode: row.work_mode || (row.location && row.location.toLowerCase().includes('remote') ? 'REMOTE' : 'HYBRID'),
        category: row.category || 'Software Development',
        openings: row.max_students || 5,
        eligibleBranches: branchList,
        minCgpa: row.min_cgpa ? Number(row.min_cgpa) : 6.5,
        responsibilities: respList.length > 0 ? respList : [
          'Design and implement core modules and frontend/backend components.',
          'Collaborate directly with senior engineering mentors.',
          'Participate in agile sprints, code reviews, and testing.'
        ],
        requirements: reqList.length > 0 ? reqList : [
          'Enrolled in B.Tech/B.E. in Engineering or related fields.',
          'Solid fundamentals in software engineering and problem-solving.',
          'Good team collaboration and communication skills.'
        ],
        skills: skillList.length > 0 ? skillList.map(s => String(s).trim()) : ['Full Stack', 'Web Development', 'Problem Solving'],
        perks: row.perks ? (row.perks.startsWith('[') ? JSON.parse(row.perks) : row.perks.split(',')) : ['PPO Conversion Opportunity', '1:1 Mentorship', 'Experience Certificate'],
        applicantCount: row.enrollment_count || 0,
      };
    });

    res.json(formatted);
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
    workMode = "HYBRID",
    category = "Software Development",
    responsibilities,
    requirements,
    skills,
    minCgpa = 6.5,
    perks,
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
      ALTER TABLE internships ADD COLUMN IF NOT EXISTS work_mode VARCHAR(64) DEFAULT 'HYBRID';
      ALTER TABLE internships ADD COLUMN IF NOT EXISTS category VARCHAR(100) DEFAULT 'Software Development';
      ALTER TABLE internships ADD COLUMN IF NOT EXISTS responsibilities TEXT;
      ALTER TABLE internships ADD COLUMN IF NOT EXISTS requirements TEXT;
      ALTER TABLE internships ADD COLUMN IF NOT EXISTS skills TEXT;
      ALTER TABLE internships ADD COLUMN IF NOT EXISTS min_cgpa NUMERIC(4,2) DEFAULT 6.5;
      ALTER TABLE internships ADD COLUMN IF NOT EXISTS perks TEXT;
    `);

    const respStr = Array.isArray(responsibilities) ? JSON.stringify(responsibilities) : (responsibilities ? String(responsibilities) : null);
    const reqStr = Array.isArray(requirements) ? JSON.stringify(requirements) : (requirements ? String(requirements) : null);
    const skillStr = Array.isArray(skills) ? JSON.stringify(skills) : (skills ? String(skills) : null);
    const perksStr = Array.isArray(perks) ? JSON.stringify(perks) : (perks ? String(perks) : null);
    const branchStr = Array.isArray(branch) ? branch.join(', ') : String(branch || 'All Branches');

    await pool.query(
      `
      INSERT INTO internships (
        id, title, company, type, is_lms_enabled, certificate_enabled,
        branch, stipend, location, deadline, description, apply_url,
        file_url, s3_key, duration, max_students, status, work_mode,
        category, responsibilities, requirements, skills, min_cgpa, perks, posted_at
      )
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,'PUBLISHED',$17,$18,$19,$20,$21,$22,$23,NOW())
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
        work_mode = EXCLUDED.work_mode,
        category = EXCLUDED.category,
        responsibilities = EXCLUDED.responsibilities,
        requirements = EXCLUDED.requirements,
        skills = EXCLUDED.skills,
        min_cgpa = EXCLUDED.min_cgpa,
        perks = EXCLUDED.perks,
        status = 'PUBLISHED'
      `,
      [
        courseId,
        title || "New Internship Opportunity",
        company || "Organization",
        type || "INTERNSHIP",
        Boolean(isLmsEnabled === true || isLmsEnabled === "true"),
        Boolean(certificateEnabled === true || certificateEnabled === "true"),
        branchStr,
        stipend || null,
        location || null,
        finalDeadline,
        description || null,
        applyUrl || null,
        publicUrl || fileUrl || null,
        s3Key || null,
        duration || null,
        maxStudents ? Number(maxStudents) : null,
        workMode || "HYBRID",
        category || "Software Development",
        respStr,
        reqStr,
        skillStr,
        minCgpa ? Number(minCgpa) : 6.5,
        perksStr,
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
