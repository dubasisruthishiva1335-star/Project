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

let mockCourses: CourseItem[] = [
  {
    id: "course_fullstack_2026",
    title: "Full Stack Web & Cloud Engineering",
    category: "Web Development",
    level: "All Levels",
    duration: "45 Hours (42 Lessons)",
    instructor: "MyVault Engineering Academy",
    thumbnail: "https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=800&auto=format&fit=crop&q=60",
    description: "Master modern full-stack development with React, Node.js, Express, PostgreSQL, REST APIs, Docker, and Cloud Deployment.",
    modulesCount: 5,
    lessonsCount: 42,
    quizzesCount: 10,
    assignmentsCount: 5,
    passingScore: 70,
    certEnabled: true,
    status: "PUBLISHED",
    enrolledCount: 1420,
    rating: 4.9,
    postedAt: new Date(Date.now() - 5 * 86400000).toISOString(),
  },
  {
    id: "course_python_ai_2026",
    title: "Python Programming & AI/ML Mastery",
    category: "AI & Machine Learning",
    level: "All Levels",
    duration: "38 Hours (35 Lessons)",
    instructor: "AI Research Labs",
    thumbnail: "https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=800&auto=format&fit=crop&q=60",
    description: "From Python fundamentals to NumPy, Pandas, Scikit-Learn, PyTorch, Neural Networks, and Generative AI applications.",
    modulesCount: 6,
    lessonsCount: 35,
    quizzesCount: 8,
    assignmentsCount: 6,
    passingScore: 70,
    certEnabled: true,
    status: "PUBLISHED",
    enrolledCount: 980,
    rating: 4.8,
    postedAt: new Date(Date.now() - 10 * 86400000).toISOString(),
  },
  {
    id: "course_cloud_devops_2026",
    title: "Cloud Computing & AWS Architecture",
    category: "Cloud & DevOps",
    level: "Intermediate",
    duration: "30 Hours (28 Lessons)",
    instructor: "Cloud Solutions Architects",
    thumbnail: "https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=800&auto=format&fit=crop&q=60",
    description: "Learn AWS services, Docker containerization, Kubernetes orchestration, CI/CD pipelines, and cloud security best practices.",
    modulesCount: 4,
    lessonsCount: 28,
    quizzesCount: 6,
    assignmentsCount: 4,
    passingScore: 65,
    certEnabled: true,
    status: "PUBLISHED",
    enrolledCount: 650,
    rating: 4.7,
    postedAt: new Date(Date.now() - 15 * 86400000).toISOString(),
  }
];

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
            enrolledCount: Number(r.enrolledCount || 120),
            rating: Number(r.rating || 4.9),
            postedAt: r.postedAt || (r.createdAt ? new Date(r.createdAt).toISOString() : new Date().toISOString()),
            modules: r.modules || [],
            finalExamQuestions: r.finalExamQuestions || [],
          }));
        }
      }
    } catch (e) {
      console.error("Failed to query MongoDB courses:", e);
    }

    const dbIds = new Set(dbCourses.map(c => c.id));
    const combined = [...dbCourses, ...mockCourses.filter(m => !dbIds.has(m.id))];

    if (id) {
      const found = combined.find(c => c.id === id);
      if (!found) return NextResponse.json({ error: "Course not found" }, { status: 404 });
      return NextResponse.json(found);
    }

    return NextResponse.json(combined);
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

    mockCourses.unshift(newCourse);

    try {
      const db = await connectDB();
      if (db) {
        await db.collection("courses").insertOne({
          ...newCourse,
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

    mockCourses = mockCourses.filter((c) => c.id !== id);

    try {
      const db = await connectDB();
      if (db) {
        await db.collection("courses").deleteOne({ id });
      }
    } catch (_) {}

    return NextResponse.json({ success: true, id });
  } catch (err: any) {
    return NextResponse.json({ error: err?.message || "Failed to delete course" }, { status: 500 });
  }
}
