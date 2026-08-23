const jwt = require("jsonwebtoken");

const JWT_SECRET = process.env.JWT_SECRET;

if (!JWT_SECRET) {
  // Fail loudly at startup rather than silently accepting unsigned/forged tokens.
  console.error(
    "FATAL: JWT_SECRET is not set. Set it in your environment before starting the server."
  );
}

/**
 * Protects admin-only routes.
 * Expects: Authorization: Bearer <token>
 * Token payload should contain { id, email, role }.
 */
function adminAuth(req, res, next) {
  const header = req.headers.authorization || "";
  const [scheme, token] = header.split(" ");

  if (scheme !== "Bearer" || !token) {
    return res.status(401).json({
      error: "Missing or malformed Authorization header",
    });
  }

  try {
    const payload = jwt.verify(token, JWT_SECRET);

    if (payload.role !== "ADMIN" && payload.role !== "MENTOR") {
      return res.status(403).json({
        error: "Admin or mentor role required",
      });
    }

    req.admin = payload;
    next();
  } catch (err) {
    return res.status(401).json({
      error: "Invalid or expired token",
    });
  }
}

/**
 * Protects student routes and attaches the authenticated student's id
 * from the token — never trust studentId from req.body/req.query alone.
 * Expects: Authorization: Bearer <token>
 * Token payload should contain { id } for the student.
 */
function studentAuth(req, res, next) {
  const header = req.headers.authorization || "";
  const [scheme, token] = header.split(" ");

  if (scheme !== "Bearer" || !token) {
    return res.status(401).json({
      error: "Missing or malformed Authorization header",
    });
  }

  try {
    const payload = jwt.verify(token, JWT_SECRET);
    req.student = payload;
    next();
  } catch (err) {
    return res.status(401).json({
      error: "Invalid or expired token",
    });
  }
}

module.exports = { adminAuth, studentAuth };
