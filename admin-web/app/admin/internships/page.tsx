import { UploadForm, type UploadFormConfig } from "@/components/admin/UploadForm";

const internshipConfig: UploadFormConfig = {
  domain: "internships",
  confirmPath: "/admin/job-listings/confirm",
  acceptedFileTypes: "application/pdf,image/*",
  successMessage: "Internship / Job Listing published successfully — visible to students in Mobile App instantly.",
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
        { value: "PLACEMENT", label: "🏢 Full-time Placement" },
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
    { name: "applyUrl", label: "Application Link / Website URL", type: "text", required: false, placeholder: "https://careers.google.com/jobs" },
  ],
};

export default function InternshipsAdminPage() {
  return (
    <div className="mx-auto max-w-2xl px-4 py-10">
      <h1 className="mb-1 text-xl font-semibold text-white">Post New Internship / Job Listing</h1>
      <p className="mb-6 text-sm text-white/50">
        Fill out details and optionally attach a PDF notification or brochure. Published items reflect on the Mobile App immediately.
      </p>
      <UploadForm config={internshipConfig} />
    </div>
  );
}
