import { NextResponse } from "next/server";
import { connectDB } from "@/lib/db";

export async function POST() {
  try {
    let mongoDeleted = { notes: 0, courses: 0, internships: 0, exams: 0 };
    
    // 1. Wipe all MongoDB collections
    try {
      const db = await connectDB();
      if (db) {
        const nRes = await db.collection("notes").deleteMany({});
        const cRes = await db.collection("courses").deleteMany({});
        const iRes = await db.collection("internships").deleteMany({});
        const eRes = await db.collection("exams").deleteMany({});
        mongoDeleted = {
          notes: nRes.deletedCount,
          courses: cRes.deletedCount,
          internships: iRes.deletedCount,
          exams: eRes.deletedCount,
        };
      }
    } catch (e: any) {
      console.error("MongoDB wipe error:", e);
    }

    return NextResponse.json({
      success: true,
      message: "All hub data, notes, courses, exams, and internships have been wiped clean across all databases.",
      mongoDeleted,
    });
  } catch (err: any) {
    return NextResponse.json({ error: err?.message || "Failed to wipe data" }, { status: 500 });
  }
}
