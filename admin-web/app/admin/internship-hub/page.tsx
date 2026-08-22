"use client";

import { useState } from "react";
import { UploadForm, type UploadFormConfig } from "@/components/admin/UploadForm";

const courseUploadConfig: UploadFormConfig = {
  domain: "internship-hub/courses",
  confirmPath: "/api/admin/internship-hub/courses/confirm",
  acceptedFileTypes: "video/mp4,application/pdf,image/*",
  requireFile: false,
  successMessage: "Industrial Course & Video Lessons published successfully — available to students in Mobile App instantly.",
  fields: [
    { name: "title", label: "Course Title *", type: "text", required: true, placeholder: "e.g. Flutter Mobile App Development" },
    {
      name: "category",
      label: "Course Domain / Category *",
      type: "select",
      required: true,
      options: [
        { value: "Mobile", label: "📱 Mobile App Development (Flutter / React Native)" },
        { value: "Web", label: "💻 Full Stack Web Development (React / Node / Next.js)" },
        { value: "AI", label: "🤖 AI & Machine Learning Foundations" },
        { value: "Data", label: "📊 Data Science & Python Engineering" },
        { value: "Cloud", label: "☁️ Cloud Computing & AWS Architecture" },
        { value: "Security", label: "🔐 Cybersecurity & Penetration Testing" },
        { value: "DevOps", label: "⚙️ DevOps & CI/CD Pipelines" },
      ],
    },
    {
      name: "level",
      label: "Target Skill Level *",
      type: "select",
      required: true,
      options: [
        { value: "Beginner", label: "Beginner (No prerequisites)" },
        { value: "Intermediate", label: "Intermediate" },
        { value: "Advanced", label: "Advanced Specialization" },
      ],
    },
    { name: "duration", label: "Estimated Duration *", type: "text", required: true, placeholder: "e.g. 8 Hours" },
    { name: "description", label: "Course Overview & Objectives *", type: "text", required: true, placeholder: "Build real-world apps with state management, REST APIs, and S3..." },
    { name: "publicUrl", label: "External S3 Video / PDF Notes URL (optional)", type: "text", required: false, placeholder: "https://myvault-files-app.s3.eu-north-1.amazonaws.com/lecture.mp4" },
  ],
};

const opportunityConfig: UploadFormConfig = {
  domain: "internships/opportunities",
  confirmPath: "/api/admin/job-listings/confirm",
  acceptedFileTypes: "application/pdf,image/*",
  requireFile: false,
  successMessage: "Internship / Job Opportunity published successfully — synced to Mobile App in real-time.",
  fields: [
    { name: "title", label: "Position Title *", type: "text", required: true, placeholder: "e.g. Full Stack Developer Intern" },
    { name: "company", label: "Company / Organization Name *", type: "text", required: true, placeholder: "e.g. Google / TCS / Startup" },
    {
      name: "type",
      label: "Listing Type *",
      type: "select",
      required: true,
      options: [
        { value: "INTERNSHIP", label: "💼 Internship" },
        { value: "PLACEMENT", label: "🏢 Full-time Placement Drive" },
        { value: "GOVT_JOB", label: "🏛️ Govt Job Opportunity" },
      ],
    },
    {
      name: "branch",
      label: "Target Branch *",
      type: "select",
      required: true,
      options: [
        { value: "All Branches", label: "All Branches" },
        { value: "CSE & IT", label: "CSE & IT" },
        { value: "ECE", label: "ECE" },
        { value: "AI & ML", label: "AI & ML" },
        { value: "EEE", label: "EEE" },
        { value: "MECH & CIVIL", label: "MECH & CIVIL" },
      ],
    },
    { name: "stipend", label: "Stipend / Salary Package", type: "text", required: false, placeholder: "e.g. ₹20,000 / month or 8 LPA" },
    { name: "location", label: "Work Location", type: "text", required: false, placeholder: "e.g. Hyderabad / Remote / Hybrid" },
    { name: "deadline", label: "Application Deadline Date", type: "date", required: false },
    { name: "description", label: "Brief Description & Requirements", type: "text", required: false, placeholder: "Key eligibility, skills required, selection process..." },
    { name: "applyUrl", label: "Application Link / Portal URL", type: "text", required: false, placeholder: "https://careers.google.com/jobs" },
  ],
};

