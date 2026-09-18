import { NextResponse } from "next/server";
import { connectDB } from "@/lib/db";

export async function POST(request: Request) {
  try {
    const body = await request.json();

    const noteRecord = {
      id: body.id || `note_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
      title: body.title || "Academic Resource",
      branch: (body.branch || "ECE").toUpperCase(),
      semester: Number(body.semester) || 1,
      unit: Number(body.unit) || 1,
      subject: body.subject || body.title?.split("—")?.[0]?.trim() || "General Engineering",
      contentType: body.contentType || "NOTES",
      fileUrl: body.fileUrl || body.publicUrl || body.url || "",
      s3Key: body.s3Key || body.key || "",
      fileSize: body.fileSize || "2.5 MB",
      author: body.author || "Faculty / Admin",
      createdAt: new Date().toISOString(),
    };

    // Save to MongoDB collection
    try {
      const db = await connectDB();
      if (db) {
        await db.collection("notes").insertOne({
          ...noteRecord,
          _id: noteRecord.id as any,
          createdAt: new Date(),
        });
      }
    } catch (dbErr) {
      console.warn("MongoDB note confirm insert error:", dbErr);
    }

    // Forward to backend service if active
    try {
      await fetch("https://project-9zrh.onrender.com/admin/notes/confirm", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(noteRecord),
      });
    } catch (_) {}

    return NextResponse.json(noteRecord, { status: 201 });
  } catch (error: any) {
    console.error("Notes confirm forward error:", error);
    return NextResponse.json(
      { error: error?.message || "Internal server error" },
      { status: 500 }
    );
  }
}
