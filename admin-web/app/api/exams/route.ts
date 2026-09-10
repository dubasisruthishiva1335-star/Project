import { NextResponse } from "next/server";
import { connectDB } from "@/lib/db";

export async function GET() {
  try {
    const db = await connectDB();
    if (db) {
      const exams = await db.collection("exams").find({}).sort({ createdAt: -1 }).toArray();
      return NextResponse.json(exams);
    }
    return NextResponse.json([]);
  } catch (err: any) {
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}
