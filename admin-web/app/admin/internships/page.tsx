"use client";

import { useState } from "react";
import { UploadForm, type UploadFormConfig } from "@/components/admin/UploadForm";

export default function InternshipsAdminPage() {
  const [selectedType, setSelectedType] = useState<"INTERNSHIP" | "PLACEMENT" | "GOVT_JOB">("INTERNSHIP");

  const getConfig = (type: "INTERNSHIP" | "PLACEMENT" | "GOVT_JOB"): UploadFormConfig => {
    switch (type) {
      case "INTERNSHIP":
        return {
          domain: "internships",
          confirmPath: "/admin/job-listings/confirm",
          acceptedFileTypes: "application/pdf,video/mp4",
          requireFile: false,
          successMessage: "💼 Internship Opportunity published successfully — visible to students in the Internship Hub instantly.",
          fields: [
            { name: "type", label: "Listing Type *", type: "text", required: true, defaultValue: "INTERNSHIP", hidden: true },
            { name: "title", label: "Internship Title *", type: "text", required: true, placeholder: "e.g. React & Node.js Developer Intern" },
            { name: "company", label: "Company / Organization Name *", type: "text", required: true, placeholder: "e.g. Google / Microsoft / Startup" },
            {
              name: "isLmsEnabled",
              label: "Execution Mode (Plain vs Full LMS Course)",
              type: "select",
              required: true,
              options: [
                { value: "false", label: "🔗 Plain Internship Listing (Apply via External URL + Circular PDF)" },
                { value: "true", label: "🎓 Full LMS Industrial Course (Modules + Video Lessons + PDF Certificate)" },
              ],
            },
            {
              name: "branch",
              label: "Target Student Branch *",
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
            { name: "stipend", label: "Monthly Stipend Amount", type: "text", required: false, placeholder: "e.g. ₹20,000 / month or Unpaid" },
            { name: "duration", label: "Internship Duration", type: "text", required: false, placeholder: "e.g. 3 Months / 6 Months" },
            { name: "location", label: "Work Location / Mode", type: "text", required: false, placeholder: "e.g. Remote / Hybrid / Hyderabad" },
            { name: "deadline", label: "Application Deadline Date", type: "date", required: false },
            { name: "description", label: "Internship Description & Key Eligibility", type: "text", required: false, placeholder: "Skills required, responsibilities, selection process..." },
            { name: "applyUrl", label: "Application Portal Link / Registration Form URL", type: "text", required: false, placeholder: "https://careers.google.com/jobs" },
          ],
        };

      case "PLACEMENT":
        return {
          domain: "internships",
          confirmPath: "/admin/job-listings/confirm",
          acceptedFileTypes: "application/pdf,video/mp4",
          requireFile: false,
          successMessage: "🏢 Campus Placement Drive published successfully — visible to students in Placement Hub instantly.",
          fields: [
            { name: "type", label: "Listing Type *", type: "text", required: true, defaultValue: "PLACEMENT", hidden: true },
            { name: "title", label: "Job Role / Profile Title *", type: "text", required: true, placeholder: "e.g. Software Development Engineer (SDE-1)" },
            { name: "company", label: "Hiring Corporate / Company Name *", type: "text", required: true, placeholder: "e.g. Tata Consultancy Services (TCS) / Amazon / Infosys" },
            {
              name: "branch",
              label: "Eligible Engineering Branches *",
              type: "select",
              required: true,
              options: [
                { value: "All Branches", label: "All Branches (Circuit & Core)" },
                { value: "CSE & IT", label: "CSE & IT Only" },
                { value: "ECE", label: "ECE Only" },
                { value: "AI & ML", label: "AI & ML Only" },
                { value: "EEE", label: "EEE Only" },
                { value: "MECH & CIVIL", label: "MECH & CIVIL Only" },
              ],
            },
            { name: "stipend", label: "Salary Package (CTC / Pay)", type: "text", required: true, placeholder: "e.g. 8.5 LPA or 12 LPA + Benefits" },
            { name: "location", label: "Posting Location", type: "text", required: false, placeholder: "e.g. Pan India / Bangalore / Hyderabad" },
            { name: "deadline", label: "Drive Registration Deadline", type: "date", required: false },
            { name: "description", label: "Eligibility Cutoff & Selection Rounds", type: "text", required: false, placeholder: "Min 60% CGPA, no active backlogs, Online Test + Tech Interview..." },
            { name: "applyUrl", label: "Corporate Drive Application Link", type: "text", required: false, placeholder: "https://careers.tcs.com/nextstep" },
          ],
        };

      case "GOVT_JOB":
        return {
          domain: "internships",
          confirmPath: "/admin/job-listings/confirm",
          acceptedFileTypes: "application/pdf,video/mp4",
          requireFile: false,
          successMessage: "🏛️ Govt Job Opportunity published successfully — visible to students in Govt Jobs Hub instantly.",
          fields: [
            { name: "type", label: "Listing Type *", type: "text", required: true, defaultValue: "GOVT_JOB", hidden: true },
            { name: "title", label: "Govt Post / Notification Title *", type: "text", required: true, placeholder: "e.g. Scientist 'B' / Executive Engineer Recruitment" },
            { name: "company", label: "Govt Ministry / Organization *", type: "text", required: true, placeholder: "e.g. ISRO / DRDO / UPSC / Railways (RRB) / State PSC" },
            {
              name: "branch",
              label: "Target Qualification / Stream *",
              type: "select",
              required: true,
              options: [
                { value: "All Branches", label: "All Engineering & Degree Streams" },
                { value: "CSE & IT", label: "Computer Science (CSE / IT)" },
                { value: "ECE", label: "Electronics & Comm (ECE)" },
                { value: "EEE", label: "Electrical Engineering (EEE)" },
                { value: "MECH & CIVIL", label: "Mechanical & Civil Engineering" },
              ],
            },
            { name: "stipend", label: "Pay Scale / Salary Level", type: "text", required: false, placeholder: "e.g. Level 10 Pay Matrix (₹56,100 - ₹1,77,500)" },
            { name: "duration", label: "Total Number of Vacancies", type: "text", required: false, placeholder: "e.g. 450 Vacancies (All India)" },
            { name: "location", label: "Job Location", type: "text", required: false, placeholder: "e.g. All India / State Cadre" },
            { name: "deadline", label: "Online Application Closing Date", type: "date", required: false },
            { name: "description", label: "Educational Qualification & Age Limit", type: "text", required: false, placeholder: "B.Tech/BE in relevant discipline, GATE score required, Age 18-30 yrs..." },
            { name: "applyUrl", label: "Official Govt Portal Registration Link", type: "text", required: false, placeholder: "https://upsc.gov.in / https://isro.gov.in" },
          ],
        };
    }
  };

  return (
    <div className="mx-auto max-w-3xl px-4 py-10">
      <div className="mb-8">
        <h1 className="bg-gradient-to-r from-accentBlue to-accentCyan bg-clip-text text-2xl font-black text-transparent">
          Publish Jobs & Opportunities
        </h1>
        <p className="mt-1 text-sm text-white/50">
          Select the opportunity category to customize the upload format. Each category routes strictly to its designated hub in the Mobile App.
        </p>
      </div>

      {/* Hub Category Selector Tabs */}
      <div className="mb-8 flex rounded-2xl border border-white/10 bg-black/60 p-1.5 backdrop-blur-xl">
        <button
          onClick={() => setSelectedType("INTERNSHIP")}
          className={`flex-1 rounded-xl py-3 text-xs font-bold transition-all duration-200 ${
            selectedType === "INTERNSHIP"
              ? "bg-accentBlue text-white shadow-lg shadow-accentBlue/20 scale-[1.01]"
              : "text-white/60 hover:text-white"
          }`}
        >
          💼 Internship & LMS Hub
        </button>

        <button
          onClick={() => setSelectedType("PLACEMENT")}
          className={`flex-1 rounded-xl py-3 text-xs font-bold transition-all duration-200 ${
            selectedType === "PLACEMENT"
              ? "bg-purple-600 text-white shadow-lg shadow-purple-600/20 scale-[1.01]"
              : "text-white/60 hover:text-white"
          }`}
        >
          🏢 Campus Placement Hub
        </button>

        <button
          onClick={() => setSelectedType("GOVT_JOB")}
          className={`flex-1 rounded-xl py-3 text-xs font-bold transition-all duration-200 ${
            selectedType === "GOVT_JOB"
              ? "bg-emerald-600 text-white shadow-lg shadow-emerald-600/20 scale-[1.01]"
              : "text-white/60 hover:text-white"
          }`}
        >
          🏛️ Govt Jobs Hub
        </button>
      </div>

      {/* Dynamic Upload Form */}
      <div className="rounded-2xl border border-white/10 bg-white/[0.02] p-6 backdrop-blur-xl">
        <UploadForm key={selectedType} config={getConfig(selectedType)} />
      </div>
    </div>
  );
}
