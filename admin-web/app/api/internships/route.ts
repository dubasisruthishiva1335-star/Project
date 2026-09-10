import { NextResponse } from "next/server";
import { connectDB } from "@/lib/db";

export async function GET() {
  try {
    const db = await connectDB();
    if (db) {
      const internships = await db.collection("internships").find({}).sort({ createdAt: -1 }).toArray();
      return NextResponse.json(internships);
    }
    return NextResponse.json([]);
  } catch (err: any) {
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}
