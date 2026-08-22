// lib/exam-store.ts
// Shared in-memory store for Competitive Exam materials uploaded via Admin Web

export interface ExamResource {
  id: string;
  examName: string;
  contentType: "VIDEO" | "PDF" | "SYLLABUS";
  title: string;
  subject: string;
  duration?: string;
  fileUrl: string;
  uploadedAt: string;
}

export let uploadedExamResources: ExamResource[] = [
  {
    id: "res_demo_01",
    examName: "UPSC Civil Services (IAS / IPS / IFS)",
    contentType: "VIDEO",
    title: "Indian Polity Fundamental Rights & Important Articles",
    subject: "Indian Polity",
    duration: "25:40",
    fileUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
    uploadedAt: new Date().toISOString(),
  },
  {
    id: "res_demo_02",
    examName: "UPSC Civil Services (IAS / IPS / IFS)",
    contentType: "PDF",
    title: "UPSC Prelims Last 10 Years Solved Question Paper",
    subject: "PYQs",
    fileUrl: "https://myvault-files-app.s3.eu-north-1.amazonaws.com/app-arm64-v8a-release.apk",
    uploadedAt: new Date().toISOString(),
  },
];

export function addExamResource(resource: Omit<ExamResource, "id" | "uploadedAt">) {
  const newResource: ExamResource = {
    ...resource,
    id: `res_${Date.now()}_${Math.floor(Math.random() * 1000)}`,
    uploadedAt: new Date().toISOString(),
  };
  uploadedExamResources.unshift(newResource);
  return newResource;
}
