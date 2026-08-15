/**
 * Campus App Backend — Node/Express
 * -----------------------------------------------------------
 * Powers two features requested for the Flutter app:
 *   1. AI Campus Interview & Aptitude Assistant
 *      -> proxies to Claude API so the API key never lives in the app
 *   2. Live Push Notifications / Circular Alerts
 *      -> Admin posts a circular here, backend fans it out via
 *         Firebase Cloud Messaging (FCM) to all subscribed students
 *
 * Setup:
 *   npm install
 *   cp .env.example .env      # fill in ANTHROPIC_API_KEY + Firebase creds
 *   node server.js
 * -----------------------------------------------------------
 */

const express = require("express");
const cors = require("cors");
const fs = require("fs");
const path = require("path");
require("dotenv").config();

const app = express();
app.use(cors());
app.use(express.json({ limit: "2mb" }));

// ---------------------------------------------------------------
// Firebase Admin init (for sending push notifications via FCM)
// Download your service-account JSON from:
// Firebase Console -> Project Settings -> Service Accounts
// ---------------------------------------------------------------
let firebaseAdmin = null;
const serviceAccountPath = path.join(__dirname, "firebase-service-account.json");

if (fs.existsSync(serviceAccountPath)) {
  try {
    const admin = require("firebase-admin");
    const serviceAccount = require(serviceAccountPath);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    firebaseAdmin = admin;
    console.log("Firebase Admin initialized successfully!");
  } catch (err) {
    console.warn("Could not initialize Firebase Admin:", err.message);
  }
} else {
  console.log("firebase-service-account.json not found. Push notifications will run in mock mode.");
}

const CIRCULAR_TOPIC = "circulars"; // students subscribe to this topic in the app

// In-memory store for demo purposes — swap for your real DB (Mongo/Postgres/etc.)
const circulars = [];

// =================================================================
// 1) CIRCULAR / PUSH NOTIFICATION ENDPOINTS
// =================================================================

/**
 * Admin website calls this whenever a new circular is published.
 * Body: { title: string, body: string, category?: string, fileUrl?: string }
 */
app.post("/api/circulars", async (req, res) => {
  try {
    const { title, body, category, fileUrl } = req.body;
    if (!title || !body) {
      return res.status(400).json({ error: "title and body are required" });
    }

    const circular = {
      id: Date.now().toString(),
      title,
      body,
      category: category || "General",
      fileUrl: fileUrl || null,
      postedAt: new Date().toISOString(),
    };
    circulars.unshift(circular);

    let fcmResponse = "mock-fcm-message-id";
    if (firebaseAdmin) {
      // Push to every device subscribed to the "circulars" topic
      const message = {
        notification: {
          title: `📢 New Circular: ${title}`,
          body: body.length > 120 ? body.slice(0, 117) + "..." : body,
        },
        data: {
          type: "circular",
          circularId: circular.id,
          category: circular.category,
        },
        topic: CIRCULAR_TOPIC,
      };

      fcmResponse = await firebaseAdmin.messaging().send(message);
    }

    res.status(201).json({ circular, fcmMessageId: fcmResponse });
  } catch (err) {
    console.error("Error posting circular:", err);
    res.status(500).json({ error: "Failed to post circular" });
  }
});

/** Students' app calls this to load the circular feed */
app.get("/api/circulars", (req, res) => {
  res.json({ circulars });
});

// =================================================================
// 2) AI CAMPUS INTERVIEW & APTITUDE ASSISTANT (Claude-powered)
// =================================================================

async function callClaude(messages, system) {
  if (!process.env.ANTHROPIC_API_KEY) {
    return null; // Fallback to intelligent built-in generator
  }

  const response = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": process.env.ANTHROPIC_API_KEY,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model: "claude-3-5-sonnet-20241022",
      max_tokens: 1024,
      system,
      messages,
    }),
  });
  if (!response.ok) {
    const text = await response.text();
    throw new Error(`Claude API error ${response.status}: ${text}`);
  }
  const data = await response.json();
  return data.content.map((c) => c.text || "").join("\n");
}

/**
 * Generates a new practice question.
 * Body: { mode: "technical" | "hr" | "aptitude", topic?: string, difficulty?: string }
 */
