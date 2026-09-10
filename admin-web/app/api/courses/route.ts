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
    
    return NextResponse.json([
      {
        id: "course_fullstack_2026",
        title: "Full Stack Web & Cloud Engineering",
        category: "Web Development",
        level: "All Levels",
        duration: "45 Hours (42 Lessons)",
        instructor: "MyVault Engineering Academy",
        thumbnail: "https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=800&auto=format&fit=crop&q=60",
        description: "Master modern full-stack engineering: React, Node.js, Express, PostgreSQL, Docker, Microservices, and Cloud Deployment.",
        modulesCount: 5,
        lessonsCount: 42,
        quizzesCount: 10,
        passingScore: 70,
        certEnabled: true,
        rating: 4.9,
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
        passingScore: 70,
        certEnabled: true,
        rating: 4.8,
      }
    ]);
  } catch (err: any) {
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}
