"use client";

import { useEffect, useState, useRef } from "react";
import Link from "next/link";

interface CompetitiveExamItem {
  id: string;
  examId: string;
  examName: string;
  category: "ENGINEERING" | "CIVIL_SERVICES" | "PLACEMENTS" | "HIGHER_STUDIES" | "BANKING_SSC";
  title: string;
  subject: string;
  unit?: string;
  contentType: "NOTES" | "PYQ_PAPER" | "FORMULA_SHEET" | "MOCK_TEST" | "VIDEO_LECTURE" | "SYLLABUS";
  year: number;
  difficulty: "BEGINNER" | "INTERMEDIATE" | "ADVANCED" | "ALL_LEVELS";
  fileUrl: string;
  s3Key?: string;
  fileSize?: string;
  description?: string;
  author?: string;
  syllabusUrl?: string;
  examDate?: string;
  isFeatured?: boolean;
  downloadsCount?: number;
  uploadedAt: string;
}

const EXAM_PRESETS = [
  { id: "gate-cs-2026", name: "GATE Computer Science & IT (2026)", category: "ENGINEERING", examDate: "Feb 07, 2026", syllabusUrl: "https://gate2026.iitkgp.ac.in" },
  { id: "gate-ece-2026", name: "GATE Electronics & Communication (2026)", category: "ENGINEERING", examDate: "Feb 08, 2026", syllabusUrl: "https://gate2026.iitkgp.ac.in" },
  { id: "gate-mech-2026", name: "GATE Mechanical Engineering (2026)", category: "ENGINEERING", examDate: "Feb 14, 2026", syllabusUrl: "https://gate2026.iitkgp.ac.in" },
  { id: "upsc-cse-2026", name: "UPSC Civil Services Examination (IAS/IPS 2026)", category: "CIVIL_SERVICES", examDate: "May 24, 2026", syllabusUrl: "https://upsc.gov.in" },
  { id: "tcs-nqt-2026", name: "TCS NQT & IT Campus Placement Kit (2026)", category: "PLACEMENTS", examDate: "Nov 2025 - Jan 2026", syllabusUrl: "https://learning.tcsionhub.in" },
  { id: "infosys-prep-2026", name: "Infosys InfyTQ & Tech Placement Prep", category: "PLACEMENTS", examDate: "Dec 2025", syllabusUrl: "https://infytq.onwingspan.com" },
  { id: "maang-dsa-2026", name: "Product Companies & MAANG DSA Master Kit", category: "PLACEMENTS", examDate: "Continuous 2026", syllabusUrl: "https://leetcode.com" },
  { id: "cat-2026", name: "CAT (IIMs & Top Business Schools 2026)", category: "HIGHER_STUDIES", examDate: "Nov 30, 2025", syllabusUrl: "https://iimcat.ac.in" },
  { id: "gre-2026", name: "GRE / TOEFL Global Higher Studies Prep", category: "HIGHER_STUDIES", examDate: "Continuous 2026", syllabusUrl: "https://ets.org/gre" },
  { id: "ssc-cgl-2026", name: "SSC CGL & Banking PO Examination (2026)", category: "BANKING_SSC", examDate: "Sep 2026", syllabusUrl: "https://ssc.nic.in" },
];

const CATEGORIES = [
  { key: "ALL", label: "All Categories", icon: "🌐" },
  { key: "ENGINEERING", label: "Engineering & GATE", icon: "🚀" },
  { key: "CIVIL_SERVICES", label: "UPSC & Govt Services", icon: "🏛️" },
  { key: "PLACEMENTS", label: "Placements & Coding", icon: "💼" },
  { key: "HIGHER_STUDIES", label: "CAT & Higher Studies", icon: "🎓" },
  { key: "BANKING_SSC", label: "Banking & SSC", icon: "🏦" },
];

const CONTENT_TYPES = [
  { key: "ALL", label: "All Formats" },
  { key: "NOTES", label: "📑 Comprehensive Notes" },
  { key: "PYQ_PAPER", label: "📝 Solved PYQs" },
  { key: "FORMULA_SHEET", label: "⚡ Formula Sheets" },
  { key: "MOCK_TEST", label: "🎯 Mock Tests" },
  { key: "SYLLABUS", label: "📌 Official Syllabus" },
];

