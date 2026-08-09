import { UploadForm, type UploadFormConfig } from "@/components/admin/UploadForm";

const notesConfig: UploadFormConfig = {
  domain: "notes",
  confirmPath: "/admin/notes/confirm",
  acceptedFileTypes: "application/pdf",
  successMessage: "Note published — visible to students immediately.",
  fields: [
    { name: "title", label: "Title", type: "text", required: true, placeholder: "Unit 3 — Fluid Mechanics" },
    {
      name: "branch",
      label: "Branch",
      type: "select",
      required: true,
      options: [
        { value: "ECE", label: "ECE" },
        { value: "CSE", label: "CSE" },
        { value: "AI_ML", label: "AI & ML" },
        { value: "EEE", label: "EEE" },
        { value: "MECH", label: "MECH" },
        { value: "CIVIL", label: "CIVIL" },
        { value: "GENERAL", label: "General" },
      ],
    },
    {
      name: "year",
      label: "Year",
      type: "select",
      required: true,
      options: [
        { value: "1", label: "Year 1 (1st Year)" },
        { value: "2", label: "Year 2 (2nd Year)" },
        { value: "3", label: "Year 3 (3rd Year)" },
        { value: "4", label: "Year 4 (4th Year)" },
      ],
    },
    {
      name: "contentType",
      label: "Content Type",
      type: "select",
      required: true,
      options: [
        { value: "NOTES", label: "Notes" },
        { value: "QUESTION_BANK", label: "Question Bank" },
        { value: "SYLLABUS", label: "Syllabus" },
        { value: "LAB_MANUAL", label: "Lab Manual" },
      ],
    },
  ],
};

export default function NotesAdminPage() {
  return (
    <div className="mx-auto max-w-2xl px-4 py-10">
      <h1 className="mb-1 text-xl font-semibold text-white">Upload Academic Notes</h1>
      <p className="mb-6 text-sm text-white/50">
        Files upload straight to AWS S3 storage; students see them the moment this confirms.
      </p>
      <UploadForm config={notesConfig} />
    </div>
  );
}
