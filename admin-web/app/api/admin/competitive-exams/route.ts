import { NextResponse } from "next/server";
import { connectDB } from "@/lib/db";

export interface CompetitiveExamItem {
  id: string;
  examId: string;
  examName: string;
  category: "ENGINEERING" | "CIVIL_SERVICES" | "PLACEMENTS" | "HIGHER_STUDIES" | "BANKING_SSC";
  title: string;
  subject: string;
  unit?: string;
  contentType: "NOTES" | "PYQ_PAPER" | "FORMULA_SHEET" | "MOCK_TEST" | "VIDEO_LECTURE" | "SYLLABUS";
  year: number;
  difficulty: "BEGINNER" | "INTERMEDIATE" | "ADVANCED" | "ALL_LEVELS";
  fileUrl: string;
  s3Key?: string;
  fileSize?: string;
  description?: string;
  author?: string;
  syllabusUrl?: string;
  examDate?: string;
  isFeatured?: boolean;
  downloadsCount?: number;
  uploadedAt: string;
}

const BACKEND_URL = process.env.NEXT_PUBLIC_BACKEND_URL || "https://project-9zrh.onrender.com";

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const category = searchParams.get("category");
    const examId = searchParams.get("examId");
    const contentType = searchParams.get("contentType");

    let dbItems: CompetitiveExamItem[] = [];

    // 1. Fetch from MongoDB
    try {
      const db = await connectDB();
      if (db) {
        const docs = await db.collection("exams").find({}).sort({ createdAt: -1 }).toArray();
        if (Array.isArray(docs)) {
          dbItems = docs.map((r: any) => ({
            id: r.id || (r._id ? r._id.toString() : ""),
            examId: r.examId || r.exam_id || "gate-cs-2026",
            examName: r.examName || r.exam_name || "Competitive Exam",
            category: r.category || "ENGINEERING",
            title: r.title,
            subject: r.subject || "General",
            unit: r.unit || "1",
            contentType: r.contentType || r.content_type || "NOTES",
            year: Number(r.year || 2026),
            difficulty: r.difficulty || "ALL_LEVELS",
            fileUrl: r.fileUrl || r.file_url,
            s3Key: r.s3Key || r.s3_key,
            fileSize: r.fileSize || r.file_size || "3.2 MB",
            description: r.description || "",
            author: r.author || "MyVault Faculty",
            syllabusUrl: r.syllabusUrl || r.syllabus_url || "",
            examDate: r.examDate || r.exam_date || "",
            isFeatured: Boolean(r.isFeatured || r.is_featured),
            downloadsCount: Number(r.downloadsCount || r.downloads_count || 0),
            uploadedAt: r.uploadedAt || r.uploaded_at || (r.createdAt ? new Date(r.createdAt).toISOString() : new Date().toISOString()),
          }));
        }
      }
    } catch (_) {}

    // 2. Fetch from backend DB if MongoDB empty
    if (dbItems.length === 0) {
      try {
        const res = await fetch(`${BACKEND_URL}/exams`, { cache: "no-store" });
        if (res.ok) {
          const rows = await res.json();
          if (Array.isArray(rows)) {
            dbItems = rows.map((r: any) => ({
              id: r.id,
              examId: r.examId || r.exam_id || "gate-cs-2026",
              examName: r.examName || r.exam_name || "Competitive Exam",
              category: r.category || "ENGINEERING",
              title: r.title,
              subject: r.subject || "General",
              unit: r.unit || "1",
              contentType: r.contentType || r.content_type || "NOTES",
              year: Number(r.year || 2026),
              difficulty: r.difficulty || "ALL_LEVELS",
              fileUrl: r.fileUrl || r.file_url,
              s3Key: r.s3Key || r.s3_key,
              fileSize: r.fileSize || r.file_size || "3.2 MB",
              description: r.description || "",
              author: r.author || "MyVault Faculty",
              syllabusUrl: r.syllabusUrl || r.syllabus_url || "",
              examDate: r.examDate || r.exam_date || "",
              isFeatured: Boolean(r.isFeatured || r.is_featured),
              downloadsCount: Number(r.downloadsCount || r.downloads_count || 0),
              uploadedAt: r.uploadedAt || r.uploaded_at || new Date().toISOString(),
            }));
          }
        }
      } catch (e) {
        console.error("Failed to fetch from backend DB exams:", e);
      }
    }

    let result = dbItems;
    if (category && category !== "ALL") {
      result = result.filter(i => i.category === category);
    }
    if (examId && examId !== "ALL") {
      result = result.filter(i => i.examId === examId);
    }
    if (contentType && contentType !== "ALL") {
      result = result.filter(i => i.contentType === contentType);
    }

    return NextResponse.json(result);
  } catch (error: any) {
    return NextResponse.json({ error: error?.message || "Internal server error" }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const newItem: CompetitiveExamItem = {
      id: body.id || "exam_" + Date.now() + "_" + Math.random().toString(36).substring(2, 7),
      examId: body.examId || "gate-cs-2026",
      examName: body.examName || "GATE Computer Science & IT",
      category: body.category || "ENGINEERING",
      title: body.title,
      subject: body.subject || "General",
      unit: body.unit || "1",
      contentType: body.contentType || "NOTES",
      year: Number(body.year) || 2026,
      difficulty: body.difficulty || "ALL_LEVELS",
      fileUrl: body.fileUrl,
      s3Key: body.s3Key || "",
      fileSize: body.fileSize || "2.5 MB",
      description: body.description || "",
      author: body.author || "MyVault Academic Team",
      syllabusUrl: body.syllabusUrl || "",
      examDate: body.examDate || "2026",
      isFeatured: Boolean(body.isFeatured),
      downloadsCount: 0,
      uploadedAt: new Date().toISOString(),
    };

    try {
      const db = await connectDB();
      if (db) {
        await db.collection("exams").insertOne({
          ...newItem,
          _id: newItem.id as any,
          createdAt: new Date(),
        });
      }
    } catch (_) {}

    // Forward to Render backend
    try {
      await fetch(`${BACKEND_URL}/admin/exams/confirm`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(newItem),
      });
    } catch (err) {
      console.error("Failed to forward exam to Render backend:", err);
    }

    return NextResponse.json(newItem, { status: 201 });
  } catch (error: any) {
    return NextResponse.json({ error: error?.message || "Failed to save exam resource" }, { status: 500 });
  }
}

export async function DELETE(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const id = searchParams.get("id");
    if (!id) return NextResponse.json({ error: "ID required" }, { status: 400 });

    try {
      const db = await connectDB();
      if (db) {
        await db.collection("exams").deleteMany({ $or: [{ id }, { _id: id as any }] });
      }
    } catch (_) {}

    try {
      await fetch(`${BACKEND_URL}/admin/exams/${id}`, { method: "DELETE" });
    } catch (_) {}

    return NextResponse.json({ success: true, id });
  } catch (error: any) {
    return NextResponse.json({ error: error?.message || "Failed to delete exam resource" }, { status: 500 });
  }
}
