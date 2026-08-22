// lib/exam-store.ts
// Shared in-memory store for Competitive Exam materials uploaded via Admin Web

export interface ExamResource {
  id: string;
  examId: string;
  examName?: string;
  subject: string;
  unit: string;
  contentType: string;
  title: string;
  duration?: string;
  fileUrl: string;
  s3Key?: string;
  createdAt: string;
}

export let uploadedExamResources: ExamResource[] = [
  {
    id: "sample_upsc_1",
    examId: "upsc-cse-2026",
    examName: "UPSC Civil Services (IAS / IPS / IFS)",
    subject: "Quantitative Aptitude",
    unit: "1",
    contentType: "NOTES",
    title: "cv",
    fileUrl: "https://myvault-files-app.s3.eu-north-1.amazonaws.com/exams/upsc-cse-2026/1787398331254_ilovepdf_merged.pdf",
    createdAt: new Date().toISOString(),
  },
];

export function addExamResource(resource: Omit<ExamResource, "id" | "createdAt">) {
  const newResource: ExamResource = {
    ...resource,
    id: `res_${Date.now()}_${Math.floor(Math.random() * 1000)}`,
    createdAt: new Date().toISOString(),
  };
  uploadedExamResources.unshift(newResource);
  return newResource;
}

export function clearExamResources() {
  uploadedExamResources = [];
}
