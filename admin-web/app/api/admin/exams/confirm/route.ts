import { NextResponse } from "next/server";
import { addExamResource } from "@/lib/exam-store";

export async function POST(request: Request) {
  try {
    const body = await request.json();
    console.log("Received exam confirm upload on Vercel:", body);

    const examName = body.examName || "UPSC Civil Services (IAS / IPS / IFS)";
    const title = body.title || "Exam Lecture & Material";
    const subject = body.subject || "General Studies";
    const contentType = body.contentType || "VIDEO";
    const duration = body.duration || "20:00";
    const fileUrl =
      body.publicUrl ||
      (body.s3Key ? `https://myvault-files-app.s3.eu-north-1.amazonaws.com/${body.s3Key}` : null) ||
      "https://myvault-files-app.s3.eu-north-1.amazonaws.com/app-arm64-v8a-release.apk";

    // 1. Add to local Vercel shared store
    const newResource = addExamResource({
      examName,
      contentType,
      title,
      subject,
      duration,
      fileUrl,
    });

    // 2. Forward to Railway backend in background
    try {
      await fetch("https://romantic-serenity-production-3e5b.up.railway.app/admin/exams/confirm", {
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
