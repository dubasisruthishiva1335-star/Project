import { UploadForm, type UploadFormConfig } from "@/components/admin/UploadForm";

const notesConfig: UploadFormConfig = {
  domain: "notes",
  confirmPath: "/admin/notes/confirm",
  acceptedFileTypes: "application/pdf,video/mp4",
  successMessage: "Academic material published successfully — visible to students instantly.",
  fields: [
    { name: "title", label: "Title", type: "text", required: true, placeholder: "Unit 3 — Data Structures & Algorithms" },
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
      name: "semester",
      label: "Semester",
      type: "select",
      required: true,
      options: [
        { value: "1", label: "Sem 1 (1st Year)" },
        { value: "2", label: "Sem 2 (1st Year)" },
        { value: "3", label: "Sem 3 (2nd Year)" },
        { value: "4", label: "Sem 4 (2nd Year)" },
        { value: "5", label: "Sem 5 (3rd Year)" },
        { value: "6", label: "Sem 6 (3rd Year)" },
        { value: "7", label: "Sem 7 (4th Year)" },
        { value: "8", label: "Sem 8 (4th Year)" },
      ],
    },
    {
      name: "unit",
      label: "Unit Number",
      type: "select",
      required: true,
      options: [
        { value: "1", label: "Unit 1" },
        { value: "2", label: "Unit 2" },
        { value: "3", label: "Unit 3" },
        { value: "4", label: "Unit 4" },
        { value: "5", label: "Unit 5" },
      ],
    },
    {
      name: "contentType",
      label: "Material Category",
      type: "select",
      required: true,
      options: [
        { value: "NOTES", label: "📄 Lecture Notes" },
        { value: "VIDEO_LECTURE", label: "🎬 Video Lecture" },
        { value: "LAB_MANUAL", label: "🧪 Lab Manual" },
        { value: "CHEAT_SHEET", label: "⚡ Cheat Sheet" },
        { value: "ASSIGNMENT", label: "📋 Assignment" },
        { value: "QUESTION_BANK", label: "📊 Question Bank / Previous Papers" },
        { value: "SYLLABUS", label: "📜 Syllabus" },
      ],
    },
  ],
};

export default function NotesAdminPage() {
  return (
    <div className="mx-auto max-w-2xl px-4 py-10">
      <h1 className="mb-1 text-xl font-semibold text-white">Upload Academic Resources</h1>
      <p className="mb-6 text-sm text-white/50">
        Files upload directly to AWS S3 storage; students see them instantly under their selected branch, semester, and unit.
      </p>
      <UploadForm config={notesConfig} />
    </div>
  );
}
