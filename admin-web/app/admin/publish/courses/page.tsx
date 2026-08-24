"use client";

import { useState } from "react";
import { apiRequest } from "@/lib/api-client";

const EXAMS = [
  "UPSC Civil Services (IAS / IPS / IFS)",
  "SSC CGL (Staff Selection Commission)",
  "SBI PO / IBPS PO & Clerk",
  "Railway Recruitment Board (RRB JE / NTPC)",
  "GATE Engineering (CS / ECE / EE / ME)",
  "JEE Main & Advanced",
  "NEET Medical Entrance",
  "CAT / Management Entrance",
];

export default function CoursesPublish() {
  const [form, setForm] = useState({
    title: "",
    examName: "UPSC Civil Services (IAS / IPS / IFS)",
    subject: "General Studies",
    unit: "Unit 1",
    contentType: "VIDEO_LECTURE",
    description: "",
    s3Url: "",
  });
  const [file, setFile] = useState<File | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [message, setMessage] = useState<{ type: "success" | "error"; text: string } | null>(null);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    setForm((p) => ({ ...p, [e.target.name]: e.target.value }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.title) {
      setMessage({ type: "error", text: "Course / Video Title is required." });
      return;
    }
    setSubmitting(true);
    setMessage(null);
    try {
      const res = await apiRequest<{ success: boolean }>("/admin/exams/confirm", {
        method: "POST",
        body: JSON.stringify({ ...form, fileUrl: form.s3Url }),
      });

      if (res.success) {
        setMessage({ type: "success", text: "🎓 Course / Exam Prep material published — visible in Preparation Hub instantly." });
        setForm({ title: "", examName: "UPSC Civil Services (IAS / IPS / IFS)", subject: "General Studies", unit: "Unit 1", contentType: "VIDEO_LECTURE", description: "", s3Url: "" });
        setFile(null);
      }
    } catch (err: any) {
      setMessage({ type: "error", text: err instanceof Error ? err.message : "Upload failed. Try again." });
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="mx-auto max-w-2xl px-4 py-10">
      <h1 className="mb-1 text-xl font-bold text-white flex items-center gap-2">
        <span>🎓</span> Publish Course & Competitive Exam Prep
      </h1>
      <p className="mb-6 text-sm text-white/50">
        Publish structured courses, video lectures, and exam prep modules for UPSC, SSC, Banking, GATE, etc.
      </p>

      {message && (
        <div
          className={`mb-6 rounded-xl px-4 py-3 text-sm font-semibold border ${
            message.type === "success"
              ? "bg-cyan-500/10 text-cyan-300 border-cyan-500/30"
              : "bg-red-500/10 text-red-300 border-red-500/30"
          }`}
        >
          {message.text}
        </div>
      )}

      <form onSubmit={handleSubmit} className="space-y-4 rounded-2xl border border-white/10 bg-white/[0.02] p-6 backdrop-blur-xl">
        <div>
          <label className="mb-1.5 block text-xs font-medium text-white/80">Lesson / Module Title *</label>
          <input
            name="title"
            value={form.title}
            onChange={handleChange}
            placeholder="e.g. Indian Polity — Preamble & Fundamental Rights"
            required
            className="w-full rounded-lg border border-white/10 bg-black/40 px-3 py-2 text-sm text-white placeholder-white/30 focus:border-cyan-400/50 focus:outline-none"
          />
        </div>

        <div>
          <label className="mb-1.5 block text-xs font-medium text-white/80">Target Exam Target *</label>
          <select
            name="examName"
            value={form.examName}
            onChange={handleChange}
            className="w-full rounded-lg border border-white/10 bg-black/40 px-3 py-2 text-sm text-white focus:border-cyan-400/50 focus:outline-none"
          >
            {EXAMS.map((ex) => (
              <option key={ex} value={ex} className="bg-neutral-900 text-white">
                {ex}
              </option>
            ))}
          </select>
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="mb-1.5 block text-xs font-medium text-white/80">Subject Module</label>
            <input
              name="subject"
              value={form.subject}
              onChange={handleChange}
              placeholder="e.g. Quantitative Aptitude"
              className="w-full rounded-lg border border-white/10 bg-black/40 px-3 py-2 text-sm text-white placeholder-white/30 focus:border-cyan-400/50 focus:outline-none"
            />
          </div>

          <div>
            <label className="mb-1.5 block text-xs font-medium text-white/80">Content Type *</label>
            <select
              name="contentType"
              value={form.contentType}
              onChange={handleChange}
              className="w-full rounded-lg border border-white/10 bg-black/40 px-3 py-2 text-sm text-white focus:border-cyan-400/50 focus:outline-none"
            >
              <option value="VIDEO_LECTURE" className="bg-neutral-900 text-white">🎬 Video Stream Lesson</option>
              <option value="NOTES" className="bg-neutral-900 text-white">📄 Comprehensive PDF Notes</option>
              <option value="PRACTICE_SET" className="bg-neutral-900 text-white">⚡ Practice Problem Set</option>
              <option value="PYQ" className="bg-neutral-900 text-white">📜 Previous Year Question Paper</option>
            </select>
          </div>
        </div>

        <div>
          <label className="mb-1.5 block text-xs font-medium text-white/80">Video Stream URL / File Link</label>
          <input
            name="s3Url"
            value={form.s3Url}
            onChange={handleChange}
            placeholder="https://myvault-files-app.s3.eu-north-1.amazonaws.com/lecture.mp4"
            className="w-full rounded-lg border border-white/10 bg-black/40 px-3 py-2 text-sm text-white placeholder-white/30 focus:border-cyan-400/50 focus:outline-none"
          />
        </div>

        <div>
          <label className="mb-1.5 block text-xs font-medium text-white/80">Course Summary & Key Learning Points</label>
          <textarea
            name="description"
            value={form.description}
            onChange={handleChange}
            rows={3}
            placeholder="Key exam tricks, shortcut methods, syllabus coverage..."
            className="w-full rounded-lg border border-white/10 bg-black/40 px-3 py-2 text-sm text-white placeholder-white/30 focus:border-cyan-400/50 focus:outline-none"
          />
        </div>

        <button
          type="submit"
          disabled={submitting}
          className="w-full rounded-xl bg-cyan-500/20 border border-cyan-500/40 px-4 py-3 text-sm font-extrabold text-cyan-300 hover:bg-cyan-500/30 disabled:opacity-50 transition-colors"
        >
          {submitting ? "Publishing Course Material..." : "Publish Course Material 🎓"}
        </button>
      </form>
    </div>
  );
}
