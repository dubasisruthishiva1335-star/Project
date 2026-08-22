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
  const [activeTab, setActiveTab] = useState<"courses" | "opportunities">("courses");

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
      <div className="mb-8 flex rounded-xl border border-white/10 bg-black/40 p-1.5 backdrop-blur-md">
        <button
          onClick={() => setActiveTab("courses")}
          className={`flex-1 rounded-lg py-2.5 text-center text-sm font-semibold transition-all ${
            activeTab === "courses"
              ? "bg-gradient-to-r from-accentBlue to-cyan-500 text-white shadow-lg"
              : "text-white/60 hover:text-white"
          }`}
        >
          🎓 Courses & Learning
        </button>
        <button
          onClick={() => setActiveTab("opportunities")}
          className={`flex-1 rounded-lg py-2.5 text-center text-sm font-semibold transition-all ${
            activeTab === "opportunities"
              ? "bg-gradient-to-r from-accentBlue to-cyan-500 text-white shadow-lg"
              : "text-white/60 hover:text-white"
          }`}
        >
          💼 Internships & Jobs
        </button>
      </div>

      {/* Tab Content */}
      <div className="rounded-2xl border border-white/10 bg-white/[0.02] p-6 backdrop-blur-xl">
        {activeTab === "courses" ? (
          <div>
            <div className="mb-6 flex items-center justify-between border-b border-white/10 pb-4">
              <div>
                <h2 className="text-lg font-bold text-white">Publish Industrial Learning Course</h2>
                <p className="text-xs text-white/50">
                  Upload S3 video lessons, configure quizzes, assignments, final exams, and verified completion certificates.
                </p>
              </div>
              <span className="rounded-full border border-cyan-400/30 bg-cyan-400/10 px-3 py-1 text-xs font-semibold text-cyan-300">
                + Create Course
              </span>
            </div>
            <UploadForm config={courseUploadConfig} />
          </div>
        ) : (
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
      </div>
    </div>
  );
}