export default function AdminCompetitiveExamsPage() {
  const [activeTab, setActiveTab] = useState<"library" | "upload">("library");
  const [items, setItems] = useState<CompetitiveExamItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState("");
  const [categoryFilter, setCategoryFilter] = useState("ALL");
  const [typeFilter, setTypeFilter] = useState("ALL");
  const [message, setMessage] = useState<{ type: "success" | "error"; text: string } | null>(null);

  // Upload Form State
  const fileInputRef = useRef<HTMLInputElement | null>(null);
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [uploadProgress, setUploadProgress] = useState<number | null>(null);
  const [uploadForm, setUploadForm] = useState({
    presetId: "gate-cs-2026",
    examName: "GATE Computer Science & IT (2026)",
    category: "ENGINEERING" as any,
    title: "",
    subject: "Computer Networks & Operating Systems",
    contentType: "PYQ_PAPER" as any,
    year: 2026,
    difficulty: "INTERMEDIATE" as any,
    fileUrl: "",
    fileSize: "4.5 MB",
    description: "",
    author: "MyVault Academic Team",
    syllabusUrl: "https://gate2026.iitkgp.ac.in",
    examDate: "Feb 07, 2026",
    isFeatured: true,
  });

  const fetchData = async () => {
    try {
      setLoading(true);
      const res = await fetch("/api/admin/competitive-exams");
      if (res.ok) {
        const data = await res.json();
        if (Array.isArray(data)) setItems(data);
      }
    } catch (_) {
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  const handlePresetChange = (presetId: string) => {
    const found = EXAM_PRESETS.find(p => p.id === presetId);
    if (found) {
      setUploadForm(prev => ({
        ...prev,
        presetId: found.id,
        examName: found.name,
        category: found.category as any,
        syllabusUrl: found.syllabusUrl,
        examDate: found.examDate,
      }));
    }
  };

  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setSelectedFile(file);

    try {
      setUploadProgress(15);
      const presignRes = await fetch("/api/admin/uploads/presign", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          filename: file.name,
          contentType: file.type || "application/pdf",
          folder: "exams/" + uploadForm.presetId,
        }),
      });

      if (!presignRes.ok) throw new Error("Could not get upload URL");
      const { uploadUrl, publicUrl, s3Key } = await presignRes.json();

      setUploadProgress(50);
      const uploadRes = await fetch(uploadUrl, {
        method: "PUT",
        headers: { "Content-Type": file.type || "application/pdf" },
        body: file,
      });

      if (!uploadRes.ok) throw new Error("S3 Upload Failed");
      setUploadProgress(100);

      const sizeStr = (file.size / (1024 * 1024)).toFixed(1) + " MB";
      setUploadForm(prev => ({
        ...prev,
        fileUrl: publicUrl,
        fileSize: sizeStr,
        title: prev.title || file.name.replace(/\.[^/.]+$/, "").replace(/[-_]/g, " "),
      }));
      setMessage({ type: "success", text: "File uploaded to S3 successfully: " + file.name });
    } catch (err: any) {
      setUploadProgress(null);
      setMessage({ type: "error", text: "File upload failed. You can paste a direct PDF URL instead." });
    }
  };

  const handleSaveMaterial = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!uploadForm.title) {
      setMessage({ type: "error", text: "Material title is required." });
      return;
    }
    if (!uploadForm.fileUrl) {
      setMessage({ type: "error", text: "Please upload a PDF file or provide a direct document URL." });
      return;
    }

    try {
      const payload = {
        examId: uploadForm.presetId,
        examName: uploadForm.examName,
        category: uploadForm.category,
        title: uploadForm.title,
        subject: uploadForm.subject,
        contentType: uploadForm.contentType,
        year: Number(uploadForm.year),
        difficulty: uploadForm.difficulty,
        fileUrl: uploadForm.fileUrl,
        fileSize: uploadForm.fileSize || "3.5 MB",
        description: uploadForm.description || ("Study material and resources for " + uploadForm.examName + "."),
        author: uploadForm.author || "MyVault Faculty",
        syllabusUrl: uploadForm.syllabusUrl,
        examDate: uploadForm.examDate,
        isFeatured: uploadForm.isFeatured,
      };

      const res = await fetch("/api/admin/competitive-exams", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });

      if (res.ok) {
        const created = await res.json();
        setItems(prev => [created, ...prev]);
        setMessage({ type: "success", text: "🎉 Published " + created.title + " successfully!" });
        setActiveTab("library");
        setSelectedFile(null);
        setUploadProgress(null);
      }
    } catch (_) {
      setMessage({ type: "error", text: "Failed to publish exam material." });
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm("Are you sure you want to delete this preparation resource?")) return;
    try {
      await fetch("/api/admin/competitive-exams?id=" + id, { method: "DELETE" });
      setItems(prev => prev.filter(i => i.id !== id));
      setMessage({ type: "success", text: "Resource deleted successfully." });
    } catch (_) {
      setMessage({ type: "error", text: "Failed to delete resource." });
    }
  };

  const filteredItems = items.filter(item => {
    const matchesCat = categoryFilter === "ALL" || item.category === categoryFilter;
    const matchesType = typeFilter === "ALL" || item.contentType === typeFilter;
    const matchesQuery =
      item.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      item.examName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      item.subject.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (item.author && item.author.toLowerCase().includes(searchQuery.toLowerCase()));
    return matchesCat && matchesType && matchesQuery;
  });

  const totalPYQs = items.filter(i => i.contentType === "PYQ_PAPER").length;
  const totalFormulas = items.filter(i => i.contentType === "FORMULA_SHEET").length;
  const totalMocks = items.filter(i => i.contentType === "MOCK_TEST").length;

  return (
    <div className="mx-auto max-w-7xl px-6 py-10">
      {/* Header */}
      <div className="mb-8 flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="bg-gradient-to-r from-orange-400 via-accentCyan to-accentBlue bg-clip-text text-2xl font-extrabold text-transparent flex items-center gap-2">
            <span>🎯</span> Competitive Exams & Preparation Hub Studio
          </h1>
          <p className="mt-1 text-sm text-white/50">
            Publish GATE, UPSC, IT Placement Kits, CAT, and Govt Exam study materials directly to the Student Mobile App.
          </p>
        </div>
        <div className="flex items-center gap-3">
          <button
            onClick={() => setActiveTab(activeTab === "upload" ? "library" : "upload")}
            className="inline-flex items-center gap-2 rounded-xl bg-gradient-to-r from-orange-500 to-amber-400 px-4 py-2 text-xs font-bold text-black hover:opacity-90 transition shadow-lg shadow-orange-500/20"
          >
            <span>{activeTab === "upload" ? "📋 View Library" : "➕ Upload Exam Material"}</span>
          </button>
        </div>
      </div>

      {message && (
        <div className={"mb-6 rounded-xl px-4 py-3 text-xs font-semibold border flex items-center justify-between " + (message.type === "success" ? "bg-emerald-500/10 text-emerald-300 border-emerald-500/30" : "bg-red-500/10 text-red-300 border-red-500/30")}>
          <span>{message.text}</span>
          <button onClick={() => setMessage(null)} className="opacity-70 hover:opacity-100">✕</button>
        </div>
      )}

      {/* Metrics Row */}
      <div className="mb-8 grid grid-cols-2 gap-4 sm:grid-cols-4">
        <div className="rounded-2xl border border-white/10 bg-gradient-to-br from-orange-500/10 to-amber-500/10 p-5 backdrop-blur-xl">
          <div className="flex items-center justify-between">
            <span className="text-2xl">📚</span>
            <span className="text-2xl font-black text-orange-400">{items.length}</span>
          </div>
          <p className="mt-2 text-xs font-bold text-white/90">Total Exam Resources</p>
          <p className="text-[10px] text-white/50">Across All Competitive Streams</p>
        </div>
        <div className="rounded-2xl border border-white/10 bg-gradient-to-br from-cyan-500/10 to-blue-500/10 p-5 backdrop-blur-xl">
          <div className="flex items-center justify-between">
            <span className="text-2xl">📝</span>
            <span className="text-2xl font-black text-accentCyan">{totalPYQs}</span>
          </div>
          <p className="mt-2 text-xs font-bold text-white/90">Solved PYQ Banks</p>
          <p className="text-[10px] text-white/50">Past 10 Years Solved Papers</p>
        </div>
        <div className="rounded-2xl border border-white/10 bg-gradient-to-br from-purple-500/10 to-pink-500/10 p-5 backdrop-blur-xl">
          <div className="flex items-center justify-between">
            <span className="text-2xl">⚡</span>
            <span className="text-2xl font-black text-purple-400">{totalFormulas}</span>
          </div>
          <p className="mt-2 text-xs font-bold text-white/90">Formula Handbooks</p>
          <p className="text-[10px] text-white/50">High-Yield Fast Revision</p>
        </div>
        <div className="rounded-2xl border border-white/10 bg-gradient-to-br from-emerald-500/10 to-teal-500/10 p-5 backdrop-blur-xl">
          <div className="flex items-center justify-between">
            <span className="text-2xl">🎯</span>
            <span className="text-2xl font-black text-emerald-400">{totalMocks}</span>
          </div>
          <p className="mt-2 text-xs font-bold text-white/90">Mock Test Question Sets</p>
          <p className="text-[10px] text-white/50">Full Length & Topic Wise</p>
        </div>
      </div>

      {activeTab === "upload" && (
        <div className="mx-auto max-w-3xl rounded-2xl border border-white/10 bg-white/[0.02] p-8 backdrop-blur-xl mb-10">
          <div className="flex items-center justify-between border-b border-white/10 pb-4 mb-6">
            <div>
              <h2 className="text-lg font-bold text-white">Publish Exam Preparation Material</h2>
              <p className="text-xs text-white/50">Upload PDFs, PYQ sets, formula sheets, or link external study guides.</p>
            </div>
            <button
              onClick={() => setActiveTab("library")}
              className="text-xs text-white/60 hover:text-white"
            >
              ✕ Close
            </button>
          </div>

          <form onSubmit={handleSaveMaterial} className="space-y-5">
            {/* Target Exam Presets */}
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="mb-1 block text-xs font-medium text-white/80">Target Competitive Exam *</label>
                <select
                  value={uploadForm.presetId}
                  onChange={e => handlePresetChange(e.target.value)}
                  className="w-full rounded-xl border border-white/10 bg-black/50 px-3 py-2 text-sm text-white focus:border-orange-400 focus:outline-none"
                >
                  {EXAM_PRESETS.map(p => (
                    <option key={p.id} value={p.id}>{p.name}</option>
                  ))}
                </select>
              </div>
              <div>
                <label className="mb-1 block text-xs font-medium text-white/80">Category Stream</label>
                <select
                  value={uploadForm.category}
                  onChange={e => setUploadForm({ ...uploadForm, category: e.target.value as any })}
                  className="w-full rounded-xl border border-white/10 bg-black/50 px-3 py-2 text-sm text-white focus:border-orange-400 focus:outline-none"
                >
                  <option value="ENGINEERING">🚀 Engineering & GATE</option>
                  <option value="CIVIL_SERVICES">🏛️ UPSC & Civil Services</option>
                  <option value="PLACEMENTS">💼 Tech Placements & Coding</option>
                  <option value="HIGHER_STUDIES">🎓 CAT & Global Studies (GRE)</option>
                  <option value="BANKING_SSC">🏦 Banking PO & SSC</option>
                </select>
              </div>
            </div>

            {/* Title & Subject */}
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="mb-1 block text-xs font-medium text-white/80">Material Title *</label>
                <input
                  type="text"
                  required
                  placeholder="e.g. GATE CS 10-Year Solved PYQ Question Bank"
                  value={uploadForm.title}
                  onChange={e => setUploadForm({ ...uploadForm, title: e.target.value })}
                  className="w-full rounded-xl border border-white/10 bg-black/50 px-3.5 py-2 text-sm text-white focus:border-orange-400 focus:outline-none"
                />
              </div>
              <div>
                <label className="mb-1 block text-xs font-medium text-white/80">Subject / Module Topics</label>
                <input
                  type="text"
                  placeholder="e.g. Algorithms, Data Structures & Discrete Math"
                  value={uploadForm.subject}
                  onChange={e => setUploadForm({ ...uploadForm, subject: e.target.value })}
                  className="w-full rounded-xl border border-white/10 bg-black/50 px-3.5 py-2 text-sm text-white focus:border-orange-400 focus:outline-none"
                />
              </div>
            </div>

            {/* Content Type & Year & Difficulty */}
            <div className="grid grid-cols-3 gap-4">
              <div>
                <label className="mb-1 block text-xs font-medium text-white/80">Material Format</label>
                <select
                  value={uploadForm.contentType}
                  onChange={e => setUploadForm({ ...uploadForm, contentType: e.target.value as any })}
                  className="w-full rounded-xl border border-white/10 bg-black/50 px-3 py-2 text-sm text-white focus:border-orange-400 focus:outline-none"
                >
                  <option value="PYQ_PAPER">📝 Solved PYQ Paper</option>
                  <option value="NOTES">📑 Theory Notes & Guide</option>
                  <option value="FORMULA_SHEET">⚡ Formula & Cheat Sheet</option>
                  <option value="MOCK_TEST">🎯 Mock Test & Solutions</option>
                  <option value="SYLLABUS">📌 Official Syllabus</option>
                </select>
              </div>
              <div>
                <label className="mb-1 block text-xs font-medium text-white/80">Target Exam Year</label>
                <input
                  type="number"
                  value={uploadForm.year}
                  onChange={e => setUploadForm({ ...uploadForm, year: Number(e.target.value) })}
                  className="w-full rounded-xl border border-white/10 bg-black/50 px-3.5 py-2 text-sm text-white focus:border-orange-400 focus:outline-none"
                />
              </div>
              <div>
                <label className="mb-1 block text-xs font-medium text-white/80">Difficulty Level</label>
                <select
                  value={uploadForm.difficulty}
                  onChange={e => setUploadForm({ ...uploadForm, difficulty: e.target.value as any })}
                  className="w-full rounded-xl border border-white/10 bg-black/50 px-3 py-2 text-sm text-white focus:border-orange-400 focus:outline-none"
                >
                  <option value="ALL_LEVELS">All Levels</option>
                  <option value="BEGINNER">Beginner Friendly</option>
                  <option value="INTERMEDIATE">Intermediate</option>
                  <option value="ADVANCED">Advanced / High Difficulty</option>
                </select>
              </div>
            </div>

            {/* PDF File Upload Zone */}
            <div>
              <label className="mb-1 block text-xs font-medium text-white/80">Upload PDF Document (to AWS S3) *</label>
              <div
                onClick={() => fileInputRef.current?.click()}
                className="cursor-pointer rounded-2xl border-2 border-dashed border-white/20 bg-black/30 p-6 text-center hover:border-orange-400 transition"
              >
                <input
                  ref={fileInputRef}
                  type="file"
                  accept=".pdf,.doc,.docx"
                  onChange={handleFileUpload}
                  className="hidden"
                />
                <div className="text-3xl mb-2">📄</div>
                <p className="text-xs font-semibold text-white">
                  {selectedFile ? selectedFile.name : "Click to select and upload PDF from your computer"}
                </p>
                <p className="text-[10px] text-white/40 mt-1">Supports PDF, DOCX up to 50MB</p>
                {uploadProgress !== null && (
                  <div className="mt-3">
                    <div className="h-1.5 w-full rounded-full bg-white/10 overflow-hidden">
                      <div className="h-full bg-orange-400 transition-all duration-300" style={{ width: `${uploadProgress}%` }} />
                    </div>
                    <span className="text-[10px] text-orange-400 font-bold mt-1 inline-block">Uploading: {uploadProgress}%</span>
                  </div>
                )}
              </div>
            </div>

            {/* Direct Document URL fallback */}
            <div>
              <label className="mb-1 block text-xs font-medium text-white/80">Or Direct Document / S3 URL</label>
              <input
                type="url"
                placeholder="https://myvault-files-app.s3.eu-north-1.amazonaws.com/exams/..."
                value={uploadForm.fileUrl}
                onChange={e => setUploadForm({ ...uploadForm, fileUrl: e.target.value })}
                className="w-full rounded-xl border border-white/10 bg-black/50 px-3.5 py-2 text-sm text-white focus:border-orange-400 focus:outline-none font-mono"
              />
            </div>

            {/* Additional Meta: Author, Syllabus URL, Exam Date */}
            <div className="grid grid-cols-3 gap-4">
              <div>
                <label className="mb-1 block text-xs font-medium text-white/80">Author / Faculty Credit</label>
                <input
                  type="text"
                  placeholder="e.g. Gateforum & IIT Alumni"
                  value={uploadForm.author}
                  onChange={e => setUploadForm({ ...uploadForm, author: e.target.value })}
                  className="w-full rounded-xl border border-white/10 bg-black/50 px-3.5 py-2 text-sm text-white focus:border-orange-400 focus:outline-none"
                />
              </div>
              <div>
                <label className="mb-1 block text-xs font-medium text-white/80">Official Syllabus URL</label>
                <input
                  type="url"
                  placeholder="https://gate2026.iitkgp.ac.in"
                  value={uploadForm.syllabusUrl}
                  onChange={e => setUploadForm({ ...uploadForm, syllabusUrl: e.target.value })}
                  className="w-full rounded-xl border border-white/10 bg-black/50 px-3.5 py-2 text-sm text-white focus:border-orange-400 focus:outline-none font-mono"
                />
              </div>
              <div>
                <label className="mb-1 block text-xs font-medium text-white/80">Exam Date / Window</label>
                <input
                  type="text"
                  placeholder="e.g. Feb 07, 2026"
                  value={uploadForm.examDate}
                  onChange={e => setUploadForm({ ...uploadForm, examDate: e.target.value })}
                  className="w-full rounded-xl border border-white/10 bg-black/50 px-3.5 py-2 text-sm text-white focus:border-orange-400 focus:outline-none"
                />
              </div>
            </div>

            <div className="flex items-center gap-2 pt-2">
              <input
                type="checkbox"
                id="isFeatured"
                checked={uploadForm.isFeatured}
                onChange={e => setUploadForm({ ...uploadForm, isFeatured: e.target.checked })}
                className="h-4 w-4 rounded accent-orange-500"
              />
              <label htmlFor="isFeatured" className="text-xs text-white/80 font-medium cursor-pointer">
                ⭐ Pin as Featured / Recommended Study Material on Mobile Home Screen
              </label>
            </div>

            <div className="flex items-center justify-end gap-3 pt-4 border-t border-white/10">
              <button
                type="button"
                onClick={() => setActiveTab("library")}
                className="rounded-xl border border-white/10 px-4 py-2 text-xs font-semibold text-white/70 hover:bg-white/5"
              >
                Cancel
              </button>
              <button
                type="submit"
                className="rounded-xl bg-gradient-to-r from-orange-500 to-amber-400 px-6 py-2.5 text-xs font-black text-black hover:opacity-90 transition shadow-lg shadow-orange-500/20"
              >
                🚀 Publish Material to Mobile App
              </button>
            </div>
          </form>
        </div>
      )}

      {/* Filter & Search Bar */}
      <div className="mb-6 space-y-3 border-b border-white/10 pb-6">
        {/* Category Pills */}
        <div className="flex flex-wrap items-center gap-2">
          {CATEGORIES.map(c => (
            <button
              key={c.key}
              onClick={() => setCategoryFilter(c.key)}
              className={"flex items-center gap-1.5 rounded-xl px-3.5 py-1.5 text-xs font-bold transition border " + (categoryFilter === c.key ? "bg-orange-500 text-black border-orange-400 shadow-lg shadow-orange-500/20" : "bg-white/5 text-white/70 border-white/10 hover:bg-white/10 hover:text-white")}
            >
              <span>{c.icon}</span>
              <span>{c.label}</span>
            </button>
          ))}
        </div>

        {/* Sub-Filters: Content Type + Search */}
        <div className="flex flex-wrap items-center justify-between gap-4">
          <div className="flex flex-wrap items-center gap-2">
            {CONTENT_TYPES.map(t => (
              <button
                key={t.key}
                onClick={() => setTypeFilter(t.key)}
                className={"rounded-lg px-2.5 py-1 text-[11px] font-semibold transition " + (typeFilter === t.key ? "bg-accentCyan text-black font-bold" : "bg-white/5 text-white/60 hover:bg-white/10 hover:text-white")}
              >
                {t.label}
              </button>
            ))}
          </div>
          <input
            type="text"
            placeholder="Search exam, topic, author..."
            value={searchQuery}
            onChange={e => setSearchQuery(e.target.value)}
            className="rounded-xl border border-white/10 bg-black/50 px-3.5 py-1.5 text-xs text-white placeholder-white/40 focus:border-orange-400 focus:outline-none w-64"
          />
        </div>
      </div>

      {/* Published Exam Resources Grid */}
      <div className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3">
        {filteredItems.map(item => (
          <div
            key={item.id}
            className="rounded-2xl border border-white/10 bg-white/[0.02] p-5 backdrop-blur-xl flex flex-col justify-between hover:border-white/20 transition-all"
          >
            <div>
              <div className="flex items-start justify-between gap-3 mb-2">
                <span className={"rounded-full px-2.5 py-0.5 text-[10px] font-bold border " + (item.category === "ENGINEERING" ? "bg-blue-500/20 text-blue-300 border-blue-500/30" : item.category === "CIVIL_SERVICES" ? "bg-amber-500/20 text-amber-300 border-amber-500/30" : item.category === "PLACEMENTS" ? "bg-emerald-500/20 text-emerald-300 border-emerald-500/30" : "bg-purple-500/20 text-purple-300 border-purple-500/30")}>
                  {item.category.replace("_", " ")}
                </span>
                <span className="rounded-md bg-white/10 px-2 py-0.5 text-[10px] font-mono text-white/70">
                  {item.contentType.replace("_", " ")}
                </span>
              </div>

              <h3 className="text-sm font-bold text-white line-clamp-2 mb-1">{item.title}</h3>
              <p className="text-xs text-orange-400 font-semibold mb-2">{item.examName}</p>

              <div className="space-y-1 text-[11px] text-white/60 mb-3 bg-black/30 p-2.5 rounded-xl border border-white/5">
                <div><span className="text-white/40">Topic:</span> <span className="text-white/90 font-medium">{item.subject}</span></div>
                <div><span className="text-white/40">Credit:</span> <span className="text-white/80">{item.author || "Faculty"}</span></div>
                {item.examDate && <div><span className="text-white/40">Exam Date:</span> <span className="text-emerald-400 font-bold">{item.examDate}</span></div>}
              </div>

              {item.description && (
                <p className="text-xs text-white/50 line-clamp-2 mb-3">{item.description}</p>
              )}
            </div>

            <div className="pt-3 border-t border-white/10 flex items-center justify-between text-xs">
              <span className="text-[11px] text-white/40 font-mono">
                📦 {item.fileSize || "PDF"}
              </span>
              <div className="flex items-center gap-2">
                {item.syllabusUrl && (
                  <a
                    href={item.syllabusUrl}
                    target="_blank"
                    rel="noreferrer"
                    className="rounded-lg bg-white/5 px-2 py-1 text-[11px] font-semibold text-white/70 hover:bg-white/10 flex items-center gap-1"
                  >
                    Syllabus ↗
                  </a>
                )}
                <a
                  href={item.fileUrl}
                  target="_blank"
                  rel="noreferrer"
                  className="rounded-lg bg-orange-500/20 px-2.5 py-1 text-xs font-bold text-orange-300 border border-orange-500/40 hover:bg-orange-500/30 flex items-center gap-1"
                >
                  👁️ Open PDF ↗
                </a>
                <button
                  onClick={() => handleDelete(item.id)}
                  className="rounded-lg bg-red-500/20 px-2 py-1 text-xs font-semibold text-red-300 border border-red-500/30 hover:bg-red-500/30"
                >
                  ✕
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>

      {filteredItems.length === 0 && !loading && (
        <div className="rounded-2xl border border-white/10 bg-white/[0.02] p-12 text-center text-white/40">
          <span className="text-4xl block mb-2">🔍</span>
          No competitive exam materials found matching your filters.
        </div>
      )}
    </div>
  );
}
