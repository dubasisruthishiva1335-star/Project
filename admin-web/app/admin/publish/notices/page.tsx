"use client";

import { useState } from "react";
import { apiRequest } from "@/lib/api-client";

export default function NoticesPublish() {
  const [form, setForm] = useState({
    title: "",
    priority: "HIGH",
    targetBranch: "All Branches",
    description: "",
    fileUrl: "",
  });
  const [submitting, setSubmitting] = useState(false);
  const [message, setMessage] = useState<{ type: "success" | "error"; text: string } | null>(null);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    setForm((p) => ({ ...p, [e.target.name]: e.target.value }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.title) {
      setMessage({ type: "error", text: "Notice Title is required." });
      return;
    }
    setSubmitting(true);
    setMessage(null);
    try {
      const res = await apiRequest<{ success: boolean }>("/admin/notes/confirm", {
        method: "POST",
        body: JSON.stringify({ title: form.title, branch: form.targetBranch, contentType: "NOTICE", description: form.description }),
      });

      if (res.success) {
        setMessage({ type: "success", text: "📢 Notice / Circular published successfully — synced to Mobile App in real-time." });
        setForm({ title: "", priority: "HIGH", targetBranch: "All Branches", description: "", fileUrl: "" });
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
        <span>📢</span> Publish Notice & Official Circular
      </h1>
      <p className="mb-6 text-sm text-white/50">
        Post urgent campus notices, exam timetable circulars, and priority notifications to students.
      </p>

      {message && (
        <div
          className={`mb-6 rounded-xl px-4 py-3 text-sm font-semibold border ${
            message.type === "success"
              ? "bg-rose-500/10 text-rose-300 border-rose-500/30"
              : "bg-red-500/10 text-red-300 border-red-500/30"
          }`}
        >
          {message.text}
        </div>
      )}

      <form onSubmit={handleSubmit} className="space-y-4 rounded-2xl border border-white/10 bg-white/[0.02] p-6 backdrop-blur-xl">
        <div>
          <label className="mb-1.5 block text-xs font-medium text-white/80">Notice Title *</label>
          <input
            name="title"
            value={form.title}
            onChange={handleChange}
            placeholder="e.g. End Semester Examination Timetable Circular 2026"
            required
            className="w-full rounded-lg border border-white/10 bg-black/40 px-3 py-2 text-sm text-white placeholder-white/30 focus:border-rose-400/50 focus:outline-none"
          />
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="mb-1.5 block text-xs font-medium text-white/80">Priority Level *</label>
            <select
              name="priority"
              value={form.priority}
              onChange={handleChange}
              className="w-full rounded-lg border border-white/10 bg-black/40 px-3 py-2 text-sm text-white focus:border-rose-400/50 focus:outline-none"
            >
              <option value="URGENT" className="bg-neutral-900 text-white">🔴 URGENT ALERT</option>
              <option value="HIGH" className="bg-neutral-900 text-white">🟠 HIGH PRIORITY</option>
              <option value="NORMAL" className="bg-neutral-900 text-white">🟢 NORMAL ANNOUNCEMENT</option>
            </select>
          </div>

          <div>
            <label className="mb-1.5 block text-xs font-medium text-white/80">Target Student Branch *</label>
            <select
              name="targetBranch"
              value={form.targetBranch}
              onChange={handleChange}
              className="w-full rounded-lg border border-white/10 bg-black/40 px-3 py-2 text-sm text-white focus:border-rose-400/50 focus:outline-none"
            >
              <option value="All Branches" className="bg-neutral-900 text-white">All Engineering Streams</option>
              <option value="CSE & IT" className="bg-neutral-900 text-white">CSE & IT Only</option>
              <option value="ECE" className="bg-neutral-900 text-white">ECE Only</option>
              <option value="EEE" className="bg-neutral-900 text-white">EEE Only</option>
              <option value="MECH & CIVIL" className="bg-neutral-900 text-white">MECH & CIVIL Only</option>
            </select>
          </div>
        </div>

        <div>
          <label className="mb-1.5 block text-xs font-medium text-white/80">Circular Details & Message</label>
          <textarea
            name="description"
            value={form.description}
            onChange={handleChange}
            rows={4}
            placeholder="Complete text of notice, key dates, instructions for students..."
            className="w-full rounded-lg border border-white/10 bg-black/40 px-3 py-2 text-sm text-white placeholder-white/30 focus:border-rose-400/50 focus:outline-none"
          />
        </div>

        <button
          type="submit"
          disabled={submitting}
          className="w-full rounded-xl bg-rose-500/20 border border-rose-500/40 px-4 py-3 text-sm font-extrabold text-rose-300 hover:bg-rose-500/30 disabled:opacity-50 transition-colors"
        >
          {submitting ? "Publishing Notice..." : "Publish Notice & Circular 📢"}
        </button>
      </form>
    </div>
  );
}
