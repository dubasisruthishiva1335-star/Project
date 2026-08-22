const express = require('express');
const router = express.Router();
const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://postgres:postgres@localhost:5432/myvault',
  ssl: process.env.DATABASE_URL ? { rejectUnauthorized: false } : false,
});

// GET /internships — List all listings (supports filter by type and is_lms_enabled)
router.get('/', async (req, res) => {
  const { type, isLmsEnabled, branch } = req.query;
  try {
    let query = 'SELECT * FROM internships WHERE 1=1';
    const params = [];

    if (type) {
      params.push(String(type).toUpperCase());
      query += ` AND UPPER(type) = $${params.length}`;
    }
    if (isLmsEnabled !== undefined) {
      params.push(isLmsEnabled === 'true' || isLmsEnabled === '1');
      query += ` AND is_lms_enabled = $${params.length}`;
    }
    if (branch && branch !== 'ALL' && branch !== 'All Branches') {
      params.push(branch);
      query += ` AND (branch = $${params.length} OR branch = 'All Branches')`;
    }

    query += ' ORDER BY posted_at DESC';
    const dbRes = await pool.query(query, params);

    const items = dbRes.rows.map((j) => ({
      id: j.id,
      title: j.title,
      company: j.company,
      type: j.type,
      isLmsEnabled: Boolean(j.is_lms_enabled),
      branch: j.branch,
      stipend: j.stipend,
      location: j.location,
      deadline: j.deadline,
      description: j.description,
      applyUrl: j.apply_url,
      fileUrl: j.file_url,
      s3Key: j.s3_key,
      postedAt: j.posted_at,
    }));

    res.json(items);
  } catch (err) {
    res.json([]);
  }
});

// GET /internships/:id — Get full detail (with modules, lessons, and enrollment state)
router.get('/:id', async (req, res) => {
  const { id } = req.params;
  const studentId = req.query.studentId || 'student_demo';

  try {
    const itemRes = await pool.query('SELECT * FROM internships WHERE id = $1', [id]);
    if (itemRes.rows.length === 0) {
      return res.status(404).json({ error: 'Opportunity not found' });
    }
    const j = itemRes.rows[0];

    const detail = {
      id: j.id,
      title: j.title,
      company: j.company,
      type: j.type,
      isLmsEnabled: Boolean(j.is_lms_enabled),
      branch: j.branch,
      stipend: j.stipend,
      location: j.location,
      deadline: j.deadline,
      description: j.description,
      applyUrl: j.apply_url,
      fileUrl: j.file_url,
      s3Key: j.s3_key,
      postedAt: j.posted_at,
      isEnrolled: false,
      progressPercentage: 0,
      modules: [],
      certificateUrl: null,
    };

    if (detail.isLmsEnabled) {
      // Check enrollment
      const enrollRes = await pool.query(
        'SELECT * FROM internship_enrollments WHERE internship_id = $1 AND student_id = $2',
        [id, studentId]
      );
      detail.isEnrolled = enrollRes.rows.length > 0;

      // Check certificate
      const certRes = await pool.query(
        'SELECT certificate_url FROM internship_certificates WHERE internship_id = $1 AND student_id = $2',
        [id, studentId]
      );
      if (certRes.rows.length > 0) {
        detail.certificateUrl = certRes.rows[0].certificate_url;
      }

      // Fetch modules & lessons
      const modulesRes = await pool.query(
        'SELECT * FROM internship_modules WHERE internship_id = $1 ORDER BY sort_order ASC',
        [id]
      );
      const modules = modulesRes.rows;

      let totalLessons = 0;
      let completedLessonsCount = 0;

      for (const m of modules) {
        const lessonsRes = await pool.query(
          `SELECT l.*, 
                  (SELECT COUNT(*) FROM internship_lesson_progress lp WHERE lp.lesson_id = l.id AND lp.student_id = $1) > 0 AS is_completed
           FROM internship_lessons l 
           WHERE l.module_id = $2 
           ORDER BY l.sort_order ASC`,
          [studentId, m.id]
        );

        const lessons = lessonsRes.rows.map((l) => {
          totalLessons++;
          if (l.is_completed) completedLessonsCount++;
          return {
            id: l.id,
            title: l.title,
            contentType: l.content_type,
            videoUrl: l.video_url,
            pdfUrl: l.pdf_url,
            description: l.description,
            duration: l.duration,
            isCompleted: Boolean(l.is_completed),
          };
        });

        detail.modules.push({
          id: m.id,
          title: m.title,
          sortOrder: m.sort_order,
          lessons,
        });
      }

      detail.progressPercentage =
        totalLessons > 0 ? Math.round((completedLessonsCount / totalLessons) * 100) : 0;
    }

    res.json(detail);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /internships/:id/enroll — Student Enroll
router.post('/:id/enroll', async (req, res) => {
  const { id } = req.params;
  const { studentId = 'student_demo' } = req.body;

  try {
    const enrollId = `enroll_${Date.now()}_${Math.floor(Math.random() * 1000)}`;
    await pool.query(
      `INSERT INTO internship_enrollments (id, internship_id, student_id, enrolled_at)
       VALUES ($1, $2, $3, NOW())
       ON CONFLICT (internship_id, student_id) DO NOTHING`,
      [enrollId, id, studentId]
    );
    res.json({ success: true, enrolled: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /internships/lessons/:lessonId/complete — Complete Lesson & Auto-issue Certificate
router.post('/lessons/:lessonId/complete', async (req, res) => {
  const { lessonId } = req.params;
  const { studentId = 'student_demo', internshipId } = req.body;

  try {
    const progressId = `prog_${Date.now()}_${Math.floor(Math.random() * 1000)}`;
    await pool.query(
      `INSERT INTO internship_lesson_progress (id, lesson_id, student_id, completed_at)
       VALUES ($1, $2, $3, NOW())
       ON CONFLICT (lesson_id, student_id) DO NOTHING`,
      [progressId, lessonId, studentId]
    );

    // Check if all lessons are completed for this course
    let certificateIssued = false;
    let certUrl = null;

    if (internshipId) {
      const allLessonsRes = await pool.query(
        `SELECT l.id FROM internship_lessons l 
         JOIN internship_modules m ON l.module_id = m.id 
         WHERE m.internship_id = $1`,
        [internshipId]
      );
      const totalCount = allLessonsRes.rows.length;

      const completedRes = await pool.query(
        `SELECT COUNT(*) FROM internship_lesson_progress lp
         JOIN internship_lessons l ON lp.lesson_id = l.id
         JOIN internship_modules m ON l.module_id = m.id
         WHERE m.internship_id = $1 AND lp.student_id = $2`,
        [internshipId, studentId]
      );
      const completedCount = parseInt(completedRes.rows[0].count, 10);

      if (totalCount > 0 && completedCount >= totalCount) {
        // Issue Certificate
        const certId = `cert_${Date.now()}_${Math.floor(Math.random() * 1000)}`;
        certUrl = `https://myvault-files-app.s3.eu-north-1.amazonaws.com/certificates/${certId}.pdf`;
        await pool.query(
          `INSERT INTO internship_certificates (id, internship_id, student_id, certificate_url, issued_at)
           VALUES ($1, $2, $3, $4, NOW())
           ON CONFLICT (internship_id, student_id) DO NOTHING`,
          [certId, internshipId, studentId, certUrl]
        );
        certificateIssued = true;
      }
    }

    res.json({ success: true, completed: true, certificateIssued, certUrl });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
