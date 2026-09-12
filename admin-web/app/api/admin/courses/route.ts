import { NextResponse } from "next/server";
import { connectDB } from "@/lib/db";

export interface CourseItem {
  id: string;
  title: string;
  category: string;
  level: "Beginner" | "Intermediate" | "Advanced" | "All Levels";
  duration: string;
  instructor: string;
  thumbnail?: string;
  description: string;
  modulesCount: number;
  lessonsCount: number;
  quizzesCount: number;
  assignmentsCount: number;
  passingScore: number;
  certEnabled: boolean;
  status: "PUBLISHED" | "DRAFT";
  enrolledCount: number;
  rating: number;
  postedAt: string;
  modules?: any[];
  finalExamQuestions?: any[];
}

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const id = searchParams.get("id");

    let dbCourses: CourseItem[] = [];
    try {
      const db = await connectDB();
      if (db) {
        const rows = await db.collection("courses").find({}).sort({ createdAt: -1 }).toArray();
        if (Array.isArray(rows)) {
          dbCourses = rows.map((r: any) => ({
            id: r.id || (r._id ? r._id.toString() : ""),
            title: r.title,
            category: r.category || "Web Development",
            level: r.level || "All Levels",
            duration: r.duration || "30 Hours",
            instructor: r.instructor || "MyVault Faculty",
            thumbnail: r.thumbnail || r.url || "https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=800&auto=format&fit=crop&q=60",
            description: r.description || "Comprehensive hands-on course.",
            modulesCount: Number(r.modulesCount || (r.modules ? r.modules.length : 4)),
            lessonsCount: Number(r.lessonsCount || 24),
            quizzesCount: Number(r.quizzesCount || 6),
            assignmentsCount: Number(r.assignmentsCount || 3),
            passingScore: Number(r.passingScore || 70),
            certEnabled: r.certEnabled !== false,
            status: (r.status as any) || "PUBLISHED",
            enrolledCount: Number(r.enrolledCount || 0),
            rating: Number(r.rating || 5.0),
            postedAt: r.postedAt || (r.createdAt ? new Date(r.createdAt).toISOString() : new Date().toISOString()),
            modules: r.modules || [],
            finalExamQuestions: r.finalExamQuestions || [],
          }));
        }
      }
    } catch (e) {
      console.error("Failed to query MongoDB courses:", e);
    }

    if (id) {
      const found = dbCourses.find(c => c.id === id);
      if (!found) return NextResponse.json({ error: "Course not found" }, { status: 404 });
      return NextResponse.json(found);
    }

    return NextResponse.json(dbCourses);
  } catch (err: any) {
    return NextResponse.json({ error: err?.message || "Internal server error" }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const newCourse: CourseItem = {
      id: body.id || "course_" + Date.now() + "_" + Math.random().toString(36).substring(2, 7),
      title: body.title,
      category: body.category || "Web Development",
      level: body.level || "All Levels",
      duration: body.duration || "32 Hours",
      instructor: body.instructor || "MyVault Faculty",
      thumbnail: body.thumbnail || "https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=800&auto=format&fit=crop&q=60",
      description: body.description || "",
      modulesCount: Number(body.modulesCount || (body.modules ? body.modules.length : 4)),
      lessonsCount: Number(body.lessonsCount || 24),
      quizzesCount: Number(body.quizzesCount || 6),
      assignmentsCount: Number(body.assignmentsCount || 3),
      passingScore: Number(body.passingScore || 70),
      certEnabled: body.certEnabled !== false,
      status: "PUBLISHED",
      enrolledCount: 0,
      rating: 5.0,
      postedAt: new Date().toISOString(),
      modules: body.modules || [],
      finalExamQuestions: body.finalExamQuestions || [],
    };

    try {
      const db = await connectDB();
      if (db) {
        await db.collection("courses").insertOne({
          ...newCourse,
          _id: newCourse.id as any,
          createdAt: new Date(),
        });
      }
    } catch (e) {
      console.warn("MongoDB course insert notice:", e);
    }

    return NextResponse.json(newCourse, { status: 201 });
  } catch (err: any) {
    return NextResponse.json({ error: err?.message || "Failed to create course" }, { status: 500 });
  }
}

export async function DELETE(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const id = searchParams.get("id");
    if (!id) return NextResponse.json({ error: "Course ID is required" }, { status: 400 });

    try {
      const db = await connectDB();
      if (db) {
        await db.collection("courses").deleteMany({ $or: [{ id }, { _id: id as any }] });
      }
    } catch (_) {}

    return NextResponse.json({ success: true, id });
  } catch (err: any) {
    return NextResponse.json({ error: err?.message || "Failed to delete course" }, { status: 500 });
  }
}
