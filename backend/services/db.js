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

      // Handle CREATE TABLE
      if (s.toUpperCase().startsWith("CREATE TABLE")) {
        return { rows: [], rowCount: 0 };
      }

      // Handle academic_materials
      if (s.includes("academic_materials")) {
        if (s.toUpperCase().startsWith("INSERT")) {
          // params: [id, title, branch, semester, unit, content_type, file_url, s3_key]
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
          // Check if selecting specific id
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

      // Handle internships / placements / jobs
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
            posted_at: new Date().toISOString(),
          };
          const existingIdx = memoryStore.internships.findIndex((j) => j.id === id);
          if (existingIdx >= 0) memoryStore.internships[existingIdx] = record;
          else memoryStore.internships.unshift(record);
          return { rows: [record], rowCount: 1 };
        }
        if (s.toUpperCase().startsWith("SELECT")) {
          return { rows: [...memoryStore.internships], rowCount: memoryStore.internships.length };
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
