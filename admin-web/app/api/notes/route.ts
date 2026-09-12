import { NextResponse } from "next/server";
import { connectDB } from "@/lib/db";

export interface NoteItem {
  id: string;
  title: string;
  branch: string;
  semester: number;
  unit: number;
  subject: string;
  contentType: string;
  description?: string;
  fileUrl?: string;
  s3Key?: string;
  fileSize?: string;
  author?: string;
  createdAt: string;
}

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const branch = searchParams.get("branch");
    const semester = searchParams.get("semester");

    let dbNotes: NoteItem[] = [];
    try {
      const db = await connectDB();
      if (db) {
        const query: any = {};
        if (branch && branch !== "ALL") query.branch = branch.toUpperCase();
        if (semester && semester !== "ALL") query.semester = Number(semester);
        const docs = await db.collection("notes").find(query).sort({ createdAt: -1 }).toArray();
        dbNotes = docs.map(d => ({
          id: d.id || d._id?.toString() || "",
          title: d.title || "Academic Note",
          branch: (d.branch || "ECE").toUpperCase(),
          semester: Number(d.semester) || 1,
          unit: Number(d.unit) || 1,
          subject: d.subject || "General",
          contentType: d.contentType || "NOTES",
          description: d.description || "",
          fileUrl: d.fileUrl || d.url || "",
          s3Key: d.s3Key || "",
          fileSize: d.fileSize || "3.5 MB",
          author: d.author || "Faculty",
          createdAt: d.createdAt ? new Date(d.createdAt).toISOString() : new Date().toISOString(),
        }));
      }
    } catch (_) {}

    return NextResponse.json(dbNotes);
  } catch (err: any) {
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const newNote: NoteItem = {
      id: body.id || `note_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
      title: body.title || "Untitled Study Material",
      branch: (body.branch || "ECE").toUpperCase(),
      semester: Number(body.semester) || 1,
      unit: Number(body.unit) || 1,
      subject: body.subject || "General Engineering",
      contentType: body.contentType || "NOTES",
      description: body.description || "",
      fileUrl: body.fileUrl || body.url || "",
      s3Key: body.s3Key || "",
      fileSize: body.fileSize || "2.5 MB",
      author: body.author || "Faculty / Admin",
      createdAt: new Date().toISOString(),
    };

    try {
      const db = await connectDB();
      if (db) {
        await db.collection("notes").insertOne({
          ...newNote,
          _id: newNote.id as any,
          createdAt: new Date(),
        });
      }
    } catch (dbErr) {
      console.warn("MongoDB note insert warning:", dbErr);
    }

    return NextResponse.json(newNote, { status: 201 });
  } catch (err: any) {
    return NextResponse.json({ error: err.message }, { status: 500 });
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
        await db.collection("notes").deleteMany({
          $or: [
            { id: id },
            { _id: id as any },
          ]
        });
      }
    } catch (_) {}

    return NextResponse.json({ success: true, id });
  } catch (err: any) {
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}
