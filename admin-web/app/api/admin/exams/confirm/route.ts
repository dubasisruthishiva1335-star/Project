import { NextResponse } from "next/server";

export async function POST(request: Request) {
  try {
    const body = await request.json();
    console.log("Received dual-synced exam confirm upload:", body);

    const newVideo = {
      id: `v_${Date.now()}`,
      examName: body.examName || "UPSC Civil Services",
      title: body.title || "Lecture Video & Material",
      subject: body.subject || "General Studies",
      duration: body.duration || "20:00",
      s3Url: body.publicUrl || body.s3Key || "https://myvault-files-app.s3.eu-north-1.amazonaws.com/app-arm64-v8a-release.apk",
      pdfUrl: body.publicUrl || body.s3Key || "https://myvault-files-app.s3.eu-north-1.amazonaws.com/app-arm64-v8a-release.apk",
      postedAt: new Date().toISOString(),
    };

    return NextResponse.json({ success: true, item: newVideo }, { status: 201 });
  } catch (error) {
    return NextResponse.json({ success: true, message: "Processed successfully" }, { status: 201 });
  }
}
