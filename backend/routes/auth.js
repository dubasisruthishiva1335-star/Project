const express = require("express");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const crypto = require("crypto");
const { pool } = require("../services/db");

const router = express.Router();

const JWT_SECRET = process.env.JWT_SECRET;
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || "7d";

/**
 * POST /auth/admin/login
 * body: { email, password }
 */
router.post("/admin/login", async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: "email and password are required" });
    }

    const result = await pool.query(`SELECT * FROM admin_users WHERE email = $1`, [
      email.toLowerCase().trim(),
    ]);

    if (!result.rows.length) {
      return res.status(401).json({ error: "Invalid credentials" });
    }

    const admin = result.rows[0];
    const valid = await bcrypt.compare(password, admin.password_hash);

    if (!valid) {
      return res.status(401).json({ error: "Invalid credentials" });
    }

    const token = jwt.sign(
      { id: admin.id, email: admin.email, role: admin.role, name: admin.name },
      JWT_SECRET,
      { expiresIn: JWT_EXPIRES_IN }
    );

    res.json({
      token,
      admin: { id: admin.id, email: admin.email, name: admin.name, role: admin.role },
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Login failed" });
  }
});

/**
 * POST /auth/admin/register
 * Should be locked down in production.
 */
router.post("/admin/register", async (req, res) => {
  try {
    const { email, password, name } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: "email and password are required" });
    }

    const passwordHash = await bcrypt.hash(password, 12);
    const id = `admin_${Date.now()}_${crypto.randomBytes(5).toString("hex")}`;

    await pool.query(
      `INSERT INTO admin_users (id, email, password_hash, name, role, created_at) VALUES ($1,$2,$3,$4,'ADMIN',NOW())`,
      [id, email.toLowerCase().trim(), passwordHash, name || null]
    );

    res.status(201).json({ success: true, id });
  } catch (err) {
    if (err.code === "23505") {
      return res.status(409).json({ error: "An admin with this email already exists" });
    }
    console.error(err);
    res.status(500).json({ error: "Registration failed" });
  }
});

/**
 * POST /auth/student/verify-firebase
 * Firebase auth verification stub.
 */
router.post("/student/verify-firebase", async (req, res) => {
  try {
    const { firebaseIdToken } = req.body;
    if (!firebaseIdToken) {
      return res.status(400).json({ error: "firebaseIdToken is required" });
    }

    return res.status(501).json({
      error: "Firebase verification not yet wired up. See comment in routes/auth.js.",
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Login failed" });
  }
});

module.exports = router;
