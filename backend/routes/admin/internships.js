const express = require('express');
const router = express.Router();
const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://postgres:postgres@localhost:5432/myvault',
  ssl: process.env.DATABASE_URL ? { rejectUnauthorized: false } : false,
});

// POST /admin/internships/confirm — Create/Edit listing (supports is_lms_enabled)
router.post('/confirm', async (req, res) => {
  const {
    id,
    title,
    company,
    type = 'INTERNSHIP',
    isLmsEnabled = false,
    branch = 'All Branches',
    stipend,
    location,
    deadline,
    description,
    applyUrl,
    fileUrl,
    s3Key,
    publicUrl,
  } = req.body;

  const item = {
    id: id || `job_${Date.now()}_${Math.floor(Math.random() * 1000)}`,
    title: title || 'New Opportunity',
    company: company || 'Organization',
    type,
    isLmsEnabled: Boolean(isLmsEnabled),
    branch: branch || 'All Branches',
    stipend: stipend || null,
    location: location || null,
    deadline: deadline || null,
    description: description || null,
    applyUrl: applyUrl || 'https://myvault-project.vercel.app',
    fileUrl: publicUrl || fileUrl || (s3Key ? `https://myvault-files-app.s3.eu-north-1.amazonaws.com/${s3Key}` : null),
    s3Key: s3Key || null,
    postedAt: new Date().toISOString(),
  };

  try {
    await pool.query(
      `INSERT INTO internships (id, title, company, type, is_lms_enabled, branch, stipend, location, deadline, description, apply_url, file_url, s3_key, posted_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, NOW())
       ON CONFLICT (id) DO UPDATE SET
         title = EXCLUDED.title,
         company = EXCLUDED.company,
         type = EXCLUDED.type,
         is_lms_enabled = EXCLUDED.is_lms_enabled,
         branch = EXCLUDED.branch,
         stipend = EXCLUDED.stipend,
         location = EXCLUDED.location,
         deadline = EXCLUDED.deadline,
         description = EXCLUDED.description,
         apply_url = EXCLUDED.apply_url,
         file_url = EXCLUDED.file_url,
         s3_key = EXCLUDED.s3_key`,
      [
        item.id,
        item.title,
        item.company,
        item.type,
        item.isLmsEnabled,
        item.branch,
        item.stipend,
        item.location,
        item.deadline,
        item.description,
        item.applyUrl,
        item.fileUrl,
        item.s3Key,
      ]
    );
  } catch (err) {
    console.error('Admin Confirm Insert Error:', err.message);
  }

  res.status(201).json(item);
});

// POST /admin/internships/:id/modules — Add Course Module
router.post('/:id/modules', async (req, res) => {
  const { id } = req.params;
  const { title, sortOrder = 1 } = req.body;

  try {
    const moduleId = `mod_${Date.now()}_${Math.floor(Math.random() * 1000)}`;
    await pool.query(
      `INSERT INTO internship_modules (id, internship_id, title, sort_order, created_at)
       VALUES ($1, $2, $3, $4, NOW())`,
      [moduleId, id, title || 'New Module', sortOrder]
    );
    res.status(201).json({ id: moduleId, internshipId: id, title, sortOrder });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /admin/internships/modules/:moduleId/lessons — Add Lesson
router.post('/modules/:moduleId/lessons', async (req, res) => {
  const { moduleId } = req.params;
  const {
    title,
    contentType = 'VIDEO',
    videoUrl,
    pdfUrl,
    description,
    duration = '15 mins',
    sortOrder = 1,
  } = req.body;

  try {
    const lessonId = `les_${Date.now()}_${Math.floor(Math.random() * 1000)}`;
    await pool.query(
      `INSERT INTO internship_lessons (id, module_id, title, content_type, video_url, pdf_url, description, duration, sort_order, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW())`,
      [lessonId, moduleId, title || 'New Lesson', contentType, videoUrl || null, pdfUrl || null, description || null, duration, sortOrder]
    );
    res.status(201).json({ id: lessonId, moduleId, title, contentType, videoUrl, pdfUrl, description, duration, sortOrder });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE /admin/internships/:id — Delete Listing
router.delete('/:id', async (req, res) => {
  const { id } = req.params;
  try {
    await pool.query('DELETE FROM internships WHERE id = $1', [id]);
    res.json({ success: true, id });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
