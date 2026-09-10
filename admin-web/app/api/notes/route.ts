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

let mockNotes: NoteItem[] = [
  {
    id: "note_1789067388059",
    title: "nvkg",
    branch: "ECE",
    semester: 1,
    unit: 1,
    subject: "Basic Electronics Engineering",
    contentType: "NOTES",
    fileUrl: "https://myvault-files-app.s3.eu-north-1.amazonaws.com/notes/1789067388059-caste_certificate.pdf",
    s3Key: "notes/1789067388059-caste_certificate.pdf",
    fileSize: "1.2 MB",
    author: "Admin Portal",
    createdAt: "2026-09-11T00:30:00Z",
  },
  {
    id: "note_1789066241387",
    title: "bhgvgvhbnjmkhbhn",
    branch: "ECE",
    semester: 1,
    unit: 1,
    subject: "hbh",
    contentType: "NOTES",
    fileUrl: "https://myvault-files-app.s3.eu-north-1.amazonaws.com/notes/1789066241387-apaar-id.pdf",
    s3Key: "notes/1789066241387-apaar-id.pdf",
    fileSize: "850 KB",
    author: "Admin Portal",
    createdAt: "2026-09-11T00:20:00Z",
  },
  {
    id: "note_1789066155057",
    title: "hgv gjn mk,",
    branch: "ECE",
    semester: 1,
    unit: 1,
    subject: "hjgyhuj",
    contentType: "NOTES",
    fileUrl: "https://myvault-files-app.s3.eu-north-1.amazonaws.com/notes/1789066155057-apaar-id.pdf",
    s3Key: "notes/1789066155057-apaar-id.pdf",
    fileSize: "850 KB",
    author: "Admin Portal",
    createdAt: "2026-09-11T00:15:00Z",
  },
  {
    id: "note_ece_sem1_ec101_u1",
    title: "Unit 1 — Semiconductor Diodes & Applications",
    branch: "ECE",
    semester: 1,
    unit: 1,
    subject: "Basic Electronics Engineering",
    contentType: "NOTES",
    fileUrl: "https://myvault-files-app.s3.eu-north-1.amazonaws.com/notes/basic_electronics_u1.pdf",
    s3Key: "notes/basic_electronics_u1.pdf",
    fileSize: "4.2 MB",
    author: "Dept. of ECE Faculty",
    createdAt: "2026-09-10T10:00:00Z",
  },
  {
    id: "note_cse_sem3_cs301_u1",
    title: "Unit 1 — Asymptotic Notation & Array Analysis",
    branch: "CSE",
    semester: 3,
    unit: 1,
    subject: "Data Structures & Algorithms",
    contentType: "NOTES",
    fileUrl: "https://myvault-files-app.s3.eu-north-1.amazonaws.com/notes/dsa_unit1_asymptotic.pdf",
    s3Key: "notes/dsa_unit1_asymptotic.pdf",
    fileSize: "5.1 MB",
    author: "Dept. of CSE Mentors",
    createdAt: "2026-09-10T09:00:00Z",
  }
];

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
          id: d._id?.toString() || d.id,
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

    const noteMap = new Map<string, NoteItem>();
    [...mockNotes, ...dbNotes].forEach(n => {
      noteMap.set(n.id, n);
    });

    let combined = Array.from(noteMap.values());
    if (branch && branch !== "ALL") {
      combined = combined.filter(n => n.branch.toUpperCase() === branch.toUpperCase());
    }
    if (semester && semester !== "ALL") {
      combined = combined.filter(n => n.semester === Number(semester));
    }

    return NextResponse.json(combined);
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

    mockNotes.unshift(newNote);

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

    mockNotes = mockNotes.filter(n => n.id !== id);

    try {
      const db = await connectDB();
      if (db) {
        await db.collection("notes").deleteOne({ _id: id as any });
        await db.collection("notes").deleteOne({ id });
      }
    } catch (_) {}

    return NextResponse.json({ success: true, id });
  } catch (err: any) {
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}
