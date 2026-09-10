import { NextResponse } from "next/server";
import { connectDB } from "@/lib/db";

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const branch = (searchParams.get("branch") || "CSE").toUpperCase();
    const semester = Number(searchParams.get("semester")) || 1;

    let notes: any[] = [];
    try {
      const db = await connectDB();
      if (db) {
        const docs = await db.collection("notes").find({ branch, semester }).sort({ createdAt: -1 }).toArray();
        notes = docs;
      }
    } catch (_) {}

    // Group notes by subject name
    const subjectMap = new Map<string, any>();

    notes.forEach(note => {
      const subjectName = note.subject || "General Engineering";
      const subjectCode = subjectName.replace(/[^A-Za-z0-9]/g, "").substring(0, 5).toUpperCase() || "SUB101";

      if (!subjectMap.has(subjectName)) {
        subjectMap.set(subjectName, {
          id: `subj_${branch}_${semester}_${subjectCode}`,
          code: subjectCode,
          name: subjectName,
          branch: branch,
          semester: semester,
          contents: [],
        });
      }

      subjectMap.get(subjectName).contents.push({
        id: note._id?.toString() || note.id,
        title: note.title,
        contentType: note.contentType || "NOTES",
        unit: Number(note.unit) || 1,
        fileUrl: note.fileUrl || note.url,
        fileSize: note.fileSize || "3.5 MB",
        uploadedAt: note.createdAt || new Date().toISOString(),
      });
    });

    return NextResponse.json(Array.from(subjectMap.values()));
  } catch (err: any) {
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}
