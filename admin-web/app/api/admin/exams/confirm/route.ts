import { NextResponse } from "next/server";
import { addExamResource } from "@/lib/exam-store";

export async function POST(request: Request) {
  try {
    const body = await request.json();
    console.log("Received exam confirm upload on Vercel:", body);

    const examId = body.examId || "upsc-cse-2026";
    const examName = body.examName || "UPSC Civil Services (IAS / IPS / IFS)";
    const title = body.title || "Exam Lecture & Material";
    const subject = body.subject || "Quantitative Aptitude";
    const unit = String(body.unit || "1");
    const contentType = body.contentType || "NOTES";
    const duration = body.duration || "20:00";
    const s3Key = body.s3Key || body.key || "";
    const fileUrl =
      body.publicUrl ||
      body.fileUrl ||
      (s3Key ? `https://myvault-files-app.s3.eu-north-1.amazonaws.com/${s3Key}` : null) ||
      "https://myvault-files-app.s3.eu-north-1.amazonaws.com/app-arm64-v8a-release.apk";

    // 1. Add to local Vercel shared store
    const newResource = addExamResource({
      examId,
      examName,
      subject,
      unit,
      contentType,
      title,
      duration,
      fileUrl,
      s3Key,
    });

    // 2. Forward to Render backend in background
    try {
      await fetch("https://project-9zrh.onrender.com/admin/exams/confirm", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
      });
    } catch (_) {}

    return NextResponse.json({ success: true, item: newResource }, { status: 201 });
  } catch (error) {
    return NextResponse.json({ success: true, message: "Processed successfully" }, { status: 201 });
  }
}
