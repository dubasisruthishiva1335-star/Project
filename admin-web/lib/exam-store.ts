export interface UploadedExamResource {
  id: string;
  examId?: string;
  examName?: string;
  cat?: string;
  title: string;
  subject: string;
  contentType: string;
  fileUrl: string;
  duration?: string;
  uploadedAt: string;
  unit?: string;
  s3Key?: string;
}

export const uploadedExamResources: UploadedExamResource[] = [];

export function addExamResource(data: {
  examId?: string;
  examName?: string;
  subject: string;
  unit?: string;
  contentType: string;
  title: string;
  duration?: string;
  fileUrl: string;
  s3Key?: string;
}): UploadedExamResource {
  const newRes: UploadedExamResource = {
    id: `exam_res_${Date.now()}`,
    examId: data.examId,
    examName: data.examName,
    subject: data.subject,
    unit: data.unit,
    contentType: data.contentType,
    title: data.title,
    duration: data.duration,
    fileUrl: data.fileUrl,
    s3Key: data.s3Key,
    uploadedAt: new Date().toISOString(),
  };

  uploadedExamResources.unshift(newRes);
  return newRes;
}
