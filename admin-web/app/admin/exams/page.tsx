"use client";

import { useState, useEffect, useCallback } from "react";
import { UploadForm, type UploadFormConfig } from "@/components/admin/UploadForm";

interface ExamResource {
  id: string;
  examName: string;
  contentType: "VIDEO" | "PDF" | "SYLLABUS";
  title: string;
  subject: string;
  duration?: string;
  fileUrl: string;
  uploadedAt?: string;
}

const STORAGE_KEY = "myvault_uploaded_exams_v1";

const CATEGORIES = [
  "All",
  "Government",
  "Banking",
  "Railways",
  "Higher Education",
  "Management",
  "Professional",
];

export default function ExamsAdminPage() {
  const [resources, setResources] = useState<ExamResource[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedCategory, setSelectedCategory] = useState<string>("All");
  const [searchQuery, setSearchQuery] = useState<string>("");
  const [resourceFormat, setResourceFormat] = useState<"VIDEO" | "PDF" | "SYLLABUS">("VIDEO");

  // Dynamic accepted file types and S3 target folder based on selected Resource Format
  const acceptedFileTypes =
    resourceFormat === "VIDEO"
      ? "video/mp4, video/webm, video/x-matroska, video/*"
      : resourceFormat === "PDF"
      ? "application/pdf"
      : "application/pdf, .doc, .docx";

  const targetFolder =
    resourceFormat === "VIDEO"
      ? "exams/videos"
      : resourceFormat === "PDF"
      ? "exams/pdfs"
      : "exams/syllabus";

  const examConfig: UploadFormConfig = {
    domain: targetFolder,
    confirmPath: "/admin/exams/confirm",
    acceptedFileTypes: acceptedFileTypes,
    requireFile: true,
    successMessage: `Competitive Exam ${resourceFormat} uploaded successfully to AWS S3 (${targetFolder}/) & synced with Mobile App.`,
    fields: [
      {
        name: "examName",
        label: "Target Competitive Exam *",
        type: "select",
        required: true,
        options: [
          { value: "UPSC Civil Services (IAS / IPS / IFS)", label: "🏛️ UPSC Civil Services (IAS / IPS / IFS)" },
          { value: "SSC CGL (Staff Selection Commission)", label: "🏛️ SSC CGL (Staff Selection Commission)" },
          { value: "SBI PO / IBPS PO & Clerk", label: "🏦 SBI PO / IBPS PO & Clerk (Banking)" },
          { value: "RRB NTPC & Railway JE", label: "🚆 RRB NTPC & Railway JE" },
          { value: "JEE Main / Advanced (Engineering)", label: "🎓 JEE Main / Advanced (Engineering Entrance)" },
          { value: "NEET-UG (Medical Entrance)", label: "🩺 NEET-UG (Medical Entrance)" },
          { value: "GATE (Engineering & PSUs)", label: "⚡ GATE (Engineering & PSUs)" },
          { value: "CAT / XAT (Management)", label: "💼 CAT / XAT (IIMs & B-Schools)" },
          { value: "CA (Chartered Accountant)", label: "📊 CA (Chartered Accountant Qualification)" },
        ],
      },
      {
        name: "contentType",
        label: "Resource Format *",
        type: "select",
        required: true,
        options: [
          { value: "VIDEO", label: "🎬 S3 Video Lecture Stream (Accepts: video/mp4, video/webm)" },
          { value: "PDF", label: "📄 PDF Study Material / Solved PYQ Handout (Accepts: application/pdf)" },
          { value: "SYLLABUS", label: "📜 Syllabus & Selection Roadmap (Accepts: application/pdf, .doc)" },
        ],
      },
      { name: "title", label: "Lecture / Document Title *", type: "text", required: true, placeholder: "e.g. Indian Polity Laxmikanth Masterclass & Solved PYQs" },
      { name: "subject", label: "Subject / Module Topic *", type: "text", required: true, placeholder: "e.g. Indian Polity / Quantitative Aptitude / Biology" },
      { name: "duration", label: "Video Duration (optional, e.g. 25:00)", type: "text", required: false, placeholder: "e.g. 25:00" },
      { name: "publicUrl", label: "External S3 Media Stream URL / Direct Link (optional)", type: "text", required: false, placeholder: "https://myvault-files-app.s3.eu-north-1.amazonaws.com/lecture.mp4" },
    ],
  };

  const loadResources = useCallback(async () => {
    setLoading(true);
    let localItems: ExamResource[] = [];
    if (typeof window !== "undefined") {
      try {
        const saved = localStorage.getItem(STORAGE_KEY);
        if (saved) localItems = JSON.parse(saved);
      } catch (_) {}
    }

    try {
      const response = await fetch("/api/exams");
      if (response.ok) {
        const res = await response.json();
        const apiList: ExamResource[] = [];
        if (Array.isArray(res)) {
          res.forEach((exam: any) => {
            (exam.videos || []).forEach((v: any) => {
              apiList.push({
                id: v.id,
                examName: exam.name,
                contentType: "VIDEO",
                title: v.title,
                subject: v.subject || "General",
                duration: v.duration || "20:00",
                fileUrl: v.s3Url || v.pdfUrl || "",
                uploadedAt: new Date().toISOString(),
              });
            });
            (exam.pdfNotes || []).forEach((p: any) => {
              apiList.push({
                id: p.id,
                examName: exam.name,
                contentType: "PDF",
                title: p.title,
                subject: p.subject || "General",
                fileUrl: p.fileUrl || "",
                uploadedAt: new Date().toISOString(),
              });
            });
          });
        }

        const mergedMap = new Map<string, ExamResource>();
        localItems.forEach((item) => mergedMap.set(item.id, item));
        apiList.forEach((item) => {
          if (!mergedMap.has(item.id)) {
            mergedMap.set(item.id, item);
          }
        });

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
    const s3FileUrl =
      payload.publicUrl ||
      (file ? `https://myvault-files-app.s3.eu-north-1.amazonaws.com/${targetFolder}/${Date.now()}_${file.name.replace(/[^a-zA-Z0-9._-]/g, "_")}` : "") ||
      "https://myvault-files-app.s3.eu-north-1.amazonaws.com/app-arm64-v8a-release.apk";

    const newItem: ExamResource = {
      id: `local_res_${Date.now()}`,
      examName: payload.examName || "UPSC Civil Services (IAS / IPS / IFS)",
      contentType: (payload.contentType as any) || resourceFormat,
      title: payload.title || "Uploaded Resource",
      subject: payload.subject || "General Studies",
      duration: payload.duration || "20:00",
      fileUrl: s3FileUrl,
      uploadedAt: new Date().toISOString(),
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

  const filteredResources = resources.filter((r) => {
    const matchesSearch =
      r.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      r.subject.toLowerCase().includes(searchQuery.toLowerCase()) ||
      r.examName.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesSearch;
  });

  return (
    <div className="mx-auto max-w-6xl px-4 py-10">
      <div className="mb-8">
        <h1 className="bg-gradient-to-r from-accentBlue to-accentCyan bg-clip-text text-3xl font-black text-transparent">
          Competitive Exams Preparation Hub
        </h1>
        <p className="mt-1 text-sm text-white/60">
          Upload video lectures (.mp4, .webm), PDF notes (.pdf), solved question papers (PYQs), and syllabus roadmaps directly to AWS S3 storage for Mobile App aspirants.
        </p>
      </div>

      {/* Resource Format Switcher */}
      <div className="mb-6 flex flex-wrap items-center gap-3 rounded-2xl border border-white/10 bg-black/40 p-2 backdrop-blur-xl">
        <span className="text-xs font-bold text-white/70 px-3">Select Format Mode:</span>
        <button
          onClick={() => setResourceFormat("VIDEO")}
          className={`flex items-center gap-2 rounded-xl px-4 py-2 text-xs font-bold transition ${
            resourceFormat === "VIDEO" ? "bg-accentBlue text-white shadow-lg shadow-accentBlue/20" : "text-white/60 hover:text-white"
          }`}
        >
          🎬 Video Lecture Stream (video/mp4)
        </button>
        <button
          onClick={() => setResourceFormat("PDF")}
          className={`flex items-center gap-2 rounded-xl px-4 py-2 text-xs font-bold transition ${
            resourceFormat === "PDF" ? "bg-accentBlue text-white shadow-lg shadow-accentBlue/20" : "text-white/60 hover:text-white"
          }`}
        >
          📄 PDF Notes & PYQ (application/pdf)
        </button>
        <button
          onClick={() => setResourceFormat("SYLLABUS")}
          className={`flex items-center gap-2 rounded-xl px-4 py-2 text-xs font-bold transition ${
            resourceFormat === "SYLLABUS" ? "bg-accentBlue text-white shadow-lg shadow-accentBlue/20" : "text-white/60 hover:text-white"
          }`}
        >
          📜 Syllabus & Roadmap (.pdf / .doc)
        </button>
      </div>

      {/* Upload Form Component */}
      <div className="mb-12 rounded-2xl border border-white/10 bg-white/[0.02] p-6 backdrop-blur-xl">
        <div className="mb-4 flex items-center justify-between">
          <h2 className="text-base font-bold text-white flex items-center gap-2">
            <span>📤 Upload Competitive Exam {resourceFormat === "VIDEO" ? "Video (.mp4)" : "PDF (.pdf)"} to S3 ({targetFolder}/)</span>
          </h2>
          <span className="rounded-full bg-cyan-400/10 px-3 py-1 text-xs font-semibold text-cyan-300 border border-cyan-400/20">
            Accepted: {acceptedFileTypes}
          </span>
        </div>
        <UploadForm key={resourceFormat} config={examConfig} onSuccess={handleFormSuccess} />
      </div>

      {/* Interactive Mobile App-Style Category Tabs & Search Bar */}
      <div className="mb-8 rounded-2xl border border-white/10 bg-white/[0.02] p-6 backdrop-blur-xl">
        <div className="mb-6 flex flex-wrap items-center justify-between gap-4">
          <div>
            <h2 className="text-xl font-extrabold text-white flex items-center gap-2">
              <span>🎓 Competitive Exam Directory & Materials ({filteredResources.length})</span>
            </h2>
            <p className="text-xs text-white/50">Everything uploaded streams live on the Mobile App</p>
          </div>

          <div className="flex flex-wrap items-center gap-3">
            <input
              type="text"
              placeholder="Search UPSC, SSC, Banking, JEE, NEET..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="rounded-xl border border-white/10 bg-black/60 px-4 py-2 text-xs text-white placeholder-white/40 focus:border-accentCyan focus:outline-none w-64"
            />
            <button
              onClick={loadResources}
              className="rounded-xl border border-white/10 bg-white/5 px-3.5 py-2 text-xs font-semibold text-white/80 hover:bg-white/10"
            >
              🔄 Refresh
            </button>
          </div>
        </div>

        {/* Category Filter Pills */}
        <div className="mb-6 flex flex-wrap gap-2 border-b border-white/10 pb-4">
          {CATEGORIES.map((cat) => (
            <button
              key={cat}
              onClick={() => setSelectedCategory(cat)}
              className={`rounded-xl px-3.5 py-1.5 text-xs font-semibold transition ${
                selectedCategory === cat
                  ? "bg-accentCyan text-black font-bold shadow-md shadow-accentCyan/20"
                  : "bg-white/5 text-white/70 hover:bg-white/10 hover:text-white"
              }`}
            >
              {cat}
            </button>
          ))}
        </div>

        {/* Uploaded Materials Management Table */}
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="border-b border-white/10 bg-white/[0.02] text-white/50 uppercase">
              <tr>
                <th className="px-4 py-3">Exam Target</th>
                <th className="px-4 py-3">Resource Format</th>
                <th className="px-4 py-3">Title</th>
                <th className="px-4 py-3">Subject / Topic</th>
                <th className="px-4 py-3 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/5 text-white/80">
              {loading && resources.length === 0 ? (
                <tr>
                  <td colSpan={5} className="px-4 py-8 text-center text-white/40">
                    Loading competitive exam materials…
                  </td>
                </tr>
              ) : filteredResources.length > 0 ? (
                filteredResources.map((item) => (
                  <tr key={item.id} className="hover:bg-white/[0.02]">
                    <td className="px-4 py-3 font-semibold text-white">{item.examName}</td>
                    <td className="px-4 py-3">
                      <span className={`rounded px-2 py-0.5 font-bold ${item.contentType === "VIDEO" ? "bg-purple-500/20 text-purple-300" : "bg-amber-500/20 text-amber-300"}`}>
                        {item.contentType === "VIDEO" ? "🎬 Video Stream" : "📄 PDF Document"}
                      </span>
                    </td>
                    <td className="px-4 py-3 font-medium text-white/90">{item.title}</td>
                    <td className="px-4 py-3 text-accentCyan font-medium">{item.subject}</td>
                    <td className="px-4 py-3 text-right space-x-2">
                      {item.fileUrl && (
                        <a
                          href={item.fileUrl}
                          target="_blank"
                          rel="noreferrer"
                          className="inline-flex items-center rounded-lg bg-accentBlue/20 px-3 py-1.5 text-xs font-semibold text-accentCyan hover:bg-accentBlue/30 border border-accentBlue/40"
                        >
                          Open S3 Media ↗
                        </a>
                      )}
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={5} className="px-4 py-12 text-center text-white/40">
                    No competitive exam materials uploaded yet. Upload a video or PDF above to start!
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
