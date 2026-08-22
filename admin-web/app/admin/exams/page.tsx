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
    try {
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
          Upload video lectures (.mp4, .webm), PDF notes (.pdf), solved question papers (PYQs), and syllabus guides directly to AWS S3 storage under target exam folders.
        </p>
      </div>

      {/* Resource Format Switcher */}
      <div className="mb-6 flex items-center gap-3 rounded-2xl border border-white/10 bg-black/40 p-2">
        <span className="text-xs font-bold text-white/70 px-3">Select Format Mode:</span>
        <button
          onClick={() => setResourceFormat("VIDEO")}
          className={`flex items-center gap-2 rounded-xl px-4 py-2 text-xs font-bold transition ${
            resourceFormat === "VIDEO" ? "bg-accentBlue text-white shadow-lg" : "text-white/60 hover:text-white"
          }`}
        >
          🎬 Video Lecture Stream (video/mp4)
        </button>
        <button
          onClick={() => setResourceFormat("PDF")}
          className={`flex items-center gap-2 rounded-xl px-4 py-2 text-xs font-bold transition ${
            resourceFormat === "PDF" ? "bg-accentBlue text-white shadow-lg" : "text-white/60 hover:text-white"
          }`}
        >
          📄 PDF Notes & PYQ (application/pdf)
        </button>
        <button
          onClick={() => setResourceFormat("SYLLABUS")}
          className={`flex items-center gap-2 rounded-xl px-4 py-2 text-xs font-bold transition ${
            resourceFormat === "SYLLABUS" ? "bg-accentBlue text-white shadow-lg" : "text-white/60 hover:text-white"
          }`}
        >
          📜 Syllabus & Roadmap (.pdf / .doc)
        </button>
      </div>

      {/* Upload Form Component with Dynamic File Dropzone */}
      <div className="mb-12 rounded-2xl border border-white/10 bg-white/[0.02] p-6 backdrop-blur-xl">
        <div className="mb-4 flex items-center justify-between">
          <h2 className="text-base font-bold text-white flex items-center gap-2">
            <span>📤 Upload Competitive Exam {resourceFormat === "VIDEO" ? "Video (.mp4)" : "PDF (.pdf)"} to S3 ({targetFolder}/)</span>
          </h2>
          <span className="rounded-full bg-cyan-400/10 px-3 py-1 text-xs font-semibold text-cyan-300 border border-cyan-400/20">
            Accepted: {acceptedFileTypes}
          </span>
        </div>
        <UploadForm key={resourceFormat} config={examConfig} />
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
