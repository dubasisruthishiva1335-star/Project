"use client";

import { useEffect, useState } from "react";
import Link from "next/link";

interface Internship {
  id: string;
  title: string;
  description: string;
  duration: string;
  level: string;
  category: string;
  thumbnailUrl?: string;
  status: "draft" | "published";
  createdAt?: string;
}

export default function InternshipsAdminPage() {
  const [internships, setInternships] = useState<Internship[]>([]);
  const [loading, setLoading] = useState(true);

  // New Internship Modal State
  const [isCreating, setIsCreating] = useState(false);
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [duration, setDuration] = useState("45 Days");
  const [level, setLevel] = useState("Intermediate");
  const [category, setCategory] = useState("Full Stack Development");
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    fetchInternships();
  }, []);

  async function fetchInternships() {
    setLoading(true);
    try {
      const res = await fetch("https://romantic-serenity-production-3e5b.up.railway.app/api/admin/internships");
      const data = await res.json();
      if (data.internships) {
        setInternships(data.internships);
      }
    } catch (_) {
      // Fallback sample data
      setInternships([
        {
          id: "int_fullstack_001",
          title: "Full Stack Developer Internship",
          description: "45-day industry program covering React, Node.js, Express, PostgreSQL, and AWS S3.",
          duration: "45 Days",
          level: "Intermediate",
          category: "Development",
          status: "published",
        },
      ]);
    } finally {
      setLoading(false);
    }
  }

  async function handleCreateInternship(e: React.FormEvent) {
    e.preventDefault();
    setSaving(true);
    const newId = `int_${Date.now()}`;
    const payload = {
      id: newId,
      title,
      description,
      duration,
      level,
      category,
      status: "published",
      skills: ["React", "Node.js", "PostgreSQL"],
    };

    try {
      await fetch("https://romantic-serenity-production-3e5b.up.railway.app/api/admin/internships", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });
      setIsCreating(false);
      setTitle("");
      setDescription("");
      fetchInternships();
    } catch (err) {
      alert("Failed to create internship");
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="mx-auto max-w-6xl px-4 py-8">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-8">
        <div>
          <h1 className="text-2xl font-bold text-white">Internship LMS Content Builder</h1>
          <p className="text-sm text-white/60">
            Create, manage modules, upload video lessons to AWS S3, add quizzes, assignments, and publish content to MyVault App.
          </p>
        </div>
        <div className="flex items-center gap-3">
          <Link
            href="/admin/submissions"
            className="rounded-lg border border-white/20 bg-white/5 px-4 py-2 text-sm font-medium text-white hover:bg-white/10"
          >
            Review Submissions
          </Link>
          <button
            onClick={() => setIsCreating(true)}
            className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-500 shadow-lg shadow-blue-600/30"
          >
            + Create Internship
          </button>
        </div>
      </div>

      {/* Modal for Creating Internship */}
      {isCreating && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 p-4">
          <div className="w-full max-w-md rounded-2xl border border-white/10 bg-slate-900 p-6 text-white shadow-2xl">
            <h2 className="text-lg font-bold mb-4">Create New Internship Program</h2>
            <form onSubmit={handleCreateInternship} className="space-y-4">
              <div>
                <label className="block text-xs font-medium text-white/70 mb-1">Internship Title</label>
                <input
                  type="text"
                  required
                  placeholder="e.g. Full Stack Developer Internship"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  className="w-full rounded-lg border border-white/15 bg-white/5 px-3 py-2 text-sm text-white placeholder-white/30 focus:border-blue-500 focus:outline-none"
                />
              </div>

              <div>
                <label className="block text-xs font-medium text-white/70 mb-1">Description</label>
                <textarea
                  required
                  rows={3}
                  placeholder="Detailed description of skills learned..."
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  className="w-full rounded-lg border border-white/15 bg-white/5 px-3 py-2 text-sm text-white placeholder-white/30 focus:border-blue-500 focus:outline-none"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-medium text-white/70 mb-1">Duration</label>
                  <input
                    type="text"
                    value={duration}
                    onChange={(e) => setDuration(e.target.value)}
                    className="w-full rounded-lg border border-white/15 bg-white/5 px-3 py-2 text-sm text-white focus:border-blue-500 focus:outline-none"
                  />
                </div>
                <div>
                  <label className="block text-xs font-medium text-white/70 mb-1">Level</label>
                  <select
                    value={level}
                    onChange={(e) => setLevel(e.target.value)}
                    className="w-full rounded-lg border border-white/15 bg-slate-800 px-3 py-2 text-sm text-white focus:border-blue-500 focus:outline-none"
                  >
                    <option value="Beginner">Beginner</option>
                    <option value="Intermediate">Intermediate</option>
                    <option value="Advanced">Advanced</option>
                  </select>
                </div>
              </div>

              <div className="flex justify-end gap-3 pt-4">
                <button
                  type="button"
                  onClick={() => setIsCreating(false)}
                  className="rounded-lg px-4 py-2 text-sm text-white/60 hover:text-white"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={saving}
                  className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-500 disabled:opacity-50"
                >
                  {saving ? "Creating..." : "Save & Continue"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Internships List Grid */}
      {loading ? (
        <div className="py-20 text-center text-white/50">Loading internships...</div>
      ) : internships.length === 0 ? (
        <div className="rounded-2xl border border-white/10 bg-white/5 p-12 text-center">
          <p className="text-white/60 mb-4">No internships created yet.</p>
          <button
            onClick={() => setIsCreating(true)}
            className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-500"
          >
            Create Your First Internship
          </button>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {internships.map((int) => (
            <div
              key={int.id}
              className="rounded-2xl border border-white/10 bg-slate-900/60 p-6 backdrop-blur transition hover:border-white/20"
            >
              <div className="flex items-start justify-between mb-3">
                <span className="rounded-full bg-blue-500/10 px-3 py-1 text-xs font-semibold text-blue-400 border border-blue-500/20">
                  {int.duration}
                </span>
                <span
                  className={`rounded-full px-2.5 py-0.5 text-xs font-medium ${
                    int.status === "published"
                      ? "bg-emerald-500/10 text-emerald-400 border border-emerald-500/20"
                      : "bg-amber-500/10 text-amber-400 border border-amber-500/20"
                  }`}
                >
                  {int.status.toUpperCase()}
                </span>
              </div>

              <h2 className="text-lg font-bold text-white mb-2">{int.title}</h2>
              <p className="text-sm text-white/60 mb-6 line-clamp-2">{int.description}</p>

              <div className="flex items-center justify-between pt-4 border-t border-white/10">
                <span className="text-xs text-white/40">Level: {int.level}</span>
                <Link
                  href={`/admin/internships/${int.id}`}
                  className="inline-flex items-center gap-1.5 rounded-lg bg-blue-600 px-4 py-2 text-xs font-semibold text-white hover:bg-blue-500 transition"
                >
                  Manage Content & LMS →
                </Link>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
