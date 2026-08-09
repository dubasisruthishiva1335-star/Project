import { UploadForm, type UploadFormConfig } from "@/components/admin/UploadForm";

const resultsConfig: UploadFormConfig = {
  domain: "results",
  confirmPath: "/admin/results/confirm",
  acceptedFileTypes: "application/pdf,image/*",
  successMessage: "Result published — the student can view it immediately.",
  fields: [
    { name: "hallTicket", label: "Hall Ticket Number", type: "text", required: true, placeholder: "21A91A0501" },
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
  ],
};

export default function ResultsAdminPage() {
  return (
    <div className="mx-auto max-w-2xl px-4 py-10">
      <h1 className="mb-1 text-xl font-semibold text-white">Upload Result Marksheet</h1>
      <p className="mb-6 text-sm text-white/50">Tie a marksheet PDF or image to a specific hall ticket and Year.</p>
      <UploadForm config={resultsConfig} />
    </div>
  );
}
