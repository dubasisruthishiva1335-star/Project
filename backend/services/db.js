const { Pool } = require("pg");

const rawUrl = process.env.DATABASE_URL || "";
const isRemote = rawUrl.length > 0 && !rawUrl.includes("localhost") && !rawUrl.includes("127.0.0.1");

let pool = null;

const memoryStore = {
  academic_materials: [],
  job_listings: [],
  internships: [],
  competitive_exams: [],
  exam_results: [],
  students: [],
  course_enrollments: [],
  internship_certificates: [],
};

if (isRemote) {
  pool = new Pool({
    connectionString: rawUrl,
    ssl: { rejectUnauthorized: false },
    connectionTimeoutMillis: 5000,
  });

  pool.on("error", (err) => {
    console.warn("PostgreSQL Pool Warning:", err.message);
  });
} else {
  // In-Memory resilient store for development and standalone hosting
  pool = {
    async query(sql, params = []) {
      const s = String(sql).trim();

      // Handle DDL
      if (s.toUpperCase().startsWith("CREATE TABLE") || s.toUpperCase().startsWith("ALTER TABLE")) {
        return { rows: [], rowCount: 0 };
      }

      // Handle competitive_exams
      if (s.includes("competitive_exams")) {
        if (s.toUpperCase().startsWith("INSERT")) {
          // params: [id, exam_id, exam_name, category, title, subject, unit, content_type, year, difficulty, file_url, s3_key, file_size, description, author, syllabus_url, exam_date, is_featured]
          const id = params[0] || `exam_${Date.now()}`;
          const record = {
            id,
            exam_id: params[1] || "gate-cs-2026",
            exam_name: params[2] || "GATE Computer Science & IT",
            category: params[3] || "ENGINEERING",
            title: params[4] || "Exam Preparation Material",
            subject: params[5] || "General",
            unit: params[6] || "1",
            content_type: params[7] || "NOTES",
            year: Number(params[8]) || 2026,
            difficulty: params[9] || "ALL_LEVELS",
            file_url: params[10] || "",
            s3_key: params[11] || "",
            file_size: params[12] || "2.5 MB",
            description: params[13] || "",
            author: params[14] || "MyVault Academic Team",
            syllabus_url: params[15] || "",
            exam_date: params[16] || "",
            is_featured: Boolean(params[17]),
            downloads_count: 0,
            uploaded_at: new Date().toISOString(),
          };

          const existingIdx = memoryStore.competitive_exams.findIndex((e) => e.id === id);
          if (existingIdx >= 0) {
            memoryStore.competitive_exams[existingIdx] = { ...memoryStore.competitive_exams[existingIdx], ...record };
          } else {
            memoryStore.competitive_exams.unshift(record);
          }
          return { rows: [record], rowCount: 1 };
        }

        if (s.toUpperCase().startsWith("SELECT")) {
          let rows = [...memoryStore.competitive_exams];
          if (s.includes("WHERE id = $1") && params.length > 0) {
            rows = rows.filter((r) => r.id === params[0]);
          } else if (s.includes("category") && params.length > 0) {
            // filter if needed
          }
          return { rows, rowCount: rows.length };
        }

        if (s.toUpperCase().startsWith("DELETE")) {
          if (params.length > 0) {
            memoryStore.competitive_exams = memoryStore.competitive_exams.filter((r) => r.id !== params[0]);
          }
          return { rows: [], rowCount: 1 };
        }
      }

      // Handle academic_materials
      if (s.includes("academic_materials")) {
        if (s.toUpperCase().startsWith("INSERT")) {
          const id = params[0] || `mat_${Date.now()}`;
          const existingIdx = memoryStore.academic_materials.findIndex((m) => m.id === id);
          const record = {
            id,
            title: params[1] || "Uploaded Material",
            branch: params[2] || "GENERAL",
            semester: Number(params[3]) || 1,
            unit: Number(params[4]) || 1,
            content_type: params[5] || "NOTES",
            file_url: params[6] || "",
            s3_key: params[7] || "",
            uploaded_at: new Date().toISOString(),
          };

          if (existingIdx >= 0) {
            memoryStore.academic_materials[existingIdx] = record;
          } else {
            memoryStore.academic_materials.unshift(record);
          }
          return { rows: [record], rowCount: 1 };
        }

        if (s.toUpperCase().startsWith("SELECT")) {
          let rows = [...memoryStore.academic_materials];
          if (s.includes("WHERE id = $1") && params.length > 0) {
            rows = rows.filter((r) => r.id === params[0]);
          }
          return { rows, rowCount: rows.length };
        }

        if (s.toUpperCase().startsWith("DELETE")) {
          if (params.length > 0) {
            memoryStore.academic_materials = memoryStore.academic_materials.filter((r) => r.id !== params[0]);
          }
          return { rows: [], rowCount: 1 };
        }
      }

      // Handle internships / placements / jobs / courses
      if (s.includes("internships")) {
        if (s.toUpperCase().startsWith("INSERT")) {
          const id = params[0] || `job_${Date.now()}`;
          const record = {
            id,
            title: params[1] || "",
            company: params[2] || "",
            type: params[3] || "PLACEMENT",
            branch: params[6] || "All Branches",
            stipend: params[7] || "",
            location: params[8] || "",
            deadline: params[9] || null,
            description: params[10] || "",
            apply_url: params[11] || "",
            file_url: params[12] || "",
            s3_key: params[13] || "",
            duration: params[14] || "",
            max_students: params[15] || 5,
            work_mode: params[16] || "HYBRID",
            category: params[17] || "Software Development",
            responsibilities: params[18] || "",
            requirements: params[19] || "",
            skills: params[20] || "",
            min_cgpa: params[21] || 6.5,
            perks: params[22] || "",
            contact_phone: params[23] || "",
            contact_email: params[24] || "",
            company_website: params[25] || "",
            posted_at: new Date().toISOString(),
          };
          const existingIdx = memoryStore.internships.findIndex((j) => j.id === id);
          if (existingIdx >= 0) memoryStore.internships[existingIdx] = record;
          else memoryStore.internships.unshift(record);
          return { rows: [record], rowCount: 1 };
        }
        if (s.toUpperCase().startsWith("SELECT")) {
          let rows = [...memoryStore.internships];
          if (s.includes("WHERE id = $1") && params.length > 0) {
            rows = rows.filter((r) => r.id === params[0]);
          }
          return { rows, rowCount: rows.length };
        }
        if (s.toUpperCase().startsWith("DELETE")) {
          if (params.length > 0) {
            memoryStore.internships = memoryStore.internships.filter((r) => r.id !== params[0]);
          }
          return { rows: [], rowCount: 1 };
        }
      }

      // Fallback
      return { rows: [], rowCount: 0 };
    },
    on() {},
  };
  console.info("Info: Using active resilient database store.");
}

module.exports = { pool, isRemote, memoryStore };
