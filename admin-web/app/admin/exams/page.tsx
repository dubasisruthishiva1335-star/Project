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

export default function ExamsAdminPage() {
  const [resources, setResources] = useState<ExamResource[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedExam, setSelectedExam] = useState<string>("All");

  const examConfig: UploadFormConfig = {
    domain: "exams",
    confirmPath: "/admin/exams/confirm",
    acceptedFileTypes: "video/*,application/pdf",
    requireFile: false,
    successMessage: "Competitive Exam resource published successfully to AWS S3 & synced with Mobile App instantly.",
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
          { value: "VIDEO", label: "🎬 S3 Video Lecture Stream" },
          { value: "PDF", label: "📄 PDF Study Material / PYQ Handout" },
          { value: "SYLLABUS", label: "📜 Syllabus & Selection Roadmap" },
        ],
      },
      { name: "title", label: "Lecture / Document Title *", type: "text", required: true, placeholder: "e.g. Indian Polity Laxmikanth Masterclass & Solved PYQs" },
      { name: "subject", label: "Subject / Module Topic *", type: "text", required: true, placeholder: "e.g. Indian Polity / Quantitative Aptitude / Biology" },
      { name: "duration", label: "Video Duration (e.g. 25:00)", type: "text", required: false, placeholder: "e.g. 25:00" },
      { name: "publicUrl", label: "External S3 Media Stream URL / Link", type: "text", required: false, placeholder: "https://myvault-files-app.s3.eu-north-1.amazonaws.com/lecture.mp4" },
    ],
  };

  const loadResources = useCallback(async () => {
    setLoading(true);
    try {
      // 1. Fetch from Next.js serverless route /api/exams directly
      const response = await fetch("/api/exams");
      if (response.ok) {
        const res = await response.json();
        const list: ExamResource[] = [];
        if (Array.isArray(res)) {
          res.forEach((exam: any) => {
            (exam.videos || []).forEach((v: any) => {
              list.push({
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
              list.push({
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
        setResources(list);
      }
    } catch (_) {}
    setLoading(false);
  }, []);

  useEffect(() => {
    loadResources();
    const interval = setInterval(loadResources, 3000);
    return () => clearInterval(interval);
  }, [loadResources]);

  const filtered = selectedExam === "All"
    ? resources
    : resources.filter((r) => r.examName.toLowerCase().includes(selectedExam.toLowerCase()));

  return (
    <div className="mx-auto max-w-5xl px-4 py-10">
      <div className="mb-8">
        <h1 className="bg-gradient-to-r from-accentBlue to-accentCyan bg-clip-text text-2xl font-extrabold text-transparent">
          Competitive Exam Content Uploading Portal
        </h1>
        <p className="mt-1 text-sm text-white/50">
          Upload video lectures, PDF notes, previous year papers (PYQs), and syllabus roadmaps directly to AWS S3 storage for Mobile App aspirants.
        </p>
      </div>

      {/* Upload Form Component */}
      <div className="mb-12 rounded-2xl border border-white/10 bg-white/[0.02] p-6 backdrop-blur-xl">
        <h2 className="mb-4 text-base font-bold text-white flex items-center gap-2">
          <span>📤 Upload New Lecture Video or S3 PDF Material</span>
        </h2>
        <UploadForm config={examConfig} />
      </div>

      {/* Live Uploaded Resources Management Section */}
      <div className="rounded-2xl border border-white/10 bg-white/[0.02] p-6 backdrop-blur-xl">
        <div className="mb-6 flex flex-wrap items-center justify-between gap-4">
          <div>
            <h2 className="text-lg font-bold text-white flex items-center gap-2">
              <span>📚 Live Uploaded Competitive Exam Materials ({filtered.length})</span>
            </h2>
            <p className="text-xs text-white/50">Everything listed here streams live on the Mobile App</p>
          </div>

          <div className="flex items-center gap-3">
            <select
              value={selectedExam}
              onChange={(e) => setSelectedExam(e.target.value)}
              className="rounded-xl border border-white/10 bg-black/60 px-3.5 py-1.5 text-xs text-white focus:border-accentCyan focus:outline-none"
            >
              <option value="All">Filter by Exam (All)</option>
              <option value="UPSC">UPSC Civil Services</option>
              <option value="SSC">SSC CGL</option>
              <option value="Banking">Banking PO / Clerk</option>
              <option value="Railways">RRB Railways</option>
              <option value="JEE">JEE Main / Advanced</option>
              <option value="NEET">NEET-UG Medical</option>
              <option value="GATE">GATE Engineering</option>
              <option value="CAT">CAT Management</option>
              <option value="CA">CA Qualification</option>
            </select>

            <button
              onClick={loadResources}
              className="rounded-xl border border-white/10 bg-white/5 px-3 py-1.5 text-xs font-semibold text-white/80 hover:bg-white/10"
            >
              🔄 Refresh List
            </button>
          </div>
        </div>

        {/* Resources Table */}
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="border-b border-white/10 bg-white/[0.02] text-white/50 uppercase">
              <tr>
                <th className="px-4 py-3">Exam Target</th>
                <th className="px-4 py-3">Resource Format</th>
                <th className="px-4 py-3">Title</th>
                <th className="px-4 py-3">Subject</th>
                <th className="px-4 py-3 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/5 text-white/80">
              {loading && resources.length === 0 ? (
                <tr>
                  <td colSpan={5} className="px-4 py-8 text-center text-white/40">
                    Loading live uploaded exam resources…
                  </td>
                </tr>
              ) : filtered.length > 0 ? (
                filtered.map((item) => (
                  <tr key={item.id} className="hover:bg-white/[0.02]">
                    <td className="px-4 py-3 font-semibold text-white">{item.examName}</td>
                    <td className="px-4 py-3">
                      <span className={`rounded px-2 py-0.5 font-bold ${item.contentType === "VIDEO" ? "bg-purple-500/20 text-purple-300" : "bg-amber-500/20 text-amber-300"}`}>
                        {item.contentType === "VIDEO" ? "🎬 Video Stream" : "📄 PDF Document"}
                      </span>
                    </td>
                    <td className="px-4 py-3 font-medium text-white/90">{item.title}</td>
                    <td className="px-4 py-3 text-accentCyan">{item.subject}</td>
                    <td className="px-4 py-3 text-right space-x-2">
                      {item.fileUrl && (
                        <a
                          href={item.fileUrl}
                          target="_blank"
                          rel="noreferrer"
                          className="inline-flex items-center rounded-lg bg-accentBlue/20 px-2.5 py-1 text-xs font-semibold text-accentCyan hover:bg-accentBlue/30 border border-accentBlue/40"
                        >
                          Open S3 ↗
                        </a>
                      )}
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={5} className="px-4 py-8 text-center text-white/40">
                    No uploaded resources found for this filter.
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
