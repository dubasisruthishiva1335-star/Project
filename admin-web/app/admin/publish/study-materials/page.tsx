"use client";

import { useState } from "react";
import { apiRequest } from "@/lib/api-client";

const BRANCHES = ["GENERAL", "CSE & IT", "ECE", "AI & ML", "EEE", "MECH & CIVIL"];
const SEMESTERS = [1, 2, 3, 4, 5, 6, 7, 8];

export default function StudyMaterialsPublish() {
  const [form, setForm] = useState({
    title: "",
    branch: "CSE & IT",
    semester: 1,
    unit: 1,
    subject: "",
    contentType: "NOTES",
    description: "",
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
      setMessage({ type: "error", text: "Material Title is required." });
      return;
    }
    setSubmitting(true);
    setMessage(null);
    try {
      let fileUrl = null;
      let s3Key = null;

      const res = await apiRequest<{ success: boolean }>("/admin/notes/confirm", {
        method: "POST",
        body: JSON.stringify({ ...form, fileUrl, s3Key }),
      });

      if (res.success) {
        setMessage({ type: "success", text: "📚 Study Material published successfully — visible in Academic Repository instantly." });
        setForm({ title: "", branch: "CSE & IT", semester: 1, unit: 1, subject: "", contentType: "NOTES", description: "" });
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
        <span>📚</span> Publish Academic Study Material
      </h1>
      <p className="mb-6 text-sm text-white/50">
        Uploads lecture notes, PDFs, and lab manuals organized by Branch, Semester, and Subject in the Mobile App.
      </p>

      {message && (
        <div
          className={`mb-6 rounded-xl px-4 py-3 text-sm font-semibold border ${
            message.type === "success"
              ? "bg-emerald-500/10 text-emerald-300 border-emerald-500/30"
              : "bg-red-500/10 text-red-300 border-red-500/30"
          }`}
        >
          {message.text}
        </div>
      )}

      <form onSubmit={handleSubmit} className="space-y-4 rounded-2xl border border-white/10 bg-white/[0.02] p-6 backdrop-blur-xl">
        <div>
          <label className="mb-1.5 block text-xs font-medium text-white/80">Material Title *</label>
          <input
            name="title"
            value={form.title}
            onChange={handleChange}
            placeholder="e.g. Unit 3 — Data Structures & Algorithms Notes"
            required
            className="w-full rounded-lg border border-white/10 bg-black/40 px-3 py-2 text-sm text-white placeholder-white/30 focus:border-emerald-400/50 focus:outline-none"
          />
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="mb-1.5 block text-xs font-medium text-white/80">Engineering Branch *</label>
            <select
              name="branch"
              value={form.branch}
              onChange={handleChange}
              className="w-full rounded-lg border border-white/10 bg-black/40 px-3 py-2 text-sm text-white focus:border-emerald-400/50 focus:outline-none"
            >
              {BRANCHES.map((b) => (
                <option key={b} value={b} className="bg-neutral-900 text-white">
                  {b}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="mb-1.5 block text-xs font-medium text-white/80">Semester *</label>
            <select
              name="semester"
              value={form.semester}
              onChange={handleChange}
              className="w-full rounded-lg border border-white/10 bg-black/40 px-3 py-2 text-sm text-white focus:border-emerald-400/50 focus:outline-none"
            >
              {SEMESTERS.map((s) => (
                <option key={s} value={s} className="bg-neutral-900 text-white">
                  Semester {s}
                </option>
              ))}
            </select>
          </div>
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="mb-1.5 block text-xs font-medium text-white/80">Unit Number *</label>
            <select
              name="unit"
              value={form.unit}
              onChange={handleChange}
              className="w-full rounded-lg border border-white/10 bg-black/40 px-3 py-2 text-sm text-white focus:border-emerald-400/50 focus:outline-none"
            >
              {[1, 2, 3, 4, 5].map((u) => (
                <option key={u} value={u} className="bg-neutral-900 text-white">
                  Unit {u}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="mb-1.5 block text-xs font-medium text-white/80">Content Type *</label>
            <select
              name="contentType"
              value={form.contentType}
              onChange={handleChange}
              className="w-full rounded-lg border border-white/10 bg-black/40 px-3 py-2 text-sm text-white focus:border-emerald-400/50 focus:outline-none"
            >
              <option value="NOTES" className="bg-neutral-900 text-white">📄 Lecture Notes</option>
              <option value="VIDEO_LECTURE" className="bg-neutral-900 text-white">🎬 Video Lecture</option>
              <option value="LAB_MANUAL" className="bg-neutral-900 text-white">🧪 Lab Manual</option>
              <option value="CHEAT_SHEET" className="bg-neutral-900 text-white">⚡ Cheat Sheet</option>
              <option value="QUESTION_BANK" className="bg-neutral-900 text-white">📊 Question Bank</option>
            </select>
          </div>
        </div>

        <div>
          <label className="mb-1.5 block text-xs font-medium text-white/80">Subject Name (optional)</label>
          <input
            name="subject"
            value={form.subject}
            onChange={handleChange}
            placeholder="e.g. Data Structures & Algorithms (CS301)"
            className="w-full rounded-lg border border-white/10 bg-black/40 px-3 py-2 text-sm text-white placeholder-white/30 focus:border-emerald-400/50 focus:outline-none"
          />
        </div>

        <div>
          <label className="mb-1.5 block text-xs font-medium text-white/80">Brief Description (optional)</label>
          <textarea
            name="description"
            value={form.description}
            onChange={handleChange}
            rows={3}
            placeholder="Overview of topics covered in this material..."
            className="w-full rounded-lg border border-white/10 bg-black/40 px-3 py-2 text-sm text-white placeholder-white/30 focus:border-emerald-400/50 focus:outline-none"
          />
        </div>

        <div>
          <label className="mb-1.5 block text-xs font-medium text-white/80">PDF Document or MP4 Video File</label>
          <input
            type="file"
            accept="application/pdf,video/mp4"
            onChange={(e) => setFile(e.target.files?.[0] || null)}
            className="w-full rounded-lg border border-white/10 bg-black/40 px-3 py-2 text-sm text-white/70"
          />
        </div>

        <button
          type="submit"
          disabled={submitting}
          className="w-full rounded-xl bg-emerald-500/20 border border-emerald-500/40 px-4 py-3 text-sm font-extrabold text-emerald-300 hover:bg-emerald-500/30 disabled:opacity-50 transition-colors"
        >
          {submitting ? "Publishing Study Material..." : "Publish Study Material 📚"}
        </button>
      </form>
    </div>
  );
}
