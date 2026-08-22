"use client";

import { useState, useEffect, useCallback } from "react";
import { UploadForm, type UploadFormConfig } from "@/components/admin/UploadForm";

interface ExamMaterialResource {
  id: string;
  examId: string;
  subject: string;
  unit: string;
  contentType: "NOTES" | "VIDEO_LECTURE" | "LAB_MANUAL" | "CHEAT_SHEET" | "ASSIGNMENT" | "QUESTION_BANK" | "SYLLABUS";
  title: string;
  fileUrl: string;
  uploadedAt: string;
}

const STORAGE_KEY = "myvault_exam_academic_flow_v1";

const examNotesConfig: UploadFormConfig = {
  domain: "exams",
  confirmPath: "/admin/exams/confirm",
  acceptedFileTypes: "application/pdf,video/mp4",
  successMessage: "Competitive Exam Preparation Material published successfully — visible to students instantly in the Mobile App.",
  fields: [
    { name: "title", label: "Material Title", type: "text", required: true, placeholder: "e.g. Unit 3 — Percentage Concepts & Shortcut Methods" },
    {
      name: "examId",
      label: "Target Competitive Exam",
      type: "select",
      required: true,
      options: [
        { value: "upsc-cse-2026", label: "🏛️ UPSC Civil Services (IAS / IPS / IFS)" },
        { value: "ssc-cgl-2026", label: "📚 SSC CGL (Staff Selection Commission)" },
        { value: "ibps-po-2026", label: "🏦 SBI PO / IBPS PO & Clerk (Banking)" },
        { value: "rrb-ntpc-2026", label: "🚆 RRB NTPC & Railway JE" },
        { value: "gate-cse-2027", label: "⚡ GATE CSE (Engineering)" },
        { value: "jee-main-2026", label: "🎓 JEE Main / Advanced" },
        { value: "neet-ug-2026", label: "🩺 NEET-UG (Medical Entrance)" },
        { value: "cat-mba-2026", label: "💼 CAT / XAT (Management)" },
      ],
    },
    {
      name: "subject",
      label: "Subject Module",
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
    {
      name: "unit",
      label: "Unit Number",
      type: "select",
      required: true,
      options: [
        { value: "1", label: "Unit 1 — Fundamentals & Basic Concepts" },
        { value: "2", label: "Unit 2 — Core Methodology" },
        { value: "3", label: "Unit 3 — Advanced Problem Solving" },
        { value: "4", label: "Unit 4 — Practice Sets & Mock Drills" },
        { value: "5", label: "Unit 5 — Solved Previous Year Questions (PYQs)" },
      ],
    },
    {
      name: "contentType",
      label: "Material Category",
      type: "select",
      required: true,
      options: [
        { value: "NOTES", label: "📄 Lecture Notes & Study Material" },
        { value: "VIDEO_LECTURE", label: "🎬 Video Lecture Stream" },
        { value: "LAB_MANUAL", label: "🧪 Practice Set / Drill Sheet" },
        { value: "CHEAT_SHEET", label: "⚡ Formula Sheet & Cheat Sheet" },
        { value: "ASSIGNMENT", label: "📋 Homework & Practice Problems" },
        { value: "QUESTION_BANK", label: "📊 Question Bank & Solved PYQs" },
        { value: "SYLLABUS", label: "📜 Exam Syllabus & Selection Roadmap" },
      ],
    },
  ],
};

export default function ExamsAdminPage() {
  const [resources, setResources] = useState<ExamMaterialResource[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedExam, setSelectedExam] = useState<string>("All");
  const [selectedCategory, setSelectedCategory] = useState<string>("All");

  const loadResources = useCallback(async () => {
    setLoading(true);
    let localItems: ExamMaterialResource[] = [];
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
        const apiList: ExamMaterialResource[] = (res.data || []).map((item: any) => ({
          id: String(item.id),
          examId: item.examId || "upsc-cse-2026",
          subject: item.subject || "Quantitative Aptitude",
          unit: String(item.unit || "1"),
          contentType: item.contentType || "NOTES",
          title: item.title,
          fileUrl: item.fileUrl,
          uploadedAt: item.createdAt || new Date().toISOString(),
        }));

        const mergedMap = new Map<string, ExamMaterialResource>();
        localItems.forEach((item) => mergedMap.set(item.id, item));
        apiList.forEach((item) => mergedMap.set(item.id, item));
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
      (file ? `https://myvault-files-app.s3.eu-north-1.amazonaws.com/exams/${payload.examId || "general"}/${Date.now()}_${file.name.replace(/[^a-zA-Z0-9._-]/g, "_")}` : "") ||
      "https://myvault-files-app.s3.eu-north-1.amazonaws.com/app-arm64-v8a-release.apk";

    const newItem: ExamMaterialResource = {
      id: `local_exam_res_${Date.now()}`,
      examId: payload.examId || "upsc-cse-2026",
      subject: payload.subject || "Quantitative Aptitude",
      unit: String(payload.unit || "1"),
      contentType: payload.contentType || "NOTES",
      title: payload.title || "Uploaded Resource",
      fileUrl,
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

  const formatCategoryPill = (cat: string) => {
    switch (cat.toUpperCase()) {
      case "NOTES": return "📄 Lecture Notes";
      case "VIDEO_LECTURE": return "🎬 Video Lecture";
      case "LAB_MANUAL": return "🧪 Practice Set";
      case "CHEAT_SHEET": return "⚡ Formula Sheet";
      case "ASSIGNMENT": return "📋 Practice Homework";
      case "QUESTION_BANK": return "📊 Question Bank / PYQs";
      case "SYLLABUS": return "📜 Syllabus Roadmap";
      default: return cat;
    }
  };

  const filtered = resources.filter((r) => {
    const matchesExam = selectedExam === "All" || r.examId.toLowerCase().includes(selectedExam.toLowerCase());
    const matchesCat = selectedCategory === "All" || r.contentType === selectedCategory;
    return matchesExam && matchesCat;
  });

  return (
    <div className="mx-auto max-w-4xl px-4 py-10">
      <div className="mb-8">
        <h1 className="bg-gradient-to-r from-accentBlue to-accentCyan bg-clip-text text-2xl font-black text-transparent">
          Upload Competitive Exam Resources
        </h1>
        <p className="mt-1 text-sm text-white/50">
          Files upload directly to AWS S3 storage; students see them instantly under their selected exam, subject module, and unit (using Academic Hub flow).
        </p>
      </div>

      {/* Upload Form Component (Matching Academic Hub Flow) */}
      <div className="mb-12 rounded-2xl border border-white/10 bg-white/[0.02] p-6 backdrop-blur-xl">
        <UploadForm config={examNotesConfig} onSuccess={handleFormSuccess} />
      </div>

      {/* Uploaded Materials Table */}
      <div className="rounded-2xl border border-white/10 bg-white/[0.02] p-6 backdrop-blur-xl">
        <div className="mb-6 flex flex-wrap items-center justify-between gap-4">
          <div>
            <h2 className="text-lg font-bold text-white">📚 Published Exam Preparation Materials ({filtered.length})</h2>
            <p className="text-xs text-white/50">Students see these resources instantly in the Mobile App</p>
          </div>

          <div className="flex flex-wrap items-center gap-3">
            <select
              value={selectedExam}
              onChange={(e) => setSelectedExam(e.target.value)}
              className="rounded-xl border border-white/10 bg-black/60 px-3.5 py-1.5 text-xs text-white focus:border-accentCyan focus:outline-none"
            >
              <option value="All">Filter by Exam (All)</option>
              <option value="upsc">UPSC Civil Services</option>
              <option value="ssc">SSC CGL</option>
              <option value="ibps">SBI / IBPS Banking</option>
              <option value="rrb">RRB Railways</option>
              <option value="gate">GATE Engineering</option>
            </select>

            <select
              value={selectedCategory}
              onChange={(e) => setSelectedCategory(e.target.value)}
              className="rounded-xl border border-white/10 bg-black/60 px-3.5 py-1.5 text-xs text-white focus:border-accentCyan focus:outline-none"
            >
              <option value="All">Filter by Category (All)</option>
              <option value="NOTES">📄 Lecture Notes</option>
              <option value="VIDEO_LECTURE">🎬 Video Lecture</option>
              <option value="LAB_MANUAL">🧪 Practice Set</option>
              <option value="CHEAT_SHEET">⚡ Formula Sheet</option>
              <option value="QUESTION_BANK">📊 Question Bank / PYQs</option>
              <option value="SYLLABUS">📜 Syllabus Roadmap</option>
            </select>

            <button
              onClick={loadResources}
              className="rounded-xl border border-white/10 bg-white/5 px-3 py-1.5 text-xs font-semibold text-white/80 hover:bg-white/10"
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
                <th className="px-4 py-3">Subject / Unit</th>
                <th className="px-4 py-3">Title</th>
                <th className="px-4 py-3">Category</th>
                <th className="px-4 py-3 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/5 text-white/80">
              {loading && resources.length === 0 ? (
                <tr>
                  <td colSpan={5} className="px-4 py-8 text-center text-white/40">
                    Loading exam preparation materials…
                  </td>
                </tr>
              ) : filtered.length > 0 ? (
                filtered.map((item) => (
                  <tr key={item.id} className="hover:bg-white/[0.02]">
                    <td className="px-4 py-3 font-semibold text-white uppercase">{item.examId}</td>
                    <td className="px-4 py-3 text-accentCyan font-medium">
                      {item.subject} <span className="text-white/40">(Unit {item.unit})</span>
                    </td>
                    <td className="px-4 py-3 font-medium text-white/90">{item.title}</td>
                    <td className="px-4 py-3">
                      <span className="rounded bg-white/10 px-2 py-0.5 font-bold text-white/90">
                        {formatCategoryPill(item.contentType)}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-right space-x-2">
                      {item.fileUrl && (
                        <a
                          href={item.fileUrl}
                          target="_blank"
                          rel="noreferrer"
                          className="inline-flex items-center rounded-lg bg-accentBlue/20 px-2.5 py-1 text-xs font-semibold text-accentCyan hover:bg-accentBlue/30 border border-accentBlue/40"
                        >
                          View S3 Media ↗
                        </a>
                      )}
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={5} className="px-4 py-12 text-center text-white/40">
                    No competitive exam materials published yet. Fill out the form above to upload a resource!
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
