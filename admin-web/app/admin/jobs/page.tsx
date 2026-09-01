import { UploadForm, type UploadFormConfig } from "@/components/admin/UploadForm";

const jobConfig: UploadFormConfig = {
  domain: "internships",
  confirmPath: "/admin/job-listings/confirm",
  acceptedFileTypes: "application/pdf,video/mp4",
  requireFile: false,
  successMessage: "💼 Full-Time Job Listing published successfully — visible to students in Job Listings Hub instantly.",
  fields: [
    { name: "type", label: "Listing Type", type: "text", required: true, defaultValue: "JOB", hidden: true },
    { name: "title", label: "Job Title / Role *", type: "text", required: true, placeholder: "e.g. Senior Software Engineer / Frontend Developer" },
    { name: "company", label: "Hiring Company / Organization *", type: "text", required: true, placeholder: "e.g. Google / Microsoft / Tech Startup" },
    {
      name: "branch",
      label: "Target Degree / Branch *",
      type: "select",
      required: true,
      options: [
        { value: "All Branches", label: "All Engineering & Degree Streams" },
        { value: "CSE & IT", label: "Computer Science (CSE / IT)" },
        { value: "ECE", label: "Electronics & Comm (ECE)" },
        { value: "AI & ML", label: "AI & Machine Learning" },
        { value: "EEE", label: "Electrical Engineering (EEE)" },
        { value: "MECH & CIVIL", label: "Mechanical & Civil" },
      ],
    },
    { name: "stipend", label: "Salary Package (CTC / Compensation) *", type: "text", required: true, placeholder: "e.g. ₹6,00,000 / annum or 10 - 14 LPA" },
    { name: "location", label: "Work Location / Mode", type: "text", required: false, placeholder: "e.g. Hyderabad / Bangalore / Remote" },
    { name: "deadline", label: "Application Deadline Date", type: "date", required: false },
    { name: "description", label: "Job Description & Requirements", type: "text", required: false, placeholder: "Key eligibility, tech stack required, selection process..." },
    { name: "applyUrl", label: "Application Link / Registration URL", type: "text", required: false, placeholder: "https://careers.company.com/jobs" },
  ],
};

export default function JobsAdminPage() {
  return (
    <div className="mx-auto max-w-2xl px-4 py-10">
      <h1 className="mb-1 text-xl font-bold text-white flex items-center gap-2">
        <span>💼</span> Publish Full-Time Job Listing
      </h1>
      <p className="mb-6 text-sm text-white/50">
        Post full-time job openings, CTC packages, location, and application links. Listings route strictly to the Job Listings Hub in the Mobile App.
      </p>
      <UploadForm config={jobConfig} />
    </div>
  );
}
