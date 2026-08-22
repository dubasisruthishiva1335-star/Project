"use client";

import { UploadForm, type UploadFormConfig } from "@/components/admin/UploadForm";

const courseUploadConfig: UploadFormConfig = {
  domain: "internships/courses",
  confirmPath: "/api/admin/job-listings/confirm",
  acceptedFileTypes: "video/mp4,application/pdf",
  requireFile: false,
  successMessage: "Internship Course & Video Lessons published successfully — available to students instantly in the Mobile App.",
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
      label: "Target Skill Level",
      type: "select",
      required: true,
      options: [
        { value: "Beginner", label: "Beginner (No prerequisites)" },
        { value: "Intermediate", label: "Intermediate" },
        { value: "Advanced", label: "Advanced Specialization" },
      ],
    },
    { name: "duration", label: "Estimated Duration (e.g. 8 Hours)", type: "text", required: true, placeholder: "8 Hours" },
    { name: "description", label: "Course Overview & Objectives", type: "text", required: true, placeholder: "Build real-world apps with state management, REST APIs, and S3..." },
    { name: "publicUrl", label: "External Lesson Video / PDF URL (optional)", type: "text", required: false, placeholder: "https://myvault-files-app.s3.eu-north-1.amazonaws.com/lecture.mp4" },
  ],
};

export default function InternshipCoursesAdminPage() {
  return (
    <div className="mx-auto max-w-4xl px-4 py-10">
      <div className="mb-8">
        <h1 className="bg-gradient-to-r from-accentBlue to-accentCyan bg-clip-text text-2xl font-black text-transparent">
          Internship Learning Hub — Course Manager
        </h1>
        <p className="mt-1 text-sm text-white/50">
          Create free industrial courses, upload S3 video lessons & PDF notes, configure quizzes, assignments, and exams.
        </p>
      </div>

      <div className="rounded-2xl border border-white/10 bg-white/[0.02] p-6 backdrop-blur-xl">
        <UploadForm config={courseUploadConfig} />
      </div>
    </div>
  );
}
