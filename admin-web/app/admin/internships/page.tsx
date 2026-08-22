import { UploadForm, type UploadFormConfig } from "@/components/admin/UploadForm";

const internshipConfig: UploadFormConfig = {
  domain: "internships",
  confirmPath: "/api/admin/job-listings/confirm",
  acceptedFileTypes: "application/pdf,image/*",
  requireFile: false,
  successMessage: "Internship / Job Opportunity published successfully — visible to students in Mobile App instantly.",
  fields: [
    { name: "title", label: "Position Title", type: "text", required: true, placeholder: "Full Stack Developer Intern" },
    { name: "company", label: "Company / Organization Name", type: "text", required: true, placeholder: "Google / TCS / Startup" },
    {
      name: "type",
      label: "Listing Type",
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
      label: "Target Branch",
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

export default function InternshipsAdminPage() {
  return (
    <div className="mx-auto max-w-2xl px-4 py-10">
      <h1 className="mb-1 text-xl font-semibold text-white">Post New Internship / Job Opportunity</h1>
      <p className="mb-6 text-sm text-white/50">
        Fill out opportunity details, stipend, location, deadline, and optionally attach a PDF circular. Published items sync to the Mobile App in real-time.
      </p>
      <UploadForm config={internshipConfig} />
    </div>
  );
}
