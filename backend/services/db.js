const { Pool } = require("pg");

const rawUrl = process.env.DATABASE_URL || "";
const isRemote = rawUrl.length > 0 && !rawUrl.includes("localhost") && !rawUrl.includes("127.0.0.1");

let pool = null;

if (isRemote) {
  pool = new Pool({
    connectionString: rawUrl,
    ssl: { rejectUnauthorized: false },
    connectionTimeoutMillis: 5000,
  });

  pool.on("error", (err) => {
    console.warn("PostgreSQL Pool Warning:", err.message);
  });
} else if (process.env.NODE_ENV !== "production") {
  pool = new Pool({
    connectionString: rawUrl || "postgresql://postgres:postgres@localhost:5432/myvault_scaffold?schema=public",
    ssl: false,
    connectionTimeoutMillis: 3000,
  });

  pool.on("error", (err) => {
    console.warn("Local PostgreSQL Warning:", err.message);
  });
} else {
  // Production environment without remote DATABASE_URL configured yet
  pool = {
    query: async () => ({ rows: [] }),
    on: () => {},
  };
  console.info("Info: Remote DATABASE_URL not provided; running in memory/mock database mode.");
}

module.exports = { pool, isRemote };
