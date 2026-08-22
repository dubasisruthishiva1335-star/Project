import { NextResponse } from "next/server";
import { uploadedExamResources, addExamResource } from "@/lib/exam-store";

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const examId = searchParams.get("examId");
  const contentType = searchParams.get("contentType");

  let filtered = [...uploadedExamResources];

  if (examId && examId !== "All") {
    const target = examId.toLowerCase();
    filtered = filtered.filter((r) => {
      const id = (r.examId || "").toLowerCase();
      const name = (r.examName || "").toLowerCase();
      return id === target || id.includes(target) || target.includes(id) || name.includes(target);
    });
  }

  if (contentType && contentType !== "All") {
    filtered = filtered.filter((r) => r.contentType.toUpperCase() === contentType.toUpperCase());
  }

  return NextResponse.json({
    success: true,
    data: filtered,
  });
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    console.log("Received preparation content upload on Vercel:", body);

    const examId = body.examId || "upsc-cse-2026";
    const subject = body.subject || "Quantitative Aptitude";
    const unit = String(body.unit || "1");
    const contentType = body.contentType || "NOTES";
    const title = body.title || "Uploaded Resource";
    const s3Key = body.s3Key || body.key || "";
    const fileUrl =
      body.publicUrl ||
      body.fileUrl ||
      (s3Key ? `https://myvault-files-app.s3.eu-north-1.amazonaws.com/${s3Key}` : null) ||
      "https://myvault-files-app.s3.eu-north-1.amazonaws.com/app-arm64-v8a-release.apk";

    const newItem = addExamResource({
      examId,
      subject,
      unit,
      contentType,
      title,
      fileUrl,
      s3Key,
    });

    // Forward to Railway backend as well
    try {
      await fetch("https://romantic-serenity-production-3e5b.up.railway.app/api/uploads/confirm", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
      });
    } catch (_) {}

    return NextResponse.json({ success: true, item: newItem }, { status: 201 });
  } catch (err: any) {
    return NextResponse.json({ error: "Failed to save: " + err.message }, { status: 500 });
  }
}
