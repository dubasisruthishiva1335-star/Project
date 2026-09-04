const express = require("express");
const { pool } = require("../services/db");

const router = express.Router();

// Standard Engineering Subjects Catalog by Branch
const BRANCH_SUBJECTS = {
  CSE: [
    "Data Structures & Algorithms",
    "Database Management Systems (DBMS)",
    "Operating Systems & Linux",
    "Computer Networks (CN)",
    "Theory of Computation & Automata",
  ],
  ECE: [
    "Electronic Devices & Circuits (EDC)",
    "Signals & Systems (SS)",
    "Digital Logic Design (DLD)",
    "Linear Integrated Circuits (LIC)",
    "Analog & Digital Communications",
  ],
  AI_ML: [
    "Machine Learning Fundamentals",
    "Deep Learning & Neural Networks",
    "Natural Language Processing (NLP)",
    "Computer Vision & Pattern Recognition",
    "Python for Artificial Intelligence",
  ],
  EEE: [
    "Circuit Theory & Analysis",
    "Electrical Machines (AC & DC)",
    "Power Systems & Transmission",
    "Control Systems Engineering",
    "Power Electronics & Drives",
  ],
  MECH: [
    "Engineering Thermodynamics",
    "Fluid Mechanics & Hydraulics",
    "Strength of Materials (SOM)",
    "Manufacturing Technology & CAM",
    "Kinematics & Theory of Machines",
  ],
  CIVIL: [
    "Surveying & Geomatics",
    "Structural Analysis & Mechanics",
    "Building Materials & Construction",
    "Geotechnical & Soil Engineering",
    "Hydrology & Water Resources",
  ],
  GENERAL: [
    "Engineering Mathematics (M-1 & M-2)",
    "Engineering Physics & Semiconductor Physics",
    "Engineering Chemistry & Environmental Science",
    "Basic Electrical & Electronics (BEEE)",
    "Programming for Problem Solving (C / Python)",
  ],
};

function getDefaultSubjects(branch, semester) {
  const normBranch = (branch || "CSE").toUpperCase();
  const subNames = BRANCH_SUBJECTS[normBranch] || BRANCH_SUBJECTS["CSE"];

  return subNames.map((name, index) => ({
    id: `default_${normBranch}_${semester}_${index + 1}`,
    name,
    code: `${normBranch}-${100 * (Number(semester) || 1) + index + 1}`,
    branch: normBranch,
    semester: Number(semester) || 1,
    contents: [1, 2, 3, 4, 5].map((u) => ({
      id: `content_${normBranch}_${semester}_${index + 1}_u${u}`,
      title: `${name} — Unit ${u} Lecture Notes & PYQs`,
      contentType: u % 2 === 0 ? "VIDEO_LECTURE" : "NOTES",
      unit: u,
      fileUrl: "https://myvault-files-app.s3.eu-north-1.amazonaws.com/app-arm64-v8a-release.apk",
      s3Key: `academic/${normBranch.toLowerCase()}/sem${semester}/unit${u}.pdf`,
      uploadedAt: new Date().toISOString(),
    })),
  }));
}

/**
 * GET /notes (and /academic/content and /subjects)
 * Query parameters: branch, semester, unit, contentType
 */
router.get("/", async (req, res) => {
  const { branch = "ECE", semester = 1, unit, contentType } = req.query;

  try {
    let query = `SELECT * FROM academic_materials WHERE 1=1`;
    const params = [];

    if (branch && branch !== "ALL" && branch !== "General") {
      params.push(branch);
      query += ` AND (branch = $${params.length} OR branch = 'GENERAL')`;
    }

    if (semester) {
      params.push(Number(semester));
      query += ` AND semester = $${params.length}`;
    }

    if (unit) {
      params.push(Number(unit));
      query += ` AND unit = $${params.length}`;
    }

    if (contentType) {
      params.push(String(contentType).toUpperCase());
      query += ` AND UPPER(content_type) = $${params.length}`;
    }

    query += ` ORDER BY uploaded_at DESC`;

    const result = await pool.query(query, params);

    // Group materials by subject
    const groupedMap = new Map();

    (result.rows || []).forEach((row) => {
      const subjectName = row.title.split('—')[0].split('-')[0].trim() || "Academic Resources";
      const groupKey = `${row.branch}_${row.semester}_${subjectName}`;

      if (!groupedMap.has(groupKey)) {
        groupedMap.set(groupKey, {
          id: `subj_${row.id}`,
          name: subjectName,
          code: row.branch,
          branch: row.branch,
          semester: row.semester,
          contents: [],
        });
      }

      groupedMap.get(groupKey).contents.push({
        id: row.id,
        title: row.title,
        contentType: row.content_type,
        unit: row.unit,
        fileUrl: row.file_url,
        s3Key: row.s3_key,
        uploadedAt: row.uploaded_at,
      });
    });

    let outputList = Array.from(groupedMap.values());

    // If no custom uploaded subjects found for this branch/sem, fallback to standard catalog
    if (outputList.length === 0) {
      outputList = getDefaultSubjects(branch, semester);
    }

    res.json(outputList);
  } catch (err) {
    console.error("Notes fetch error, serving default catalog:", err.message);
    res.json(getDefaultSubjects(branch, semester));
  }
});

module.exports = router;