export default function InternshipHubAdminPage() {
  const [activeTab, setActiveTab] = useState<"courses" | "opportunities" | "submissions" | "certificates">("courses");

  return (
    <div className="mx-auto max-w-4xl px-4 py-10">
      <div className="mb-8">
        <h1 className="bg-gradient-to-r from-accentBlue to-accentCyan bg-clip-text text-2xl font-black text-transparent">
          INTERNSHIP HUB CMS ⭐
        </h1>
        <p className="mt-1 text-sm text-white/50">
          Learn a skill ➔ Complete course ➔ Earn certificate ➔ Discover & apply for relevant internships.
        </p>
      </div>

      {/* Tab Navigation Header */}
      <div className="mb-8 flex flex-wrap rounded-xl border border-white/10 bg-black/40 p-1.5 backdrop-blur-md">
        <button
          onClick={() => setActiveTab("courses")}
          className={`flex-1 rounded-lg py-2.5 px-3 text-center text-xs font-semibold transition-all sm:text-sm ${
            activeTab === "courses"
              ? "bg-gradient-to-r from-accentBlue to-cyan-500 text-white shadow-lg"
              : "text-white/60 hover:text-white"
          }`}
        >
          🎓 Courses & Learning
        </button>
        <button
          onClick={() => setActiveTab("opportunities")}
          className={`flex-1 rounded-lg py-2.5 px-3 text-center text-xs font-semibold transition-all sm:text-sm ${
            activeTab === "opportunities"
              ? "bg-gradient-to-r from-accentBlue to-cyan-500 text-white shadow-lg"
              : "text-white/60 hover:text-white"
          }`}
        >
          💼 Internships & Jobs
        </button>
        <button
          onClick={() => setActiveTab("submissions")}
          className={`flex-1 rounded-lg py-2.5 px-3 text-center text-xs font-semibold transition-all sm:text-sm ${
            activeTab === "submissions"
              ? "bg-gradient-to-r from-accentBlue to-cyan-500 text-white shadow-lg"
              : "text-white/60 hover:text-white"
          }`}
        >
          👥 Submissions
        </button>
        <button
          onClick={() => setActiveTab("certificates")}
          className={`flex-1 rounded-lg py-2.5 px-3 text-center text-xs font-semibold transition-all sm:text-sm ${
            activeTab === "certificates"
              ? "bg-gradient-to-r from-accentBlue to-cyan-500 text-white shadow-lg"
              : "text-white/60 hover:text-white"
          }`}
        >
          🏆 Certificates
        </button>
      </div>

      {/* Tab Content */}
      <div className="rounded-2xl border border-white/10 bg-white/[0.02] p-6 backdrop-blur-xl">
        {activeTab === "courses" && (
          <div>
            <div className="mb-6 flex items-center justify-between border-b border-white/10 pb-4">
              <div>
                <h2 className="text-lg font-bold text-white">Publish Industrial Learning Course</h2>
                <p className="text-xs text-white/50">
                  Upload S3 video lessons, configure quizzes, assignments, final exams, and verified certificates.
                </p>
              </div>
              <span className="rounded-full border border-cyan-400/30 bg-cyan-400/10 px-3 py-1 text-xs font-semibold text-cyan-300">
                + Create Course
              </span>
            </div>
            <UploadForm config={courseUploadConfig} />
          </div>
        )}

        {activeTab === "opportunities" && (
          <div>
            <div className="mb-6 flex items-center justify-between border-b border-white/10 pb-4">
              <div>
                <h2 className="text-lg font-bold text-white">Post New Opportunity or Placement</h2>
                <p className="text-xs text-white/50">
                  Fill out opportunity details, stipend, location, deadline, and optionally attach a PDF circular.
                </p>
              </div>
              <span className="rounded-full border border-cyan-400/30 bg-cyan-400/10 px-3 py-1 text-xs font-semibold text-cyan-300">
                + Post Opportunity
              </span>
            </div>
            <UploadForm config={opportunityConfig} />
          </div>
        )}

        {activeTab === "submissions" && (
          <div>
            <h2 className="mb-2 text-lg font-bold text-white">Student Assignment & Exam Submissions</h2>
            <p className="mb-6 text-xs text-white/50">
              Review student GitHub submissions, practical projects, and automated exam scores.
            </p>
            <div className="space-y-4">
              <div className="flex items-center justify-between rounded-xl border border-white/10 bg-black/30 p-4">
                <div>
                  <h4 className="font-semibold text-white">Rahul Kumar (21A91A0501)</h4>
                  <p className="text-xs text-white/50">Flutter Mobile App Development — Practical Assignment 01</p>
                  <p className="mt-1 text-xs text-cyan-400">GitHub: https://github.com/rahul/flutter-student-dashboard</p>
                </div>
                <span className="rounded-md border border-emerald-400/30 bg-emerald-400/10 px-2.5 py-1 text-xs font-semibold text-emerald-300">
                  PASSED (85%)
                </span>
              </div>
            </div>
          </div>
        )}

        {activeTab === "certificates" && (
          <div>
            <h2 className="mb-2 text-lg font-bold text-white">Issued Industrial Certificates</h2>
            <p className="mb-6 text-xs text-white/50">
              Verified PDFKit certificates with QR verification generated and stored directly on AWS S3.
            </p>
            <div className="space-y-4">
              <div className="flex items-center justify-between rounded-xl border border-white/10 bg-black/30 p-4">
                <div>
                  <h4 className="font-semibold text-white">IH-CERT-884920</h4>
                  <p className="text-xs text-white/50">Issued to: Rahul Kumar • Flutter Mobile App Development</p>
                  <p className="mt-1 text-xs text-white/40">Issued On: 23/08/2026</p>
                </div>
                <a
                  href="https://myvault-files-app.s3.eu-north-1.amazonaws.com/app-arm64-v8a-release.apk"
                  target="_blank"
                  rel="noreferrer"
                  className="rounded-lg bg-cyan-500/20 px-3 py-1.5 text-xs font-semibold text-cyan-300 hover:bg-cyan-500/30"
                >
                  View S3 PDF ↗
                </a>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
