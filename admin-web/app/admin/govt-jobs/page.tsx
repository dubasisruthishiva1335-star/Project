import { UploadForm, type UploadFormConfig } from "@/components/admin/UploadForm";

const govtJobConfig: UploadFormConfig = {
  domain: "internships",
  confirmPath: "/admin/job-listings/confirm",
  acceptedFileTypes: "application/pdf,video/mp4",
  requireFile: false,
  successMessage: "🏛️ Govt Job Opportunity published successfully — visible to students in Govt Jobs Hub instantly.",
  fields: [
    { name: "type", label: "Listing Type", type: "text", required: true, defaultValue: "GOVT_JOB", hidden: true },
    { name: "title", label: "Govt Post / Notification Title *", type: "text", required: true, placeholder: "e.g. Scientist 'B' / Executive Engineer Recruitment 2026" },
    { name: "company", label: "Govt Ministry / Department Name *", type: "text", required: true, placeholder: "e.g. ISRO / DRDO / UPSC / Railway Recruitment Board (RRB) / State PSC" },
    {
      name: "branch",
      label: "Target Qualification Stream *",
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
    { name: "stipend", label: "Pay Scale / Salary Level Matrix", type: "text", required: false, placeholder: "e.g. Level 10 Pay Matrix (₹56,100 - ₹1,77,500)" },
    { name: "duration", label: "Total Vacancy Posts Count", type: "text", required: false, placeholder: "e.g. 450 Vacancies (All India)" },
    { name: "location", label: "Job Posting Location", type: "text", required: false, placeholder: "e.g. All India / State Cadre" },
    { name: "deadline", label: "Online Application Closing Date", type: "date", required: false },
    { name: "description", label: "Educational Qualification & Selection Process", type: "text", required: false, placeholder: "B.Tech/BE in relevant discipline, GATE score required, Written Exam + Interview..." },
    { name: "applyUrl", label: "Official Govt Registration Portal Link", type: "text", required: false, placeholder: "https://upsc.gov.in / https://isro.gov.in" },
  ],
};

export default function GovtJobsAdminPage() {
  return (
    <div className="mx-auto max-w-2xl px-4 py-10">
      <h1 className="mb-1 text-xl font-semibold text-white">🏛️ Publish Govt Job Opportunity</h1>
      <p className="mb-6 text-sm text-white/50">
        Post Govt notifications, pay levels, vacancy counts, educational qualifications, and official application portals. Notifications route strictly to the Govt Jobs Hub in the Mobile App.
      </p>
      <UploadForm config={govtJobConfig} />
    </div>
  );
}
