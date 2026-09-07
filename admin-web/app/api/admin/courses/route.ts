import { NextResponse } from "next/server";

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

const BACKEND_URL = process.env.NEXT_PUBLIC_BACKEND_URL || "https://project-9zrh.onrender.com";

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const id = searchParams.get("id");

    let dbCourses: CourseItem[] = [];
    try {
      const res = await fetch(`${BACKEND_URL}/internships`, { cache: "no-store" });
      if (res.ok) {
        const rows = await res.json();
        if (Array.isArray(rows)) {
          dbCourses = rows.map((r: any) => ({
            id: r.id,
            title: r.title,
            category: r.category || "Software Development",
            level: "All Levels",
            duration: r.duration || "30 Hours",
            instructor: r.company || "MyVault Faculty",
            thumbnail: r.thumbnail || "https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=800&auto=format&fit=crop&q=60",
            description: r.description || "Comprehensive hands-on technical course.",
            modulesCount: Number(r.module_count || 4),
            lessonsCount: Number(r.lesson_count || 24),
            quizzesCount: 6,
            assignmentsCount: 3,
            passingScore: 70,
            certEnabled: true,
            status: "PUBLISHED",
            enrolledCount: Number(r.enrollment_count || 120),
            rating: 4.8,
            postedAt: r.posted_at || new Date().toISOString(),
          }));
        }
      }
    } catch (_) {}

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
      modulesCount: Number(body.modulesCount || 4),
      lessonsCount: Number(body.lessonsCount || 24),
      quizzesCount: Number(body.quizzesCount || 6),
      assignmentsCount: Number(body.assignmentsCount || 3),
      passingScore: Number(body.passingScore || 70),
      certEnabled: body.certEnabled !== false,
      status: "PUBLISHED",
      enrolledCount: 0,
      rating: 5.0,
      postedAt: new Date().toISOString(),
    };

    mockCourses.unshift(newCourse);

    try {
      await fetch(`${BACKEND_URL}/admin/internships/confirm`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          id: newCourse.id,
          title: newCourse.title,
          company: newCourse.instructor,
          type: "COURSE",
          category: newCourse.category,
          duration: newCourse.duration,
          description: newCourse.description,
          status: "PUBLISHED",
          isLmsEnabled: true,
          certificateEnabled: newCourse.certEnabled,
        }),
      });
    } catch (_) {}

    return NextResponse.json(newCourse, { status: 201 });
  } catch (err: any) {
    return NextResponse.json({ error: err?.message || "Failed to create course" }, { status: 500 });
  }
}