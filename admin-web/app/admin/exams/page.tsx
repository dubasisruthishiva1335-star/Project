import { UploadForm, type UploadFormConfig } from "@/components/admin/UploadForm";

const examConfig: UploadFormConfig = {
  domain: "exams",
  confirmPath: "/admin/exams/confirm",
  acceptedFileTypes: "video/*,application/pdf",
  requireFile: false,
  successMessage: "Competitive Exam Preparation Resource (Video / PDF / PYQ) published successfully to AWS S3 & Mobile App.",
  fields: [
    {
      name: "examName",
      label: "Select Target Competitive Exam",
      type: "select",
      required: true,
      options: [
        { value: "UPSC Civil Services (IAS / IPS / IFS)", label: "🏛️ UPSC Civil Services (IAS / IPS / IFS)" },
        { value: "SSC CGL (Staff Selection Commission)", label: "🏛️ SSC CGL (Staff Selection Commission)" },
        { value: "SBI PO / IBPS PO & Clerk", label: "🏦 SBI PO / IBPS PO & Clerk (Banking)" },
        { value: "RRB NTPC & Railway JE", label: "🚆 RRB NTPC & Railway JE" },
        { value: "JEE Main / Advanced (Engineering)", label: "🎓 JEE Main / Advanced (Engineering Entrance)" },
        { value: "NEET-UG (Medical Entrance)", label: "🩺 NEET-UG (Medical Entrance)" },
        { value: "GATE (Engineering & PSUs)", label: "⚡ GATE (Engineering & PSUs)" },
        { value: "CAT / XAT (Management)", label: "💼 CAT / XAT (IIMs & B-Schools)" },
        { value: "CA (Chartered Accountant)", label: "📊 CA (Chartered Accountant Qualification)" },
      ],
    },
    {
      name: "contentType",
      label: "Resource Category",
      type: "select",
      required: true,
      options: [
        { value: "VIDEO", label: "🎬 S3 Video Lecture Stream" },
        { value: "PDF", label: "📄 PDF Study Material / PYQ Handout" },
        { value: "SYLLABUS", label: "📜 Syllabus & Strategy Roadmap" },
      ],
    },
    { name: "title", label: "Resource Title", type: "text", required: true, placeholder: "e.g. Indian Polity Laxmikanth Masterclass & PYQ Analysis" },
    { name: "subject", label: "Subject / Topic", type: "text", required: true, placeholder: "e.g. Indian Polity / Quantitative Aptitude / Biology" },
    { name: "duration", label: "Lecture Duration (for Videos)", type: "text", required: false, placeholder: "e.g. 25:00" },
    { name: "publicUrl", label: "External S3 Media Stream URL / Link", type: "text", required: false, placeholder: "https://myvault-files-app.s3.eu-north-1.amazonaws.com/lecture.mp4" },
  ],
};

export default function ExamsAdminPage() {
  return (
    <div className="mx-auto max-w-2xl px-4 py-10">
      <h1 className="mb-1 text-xl font-semibold text-white">Upload Competitive Exam Video Lecture & PDF Notes</h1>
      <p className="mb-6 text-sm text-white/50">
        Upload video lectures, PDF notes, and PYQs directly to AWS S3 storage for UPSC, SSC, Banking, JEE, NEET, GATE, CAT, and CA aspirants.
      </p>
      <UploadForm config={examConfig} />
    </div>
  );
}
