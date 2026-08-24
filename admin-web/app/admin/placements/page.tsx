import { UploadForm, type UploadFormConfig } from "@/components/admin/UploadForm";

const placementConfig: UploadFormConfig = {
  domain: "internships",
  confirmPath: "/admin/job-listings/confirm",
  acceptedFileTypes: "application/pdf,video/mp4",
  requireFile: false,
  successMessage: "🏢 Campus Placement Drive published successfully — visible to students in Placement Hub instantly.",
  fields: [
    { name: "type", label: "Listing Type", type: "text", required: true, defaultValue: "PLACEMENT", hidden: true },
    { name: "title", label: "Job Profile / Role Title *", type: "text", required: true, placeholder: "e.g. Software Development Engineer (SDE-1)" },
    { name: "company", label: "Hiring Corporate / Company Name *", type: "text", required: true, placeholder: "e.g. Tata Consultancy Services (TCS) / Amazon / Infosys" },
    {
      name: "branch",
      label: "Eligible Engineering Branches *",
      type: "select",
      required: true,
      options: [
        { value: "All Branches", label: "All Engineering Branches (Circuit & Core)" },
        { value: "CSE & IT", label: "CSE & IT Only" },
        { value: "ECE", label: "ECE Only" },
        { value: "AI & ML", label: "AI & ML Only" },
        { value: "EEE", label: "EEE Only" },
        { value: "MECH & CIVIL", label: "MECH & CIVIL Only" },
      ],
    },
    { name: "stipend", label: "Salary Package (CTC / Pay) *", type: "text", required: true, placeholder: "e.g. 8.5 LPA or 12.0 LPA + Joining Bonus" },
    { name: "location", label: "Posting Location", type: "text", required: false, placeholder: "e.g. Pan India / Bangalore / Hyderabad" },
    { name: "deadline", label: "Drive Registration Deadline", type: "date", required: false },
    { name: "description", label: "Eligibility Cutoff & Selection Process", type: "text", required: false, placeholder: "Min 60% CGPA, no active backlogs, Online Aptitude Test + Tech Interview..." },
    { name: "applyUrl", label: "Corporate Drive Portal Application Link", type: "text", required: false, placeholder: "https://careers.tcs.com/nextstep" },
  ],
};

export default function PlacementsAdminPage() {
  return (
    <div className="mx-auto max-w-2xl px-4 py-10">
      <h1 className="mb-1 text-xl font-semibold text-white">🏢 Publish Campus Placement Drive</h1>
      <p className="mb-6 text-sm text-white/50">
        Post corporate placement drives, salary packages (CTC), eligibility CGPA cutoffs, and application links. Drives route strictly to the Campus Placement Hub in the Mobile App.
      </p>
      <UploadForm config={placementConfig} />
    </div>
  );
}
