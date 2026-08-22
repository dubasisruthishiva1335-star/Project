// lib/exam-store.ts
// Shared store for Competitive Exam materials uploaded via Admin Web

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

// Clean & empty initial store — only displays user-uploaded content
export let uploadedExamResources: ExamResource[] = [];

export function addExamResource(resource: Omit<ExamResource, "id" | "uploadedAt">) {
  const newResource: ExamResource = {
    ...resource,
    id: `res_${Date.now()}_${Math.floor(Math.random() * 1000)}`,
    uploadedAt: new Date().toISOString(),
  };
  uploadedExamResources.unshift(newResource);
  return newResource;
}

export function clearExamResources() {
  uploadedExamResources = [];
}