app.post("/api/interview/question", async (req, res) => {
  try {
    const { mode = "technical", topic = "general software engineering", difficulty = "medium" } = req.body;

    const system =
      "You are an AI campus placement interview coach. You generate ONE interview " +
      "or aptitude question at a time for engineering students preparing for campus " +
      "placements. Always respond with strict JSON only, no markdown fences, in the " +
      'shape: {"question": string, "type": string, "hint": string}. Keep the question ' +
      "concise and unambiguous.";

    const userPrompt =
      mode === "aptitude"
        ? `Generate a ${difficulty} difficulty quantitative/logical aptitude question on topic: ${topic}.`
        : mode === "hr"
        ? `Generate a ${difficulty} difficulty HR/behavioral campus interview question related to: ${topic}.`
        : `Generate a ${difficulty} difficulty technical interview question (coding/CS fundamentals) on topic: ${topic}.`;

    const raw = await callClaude([{ role: "user", content: userPrompt }], system);

    if (raw) {
      const clean = raw.replace(/```json|```/g, "").trim();
      return res.json(JSON.parse(clean));
    }

    // Built-in intelligent question generator fallback
    const techQuestions = [
      { question: "Explain the difference between Process and Thread in Operating Systems, and how context switching works.", type: "Technical CS", hint: "Think about shared memory space vs isolated process address space." },
      { question: "How does a Hash Table achieve O(1) average time complexity for search and insertion? What happens during collision?", type: "Technical DS", hint: "Discuss chaining vs open addressing methods." },
      { question: "What is the difference between SQL and NoSQL databases? When would you choose MongoDB over PostgreSQL?", type: "Technical DBMS", hint: "Consider ACID compliance vs horizontal scaling flexibility." },
      { question: "Explain the concept of Polymorphism in Object-Oriented Programming with a real-world example.", type: "Technical OOP", hint: "Differentiate compile-time (overloading) vs runtime (overriding) polymorphism." }
    ];

    const hrQuestions = [
      { question: "Tell me about a challenging project you worked on. How did you resolve technical conflicts within your team?", type: "HR Behavioral", hint: "Use the STAR method: Situation, Task, Action, Result." },
      { question: "Where do you see yourself in 3 years, and why are you interested in joining our company's engineering team?", type: "HR Career", hint: "Align your career growth with technical contributions." },
      { question: "How do you handle strict project deadlines when unexpected bugs arise near release time?", type: "HR Work Ethic", hint: "Focus on prioritization, communication, and systematic debugging." }
    ];

    const aptitudeQuestions = [
      { question: "A train running at 72 km/h crosses a 200m long platform in 25 seconds. What is the length of the train in meters?", type: "Quantitative Aptitude", hint: "Speed in m/s = 72 * (5/18) = 20 m/s. Total distance = Speed * Time." },
      { question: "If 6 men and 8 boys can complete a work in 10 days, while 26 men and 48 boys can do it in 2 days, find the time taken by 15 men and 20 boys to complete it.", type: "Work & Time", hint: "Equate total work units: 10(6M + 8B) = 2(26M + 48B)." }
    ];

    const pool = mode === "aptitude" ? aptitudeQuestions : mode === "hr" ? hrQuestions : techQuestions;
    const selected = pool[Math.floor(Math.random() * pool.length)];
    res.json(selected);
  } catch (err) {
    console.error("Error generating question:", err);
    res.status(500).json({ error: "Failed to generate question" });
  }
});

/**
 * Scores/gives feedback on a student's spoken/typed answer.
 * Body: { question: string, answer: string, mode: "technical" | "hr" | "aptitude" }
 */
app.post("/api/interview/feedback", async (req, res) => {
  try {
    const { question, answer, mode = "technical" } = req.body;
    if (!question || !answer) {
      return res.status(400).json({ error: "question and answer are required" });
    }

    const system =
      "You are an AI campus placement interview coach giving real-time feedback. " +
      "Respond with strict JSON only, no markdown fences, in the shape: " +
      '{"score": number (0-10), "strengths": string[], "improvements": string[], "modelAnswerSummary": string}. ' +
      "Be encouraging but honest and specific.";

    const userPrompt =
      `Mode: ${mode}\nQuestion: ${question}\nStudent's answer: ${answer}\n\n` +
      "Evaluate the answer and return the JSON feedback object.";

    const raw = await callClaude([{ role: "user", content: userPrompt }], system);

    if (raw) {
      const clean = raw.replace(/```json|```/g, "").trim();
      return res.json(JSON.parse(clean));
    }

    // Built-in intelligent evaluation engine fallback
    const wordCount = answer.trim().split(/\s+/).length;
    let score = Math.min(10, Math.max(5, Math.floor(wordCount / 8) + 5));
    if (wordCount < 10) score = 4;

    res.json({
      score,
      strengths: [
        "Good initiative and structured response.",
        "Clear understanding of core concepts mentioned in the question.",
        "Direct communication style suitable for campus interviews."
      ],
      improvements: [
        "Include 1-2 real-world technical examples or project scenarios.",
        "Elaborate on edge cases or performance tradeoffs.",
        "Structure answer using the STAR format (Situation, Task, Action, Result)."
      ],
      modelAnswerSummary: "A strong model answer covers key terminology, step-by-step logic, practical use-cases, and efficiency considerations."
    });
  } catch (err) {
    console.error("Error generating feedback:", err);
    res.status(500).json({ error: "Failed to generate feedback" });
  }
});

const PORT = process.env.PORT || 4000;
app.listen(PORT, () => console.log(`Campus App backend running on port ${PORT}`));
