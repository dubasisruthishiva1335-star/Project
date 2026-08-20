import { UploadForm, type UploadFormConfig } from "@/components/admin/UploadForm";

const examConfig: UploadFormConfig = {
  domain: "exams",
  confirmPath: "/admin/exams/confirm",
  acceptedFileTypes: "video/*,application/pdf",
  requireFile: false,
  successMessage: "Exam video lecture / PDF study material published successfully to S3 & Mobile App.",
  fields: [
    {
      name: "examName",
      label: "Select Competitive Exam",
      type: "select",
      required: true,
      options: [
        { value: "UPSC Civil Services", label: "🏛️ UPSC Civil Services (IAS/IPS)" },
        { value: "SSC CGL", label: "🏛️ SSC CGL (Staff Selection Commission)" },
        { value: "SBI PO / IBPS PO", label: "🏦 SBI PO / IBPS PO (Banking)" },
        { value: "RRB NTPC & Railway JE", label: "🚆 RRB NTPC & Railway JE" },
        { value: "JEE Main / Advanced", label: "🎓 JEE Main / Advanced (Engineering)" },
        { value: "NEET-UG Medical Entrance", label: "🩺 NEET-UG Medical Entrance" },
        { value: "GATE Engineering & PSUs", label: "⚡ GATE Engineering & PSUs" },
        { value: "CAT / XAT Management", label: "💼 CAT / XAT (IIMs & Management)" },
        { value: "CA Foundation & Intermediate", label: "📊 CA (Chartered Accountant)" },
      ],
    },
    { name: "title", label: "Lecture Title", type: "text", required: true, placeholder: "e.g. Indian Polity & Constitution Masterclass" },
    { name: "subject", label: "Subject / Topic", type: "text", required: true, placeholder: "e.g. General Studies / Mathematics / Quant" },
    { name: "duration", label: "Lecture Duration", type: "text", required: false, placeholder: "e.g. 25:00" },
    { name: "publicUrl", label: "S3 Video Stream URL / External Link", type: "text", required: false, placeholder: "https://myvault-files-app.s3.eu-north-1.amazonaws.com/video.mp4" },
  ],
};

export default function ExamsAdminPage() {
  return (
    <div className="mx-auto max-w-2xl px-4 py-10">
      <h1 className="mb-1 text-xl font-semibold text-white">Upload Competitive Exam Video Lecture & PDF Notes</h1>
      <p className="mb-6 text-sm text-white/50">
        Upload video lectures and PDF resources to AWS S3 for UPSC, SSC, Banking, JEE, NEET, GATE, CAT, and CA competitive exams.
      </p>
      <UploadForm config={examConfig} />
    </div>
  );
}
