"use client";

import { useState, useEffect, useCallback } from "react";
import { UploadForm, type UploadFormConfig } from "@/components/admin/UploadForm";

interface PrepResource {
  id: string;
  examId: string;
  subject: string;
  topic: string;
  title: string;
  description?: string;
  contentType: "VIDEO" | "PDF" | "NOTE" | "SYLLABUS" | "PREVIOUS_PAPER" | "CURRENT_AFFAIRS";
  fileUrl: string;
  thumbnailUrl?: string;
  fileSize?: number;
  durationSeconds?: number;
  isFree: boolean;
  isPublished: boolean;
  uploadedBy: string;
  createdAt: string;
}

const STORAGE_KEY = "myvault_prep_hub_v1";

export default function PreparationHubAdminPage() {
  const [resources, setResources] = useState<PrepResource[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedExam, setSelectedExam] = useState<string>("All");
  const [selectedType, setSelectedType] = useState<string>("All");
  const [searchQuery, setSearchQuery] = useState<string>("");
  const [activeMode, setActiveMode] = useState<"VIDEO" | "PDF" | "NOTE" | "SYLLABUS" | "PREVIOUS_PAPER">("VIDEO");

  // Dynamic file requirements based on Content Type
  const acceptedFileTypes =
    activeMode === "VIDEO"
      ? "video/mp4, video/webm, video/*"
      : activeMode === "SYLLABUS"
      ? "application/pdf, .doc, .docx"
      : "application/pdf";

  const targetFolder =
    activeMode === "VIDEO"
      ? "competitive-exams/preparation/videos"
      : activeMode === "SYLLABUS"
      ? "competitive-exams/preparation/syllabus"
      : "competitive-exams/preparation/notes";

  const formConfig: UploadFormConfig = {
    domain: targetFolder,
    confirmPath: "/admin/exams/confirm",
    acceptedFileTypes: acceptedFileTypes,
    requireFile: true,
    successMessage: `Preparation Resource (${activeMode}) uploaded successfully to AWS S3 & synced with Mobile App instantly!`,
    fields: [
      {
        name: "examId",
        label: "Target Competitive Exam *",
        type: "select",
        required: true,
        options: [
          { value: "ssc-cgl-2026", label: "📚 SSC CGL 2026 (Staff Selection Commission)" },
          { value: "upsc-cse-2026", label: "🏛️ UPSC Civil Services 2026 (IAS / IPS / IFS)" },
          { value: "ibps-po-2026", label: "🏦 IBPS PO / SBI PO 2026 (Banking)" },
          { value: "rrb-ntpc-2026", label: "🚆 RRB NTPC & Railway JE 2026" },
          { value: "gate-cse-2027", label: "⚡ GATE CSE 2027 (Engineering)" },
          { value: "cat-mba-2026", label: "💼 CAT / XAT 2026 (Management)" },
        ],
      },
      {
        name: "subject",
        label: "Subject Module *",
        type: "select",
        required: true,
        options: [
          { value: "Quantitative Aptitude", label: "🔢 Quantitative Aptitude" },
          { value: "Logical Reasoning", label: "🧩 Logical Reasoning" },
          { value: "English Language", label: "📖 English Language" },
          { value: "General Awareness", label: "🌐 General Awareness & GK" },
          { value: "Current Affairs", label: "📰 Current Affairs & Daily News" },
          { value: "Computer Science Core", label: "💻 Computer Science Core (GATE)" },
        ],
      },
      { name: "topic", label: "Chapter Topic (e.g. Percentage, Profit & Loss)", type: "text", required: true, placeholder: "e.g. Percentage - Complete Concept" },
      { name: "title", label: "Preparation Content Title *", type: "text", required: true, placeholder: "e.g. Percentage Masterclass & Solved PYQs" },
      { name: "description", label: "Content Description", type: "text", required: false, placeholder: "e.g. Learn percentage concepts from basics with shortcut tricks..." },
      { name: "duration", label: "Video Duration / Reading Time (e.g. 42:15)", type: "text", required: false, placeholder: "e.g. 42:15" },
      { name: "publicUrl", label: "External S3 / CDN URL (optional direct link)", type: "text", required: false, placeholder: "https://myvault-files-app.s3.eu-north-1.amazonaws.com/lecture.mp4" },
    ],
  };

  const loadResources = useCallback(async () => {
    setLoading(true);
    let localItems: PrepResource[] = [];
    if (typeof window !== "undefined") {
      try {
        const saved = localStorage.getItem(STORAGE_KEY);
        if (saved) localItems = JSON.parse(saved);
      } catch (_) {}
    }

    try {
      const response = await fetch("/api/admin/preparation");
      if (response.ok) {
        const res = await response.json();
        const apiList: PrepResource[] = res.data || [];
        const mergedMap = new Map<string, PrepResource>();
        localItems.forEach((item) => mergedMap.set(String(item.id), item));
        apiList.forEach((item) => mergedMap.set(String(item.id), item));
        setResources(Array.from(mergedMap.values()));
      } else if (localItems.length > 0) {
        setResources(localItems);
      }
    } catch (_) {
      if (localItems.length > 0) setResources(localItems);
    }
    setLoading(false);
  }, []);

  useEffect(() => {
    loadResources();
  }, [loadResources]);

  const handleFormSuccess = (payload: Record<string, any>, file: File | null) => {
    const fileUrl =
      payload.publicUrl ||
      (file ? `https://myvault-files-app.s3.eu-north-1.amazonaws.com/${targetFolder}/${Date.now()}_${file.name.replace(/[^a-zA-Z0-9._-]/g, "_")}` : "") ||
      "https://myvault-files-app.s3.eu-north-1.amazonaws.com/app-arm64-v8a-release.apk";

    const newItem: PrepResource = {
      id: `local_prep_${Date.now()}`,
      examId: payload.examId || "ssc-cgl-2026",
      subject: payload.subject || "Quantitative Aptitude",
      topic: payload.topic || "General",
      title: payload.title || "Uploaded Resource",
      description: payload.description || "",
      contentType: activeMode,
      fileUrl,
      isFree: true,
      isPublished: true,
      uploadedBy: "Admin",
      createdAt: new Date().toISOString(),
    };

    setResources((prev) => {
      const updated = [newItem, ...prev];
      if (typeof window !== "undefined") {
        try {
          localStorage.setItem(STORAGE_KEY, JSON.stringify(updated));
        } catch (_) {}
      }
      return updated;
    });
  };

  const videoCount = resources.filter((r) => r.contentType === "VIDEO").length;
  const notesCount = resources.filter((r) => r.contentType === "NOTE").length;
  const pdfCount = resources.filter((r) => r.contentType === "PDF" || r.fileUrl.endsWith(".pdf")).length;
  const totalCount = resources.length;

  const filtered = resources.filter((r) => {
    const matchesExam = selectedExam === "All" || r.examId.toLowerCase().includes(selectedExam.toLowerCase());
    const matchesType = selectedType === "All" || r.contentType === selectedType;
    const matchesSearch =
      r.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      r.subject.toLowerCase().includes(searchQuery.toLowerCase()) ||
      r.topic.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesExam && matchesType && matchesSearch;
  });

  return (
    <div className="mx-auto max-w-6xl px-4 py-10">
      {/* Header */}
      <div className="mb-8 flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="bg-gradient-to-r from-accentBlue to-accentCyan bg-clip-text text-3xl font-black text-transparent flex items-center gap-2">
            <span>Competitive Exam Preparation Hub</span>
            <span className="rounded-full bg-accentCyan/20 px-3 py-1 text-xs font-bold text-accentCyan border border-accentCyan/30">
              CMS ⭐
            </span>
          </h1>
          <p className="mt-1 text-sm text-white/60">
            Manage preparation content for competitive exams. Admin uploads videos, notes, PDFs & syllabus ➔ Syncs to Mobile App instantly.
          </p>
        </div>
        <button
          onClick={() => window.scrollTo({ top: 300, behavior: "smooth" })}
          className="rounded-xl bg-accentBlue px-5 py-2.5 text-xs font-bold text-white shadow-lg shadow-accentBlue/30 hover:bg-blue-600 transition"
        >
          + Upload Content
        </button>
      </div>

      {/* Analytics Summary Cards */}
      <div className="mb-8 grid grid-cols-2 gap-4 sm:grid-cols-4">
        <div className="rounded-2xl border border-white/10 bg-gradient-to-br from-purple-500/20 to-indigo-500/10 p-5 backdrop-blur-xl">
          <span className="text-2xl">🎬</span>
          <div className="mt-2 text-2xl font-black text-white">{videoCount}</div>
          <div className="text-xs font-semibold text-purple-300">Preparation Videos</div>
        </div>
        <div className="rounded-2xl border border-white/10 bg-gradient-to-br from-cyan-500/20 to-teal-500/10 p-5 backdrop-blur-xl">
          <span className="text-2xl">📚</span>
          <div className="mt-2 text-2xl font-black text-white">{notesCount}</div>
          <div className="text-xs font-semibold text-cyan-300">Study Notes</div>
        </div>
        <div className="rounded-2xl border border-white/10 bg-gradient-to-br from-amber-500/20 to-yellow-500/10 p-5 backdrop-blur-xl">
          <span className="text-2xl">📄</span>
          <div className="mt-2 text-2xl font-black text-white">{pdfCount}</div>
          <div className="text-xs font-semibold text-amber-300">PDF Documents</div>
        </div>
        <div className="rounded-2xl border border-white/10 bg-gradient-to-br from-emerald-500/20 to-green-500/10 p-5 backdrop-blur-xl">
          <span className="text-2xl">⚡</span>
          <div className="mt-2 text-2xl font-black text-white">{totalCount}</div>
          <div className="text-xs font-semibold text-emerald-300">Total Resources</div>
        </div>
      </div>

      {/* Resource Format Switcher */}
      <div className="mb-6 flex flex-wrap items-center gap-2 rounded-2xl border border-white/10 bg-black/40 p-2 backdrop-blur-xl">
        <span className="text-xs font-bold text-white/70 px-3">Content Type:</span>
        <button
          onClick={() => setActiveMode("VIDEO")}
          className={`flex items-center gap-2 rounded-xl px-4 py-2 text-xs font-bold transition ${
            activeMode === "VIDEO" ? "bg-accentBlue text-white shadow-lg" : "text-white/60 hover:text-white"
          }`}
        >
          🎬 Video
        </button>
        <button
          onClick={() => setActiveMode("PDF")}
          className={`flex items-center gap-2 rounded-xl px-4 py-2 text-xs font-bold transition ${
            activeMode === "PDF" ? "bg-accentBlue text-white shadow-lg" : "text-white/60 hover:text-white"
          }`}
        >
          📄 PDF
        </button>
        <button
          onClick={() => setActiveMode("NOTE")}
          className={`flex items-center gap-2 rounded-xl px-4 py-2 text-xs font-bold transition ${
            activeMode === "NOTE" ? "bg-accentBlue text-white shadow-lg" : "text-white/60 hover:text-white"
          }`}
        >
          📝 Notes
        </button>
        <button
          onClick={() => setActiveMode("SYLLABUS")}
          className={`flex items-center gap-2 rounded-xl px-4 py-2 text-xs font-bold transition ${
            activeMode === "SYLLABUS" ? "bg-accentBlue text-white shadow-lg" : "text-white/60 hover:text-white"
          }`}
        >
          📖 Syllabus
        </button>
        <button
          onClick={() => setActiveMode("PREVIOUS_PAPER")}
          className={`flex items-center gap-2 rounded-xl px-4 py-2 text-xs font-bold transition ${
            activeMode === "PREVIOUS_PAPER" ? "bg-accentBlue text-white shadow-lg" : "text-white/60 hover:text-white"
          }`}
        >
          📜 Previous Paper
        </button>
      </div>

      {/* Upload Screen Card */}
      <div className="mb-12 rounded-2xl border border-white/10 bg-white/[0.02] p-6 backdrop-blur-xl">
        <div className="mb-4 flex items-center justify-between">
          <h2 className="text-base font-bold text-white flex items-center gap-2">
            <span>📤 Upload Preparation Content ({activeMode}) to AWS S3</span>
          </h2>
          <span className="rounded-full bg-cyan-400/10 px-3 py-1 text-xs font-semibold text-cyan-300 border border-cyan-400/20">
            Accepted: {acceptedFileTypes}
          </span>
        </div>
        <UploadForm key={activeMode} config={formConfig} onSuccess={handleFormSuccess} />
      </div>

      {/* Management Directory & Table */}
      <div className="rounded-2xl border border-white/10 bg-white/[0.02] p-6 backdrop-blur-xl">
        <div className="mb-6 flex flex-wrap items-center justify-between gap-4">
          <div>
            <h2 className="text-xl font-extrabold text-white">📚 Preparation Content Library ({filtered.length})</h2>
            <p className="text-xs text-white/50">All published items stream live on the Student Mobile App</p>
          </div>

          <div className="flex flex-wrap items-center gap-3">
            <input
              type="text"
              placeholder="Search content, topic, subject..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="rounded-xl border border-white/10 bg-black/60 px-4 py-2 text-xs text-white placeholder-white/40 focus:border-accentCyan focus:outline-none w-56"
            />
            <select
              value={selectedExam}
              onChange={(e) => setSelectedExam(e.target.value)}
              className="rounded-xl border border-white/10 bg-black/60 px-3.5 py-2 text-xs text-white focus:border-accentCyan focus:outline-none"
            >
              <option value="All">All Exams</option>
              <option value="ssc">SSC CGL</option>
              <option value="upsc">UPSC CSE</option>
              <option value="ibps">IBPS PO</option>
              <option value="rrb">RRB Railways</option>
              <option value="gate">GATE Engineering</option>
            </select>
            <button
              onClick={loadResources}
              className="rounded-xl border border-white/10 bg-white/5 px-3.5 py-2 text-xs font-semibold text-white/80 hover:bg-white/10"
            >
              🔄 Refresh
            </button>
          </div>
        </div>

        {/* Directory Table */}
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="border-b border-white/10 bg-white/[0.02] text-white/50 uppercase">
              <tr>
                <th className="px-4 py-3">Exam Target</th>
                <th className="px-4 py-3">Subject / Topic</th>
                <th className="px-4 py-3">Content Title</th>
                <th className="px-4 py-3">Type</th>
                <th className="px-4 py-3">Status</th>
                <th className="px-4 py-3 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/5 text-white/80">
              {loading && resources.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-4 py-8 text-center text-white/40">
                    Loading preparation resources…
                  </td>
                </tr>
              ) : filtered.length > 0 ? (
                filtered.map((item) => (
                  <tr key={item.id} className="hover:bg-white/[0.02]">
                    <td className="px-4 py-3 font-semibold text-white uppercase">{item.examId}</td>
                    <td className="px-4 py-3 text-accentCyan font-medium">
                      {item.subject} <span className="text-white/40">({item.topic})</span>
                    </td>
                    <td className="px-4 py-3 font-medium text-white/90">{item.title}</td>
                    <td className="px-4 py-3">
                      <span className={`rounded px-2 py-0.5 font-bold ${item.contentType === "VIDEO" ? "bg-purple-500/20 text-purple-300" : "bg-amber-500/20 text-amber-300"}`}>
                        {item.contentType}
                      </span>
                    </td>
                    <td className="px-4 py-3">
                      <span className="rounded bg-emerald-500/20 px-2 py-0.5 text-xs font-bold text-emerald-400 border border-emerald-500/30">
                        Published
                      </span>
                    </td>
                    <td className="px-4 py-3 text-right space-x-2">
                      {item.fileUrl && (
                        <a
                          href={item.fileUrl}
                          target="_blank"
                          rel="noreferrer"
                          className="inline-flex items-center rounded-lg bg-accentBlue/20 px-3 py-1 text-xs font-semibold text-accentCyan hover:bg-accentBlue/30 border border-accentBlue/40"
                        >
                          View S3 Media ↗
                        </a>
                      )}
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={6} className="px-4 py-12 text-center text-white/40">
                    No preparation content uploaded yet. Upload a video or PDF above to start!
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
