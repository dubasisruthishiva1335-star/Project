import { NextResponse } from "next/server";
import { connectDB } from "@/lib/db";

export async function GET() {
  try {
    const db = await connectDB();
    if (db) {
      const courses = await db.collection("courses").find({}).sort({ createdAt: -1 }).toArray();
      if (courses && courses.length > 0) {
        return NextResponse.json(courses);
      }
    }
    return NextResponse.json([]);
  } catch (err: any) {
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}
