import { UploadForm, type UploadFormConfig } from "@/components/admin/UploadForm";

const internshipConfig: UploadFormConfig = {
  domain: "internships",
  confirmPath: "/admin/job-listings/confirm",
  acceptedFileTypes: "application/pdf,video/mp4",
  requireFile: false,
  successMessage: "💼 Internship Opportunity published successfully — visible to students in Internship Hub instantly.",
  fields: [
    { name: "type", label: "Listing Type", type: "text", required: true, defaultValue: "INTERNSHIP", hidden: true },
    { name: "title", label: "Internship Title *", type: "text", required: true, placeholder: "e.g. React & Node.js Developer Intern" },
    { name: "company", label: "Company / Organization Name *", type: "text", required: true, placeholder: "e.g. Google / Microsoft / Startup" },
    {
      name: "isLmsEnabled",
      label: "Execution Mode (Plain Link vs Full LMS Industrial Course)",
      type: "select",
      required: true,
      options: [
        { value: "false", label: "🔗 Plain Internship Listing (Apply via External URL + PDF Circular)" },
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
    { name: "applyUrl", label: "Application Portal Link / Registration Form URL", type: "text", required: false, placeholder: "https://careers.google.com/internships" },
  ],
};

export default function InternshipsAdminPage() {
  return (
    <div className="mx-auto max-w-2xl px-4 py-10">
      <h1 className="mb-1 text-xl font-semibold text-white">💼 Publish Internship & LMS Course</h1>
      <p className="mb-6 text-sm text-white/50">
        Post internships and LMS industrial training courses with video lessons, pdf materials, and completion certificates. Routes strictly to the Internship Hub in the Mobile App.
      </p>
      <UploadForm config={internshipConfig} />
    </div>
  );
}
