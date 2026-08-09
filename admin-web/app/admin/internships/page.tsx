import { UploadForm, type UploadFormConfig } from "@/components/admin/UploadForm";

// One form covers Internships, Placements, and Govt Jobs — the JobListing
// model differentiates on `type`. File is optional here (a job posting
// often only needs an apply link), so requireFile stays false and an
// attachment can be added later via the same domain if needed.
const jobListingConfig: UploadFormConfig = {
  domain: "job-listings",
  confirmPath: "/admin/job-listings/confirm",
  requireFile: false,
  successMessage: "Listing published to the Placement Desk.",
  fields: [
    {
      name: "type",
      label: "Listing Type",
      type: "select",
      required: true,
      options: [
        { value: "INTERNSHIP", label: "Internship" },
        { value: "PLACEMENT", label: "Placement" },
        { value: "GOVT_JOB", label: "Govt Job" },
      ],
    },
    { name: "title", label: "Title", type: "text", required: true, placeholder: "Frontend Engineering Intern" },
    { name: "company", label: "Company / Organization", type: "text", required: true },
    { name: "applyUrl", label: "Apply Link", type: "text", required: true, placeholder: "https://…" },
    { name: "deadline", label: "Deadline", type: "date" },
    { name: "branch", label: "Branch (optional)", type: "text", placeholder: "Leave blank for all branches" },
  ],
};

export default function InternshipsAdminPage() {
  return (
    <div className="mx-auto max-w-2xl px-4 py-10">
      <h1 className="mb-1 text-xl font-semibold text-white">Post Internship / Placement / Govt Job</h1>
      <p className="mb-6 text-sm text-white/50">Appears instantly on the Placement Desk in the app.</p>
      <UploadForm config={jobListingConfig} />
    </div>
  );
}
