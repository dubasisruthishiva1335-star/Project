import { NextResponse } from "next/server";

export interface CompetitiveExamItem {
  id: string;
  examId: string;
  examName: string;
  category: "ENGINEERING" | "CIVIL_SERVICES" | "PLACEMENTS" | "HIGHER_STUDIES" | "BANKING_SSC";
  title: string;
  subject: string;
  unit?: string;
  contentType: "NOTES" | "PYQ_PAPER" | "FORMULA_SHEET" | "MOCK_TEST" | "VIDEO_LECTURE" | "SYLLABUS";
  year: number;
  difficulty: "BEGINNER" | "INTERMEDIATE" | "ADVANCED" | "ALL_LEVELS";
  fileUrl: string;
  s3Key?: string;
  fileSize?: string;
  description?: string;
  author?: string;
  syllabusUrl?: string;
  examDate?: string;
  isFeatured?: boolean;
  downloadsCount?: number;
  uploadedAt: string;
}

let mockExams: CompetitiveExamItem[] = [
  {
    id: "exam_gate_cs_pyq_2025",
    examId: "gate-cs-2026",
    examName: "GATE Computer Science & IT (2026)",
    category: "ENGINEERING",
    title: "GATE CS Last 10 Years Solved PYQ Question Bank (2015-2025)",
    subject: "Full Syllabus (Algorithms, Networks, OS, DBMS)",
    contentType: "PYQ_PAPER",
    year: 2026,
    difficulty: "ADVANCED",
    fileUrl: "https://myvault-files-app.s3.eu-north-1.amazonaws.com/exams/gate-cs/gate_cs_solved_pyq_bank.pdf",
    s3Key: "exams/gate-cs/gate_cs_solved_pyq_bank.pdf",
    fileSize: "14.2 MB",
    description: "Complete chapter-wise solved GATE Computer Science question papers with in-depth step-by-step solutions and marks distribution.",
    author: "IIT Alumni & Gateforum Faculty",
    syllabusUrl: "https://gate2026.iitkgp.ac.in",
    examDate: "Feb 07, 2026",
    isFeatured: true,
    downloadsCount: 1420,
    uploadedAt: new Date(Date.now() - 2 * 86400000).toISOString(),
  },
  {
    id: "exam_gate_formula_handbook",
    examId: "gate-cs-2026",
    examName: "GATE Computer Science & IT (2026)",
    category: "ENGINEERING",
    title: "Ultimate High-Yield Formula & Quick Revision Handbook",
    subject: "Engineering Mathematics & Discrete Structures",
    contentType: "FORMULA_SHEET",
    year: 2026,
    difficulty: "ALL_LEVELS",
    fileUrl: "https://myvault-files-app.s3.eu-north-1.amazonaws.com/exams/gate-cs/gate_cs_quick_formula_handbook.pdf",
    s3Key: "exams/gate-cs/gate_cs_quick_formula_handbook.pdf",
    fileSize: "5.8 MB",
    description: "Every essential formula, theorem, time complexity cheat sheet, and recurrence relation for fast last-minute revision.",
    author: "MyVault Senior Tech Mentors",
    syllabusUrl: "https://gate2026.iitkgp.ac.in",
    examDate: "Feb 07, 2026",
    isFeatured: true,
    downloadsCount: 890,
    uploadedAt: new Date(Date.now() - 4 * 86400000).toISOString(),
  },
  {
    id: "exam_tcs_nqt_prep_2026",
    examId: "tcs-nqt-2026",
    examName: "TCS NQT & IT Campus Placements (2026)",
    category: "PLACEMENTS",
    title: "TCS NQT 2026 Comprehensive Foundation & Advanced Coding Kit",
    subject: "Numerical Ability, Verbal & Hands-On Coding",
    contentType: "NOTES",
    year: 2026,
    difficulty: "INTERMEDIATE",
    fileUrl: "https://myvault-files-app.s3.eu-north-1.amazonaws.com/exams/placements/tcs_nqt_master_preparation_kit.pdf",
    s3Key: "exams/placements/tcs_nqt_master_preparation_kit.pdf",
    fileSize: "8.6 MB",
    description: "Contains 100+ solved numerical aptitude problems, reasoning shortcuts, and Python/C++ code templates for TCS NQT Ninja & Prime roles.",
    author: "Campus Placement Cell",
    syllabusUrl: "https://learning.tcsionhub.in",
    examDate: "Nov 2025 - Jan 2026",
    isFeatured: true,
    downloadsCount: 2310,
    uploadedAt: new Date(Date.now() - 1 * 86400000).toISOString(),
  },
  {
    id: "exam_upsc_polity_handbook",
    examId: "upsc-cse-2026",
    examName: "UPSC Civil Services Examination (2026)",
    category: "CIVIL_SERVICES",
    title: "Indian Polity & Constitution Fast-Track Revision Notes",
    subject: "GS Paper II (Polity, Governance, Constitution)",
    contentType: "NOTES",
    year: 2026,
    difficulty: "ADVANCED",
    fileUrl: "https://myvault-files-app.s3.eu-north-1.amazonaws.com/exams/upsc/upsc_indian_polity_revision.pdf",
    s3Key: "exams/upsc/upsc_indian_polity_revision.pdf",
    fileSize: "11.4 MB",
    description: "Summarized articles, constitutional amendments, landmark Supreme Court judgments, and key statutory bodies.",
    author: "IAS Mentorship Cell",
    syllabusUrl: "https://upsc.gov.in",
    examDate: "May 24, 2026",
    isFeatured: false,
    downloadsCount: 780,
    uploadedAt: new Date(Date.now() - 5 * 86400000).toISOString(),
  },
  {
    id: "exam_cat_quant_mastery",
    examId: "cat-2026",
    examName: "CAT (IIMs & Top B-Schools 2026)",
    category: "HIGHER_STUDIES",
    title: "CAT Quantitative Aptitude & Data Interpretation Master Strategy",
    subject: "QA, DILR & Arithmetic Shortcuts",
    contentType: "FORMULA_SHEET",
    year: 2026,
    difficulty: "ADVANCED",
    fileUrl: "https://myvault-files-app.s3.eu-north-1.amazonaws.com/exams/cat/cat_quant_dilr_shortcuts.pdf",
    s3Key: "exams/cat/cat_quant_dilr_shortcuts.pdf",
    fileSize: "6.2 MB",
    description: "Speed math techniques, geometry theorems, modern math shortcuts, and matrix-based DILR problem-solving frameworks.",
    author: "99.8%ile CAT Faculty",
    syllabusUrl: "https://iimcat.ac.in",
    examDate: "Nov 30, 2025",
    isFeatured: false,
    downloadsCount: 650,
    uploadedAt: new Date(Date.now() - 6 * 86400000).toISOString(),
  },
  {
    id: "exam_dsa_maang_interview",
    examId: "maang-dsa-2026",
    examName: "Product Companies & MAANG DSA Prep (2026)",
    category: "PLACEMENTS",
    title: "Blind 75 & NeetCode 150 LeetCode Patterns & Solutions",
    subject: "Dynamic Programming, Trees, Graphs, System Design",
    contentType: "NOTES",
    year: 2026,
    difficulty: "ADVANCED",
    fileUrl: "https://myvault-files-app.s3.eu-north-1.amazonaws.com/exams/placements/maang_blind75_dsa_guide.pdf",
    s3Key: "exams/placements/maang_blind75_dsa_guide.pdf",
    fileSize: "16.8 MB",
    description: "Clean C++, Python, and Java implementations for the top 150 interview coding questions asked in Google, Amazon, Microsoft, and Uber.",
    author: "FAANG Senior Engineers",
    syllabusUrl: "https://leetcode.com",
    examDate: "Continuous 2026",
    isFeatured: true,
    downloadsCount: 3450,
    uploadedAt: new Date(Date.now() - 3 * 86400000).toISOString(),
  }
];

const BACKEND_URL = process.env.NEXT_PUBLIC_BACKEND_URL || "https://project-9zrh.onrender.com";

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const category = searchParams.get("category");
    const examId = searchParams.get("examId");
    const contentType = searchParams.get("contentType");

    let dbItems: CompetitiveExamItem[] = [];
    try {
      const res = await fetch(`${BACKEND_URL}/exams`, { cache: "no-store" });
      if (res.ok) {
        const rows = await res.json();
        if (Array.isArray(rows)) {
          dbItems = rows.map((r: any) => ({
            id: r.id,
            examId: r.examId || r.exam_id,
            examName: r.examName || r.exam_name || "Competitive Exam",
            category: r.category || "ENGINEERING",
            title: r.title,
            subject: r.subject || "General",
            unit: r.unit || "1",
            contentType: r.contentType || r.content_type || "NOTES",
            year: Number(r.year || 2026),
            difficulty: r.difficulty || "ALL_LEVELS",
            fileUrl: r.fileUrl || r.file_url,
            s3Key: r.s3Key || r.s3_key,
            fileSize: r.fileSize || r.file_size || "3.2 MB",
            description: r.description || "",
            author: r.author || "MyVault Faculty",
            syllabusUrl: r.syllabusUrl || r.syllabus_url || "",
            examDate: r.examDate || r.exam_date || "",
            isFeatured: Boolean(r.isFeatured || r.is_featured),
            downloadsCount: Number(r.downloadsCount || r.downloads_count || 0),
            uploadedAt: r.uploadedAt || r.uploaded_at || new Date().toISOString(),
          }));
        }
      }
    } catch (e) {
      console.error("Failed to fetch from backend DB exams:", e);
    }

    const dbIds = new Set(dbItems.map(i => i.id));
    const combined = [...dbItems, ...mockExams.filter(m => !dbIds.has(m.id))];

    let result = combined;
    if (category && category !== "ALL") {
      result = result.filter(i => i.category === category);
    }
    if (examId && examId !== "ALL") {
      result = result.filter(i => i.examId === examId);
    }
    if (contentType && contentType !== "ALL") {
      result = result.filter(i => i.contentType === contentType);
    }

    return NextResponse.json(result);
  } catch (error: any) {
    return NextResponse.json({ error: error?.message || "Internal server error" }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const newItem: CompetitiveExamItem = {
      id: body.id || "exam_" + Date.now() + "_" + Math.random().toString(36).substring(2, 7),
      examId: body.examId || "gate-cs-2026",
      examName: body.examName || "GATE Computer Science & IT",
      category: body.category || "ENGINEERING",
      title: body.title,
      subject: body.subject || "General",
      unit: body.unit || "1",
      contentType: body.contentType || "NOTES",
      year: Number(body.year) || 2026,
      difficulty: body.difficulty || "ALL_LEVELS",
      fileUrl: body.fileUrl,
      s3Key: body.s3Key || "",
      fileSize: body.fileSize || "2.5 MB",
      description: body.description || "",
      author: body.author || "MyVault Academic Team",
      syllabusUrl: body.syllabusUrl || "",
      examDate: body.examDate || "2026",
      isFeatured: Boolean(body.isFeatured),
      downloadsCount: 0,
      uploadedAt: new Date().toISOString(),
    };

    mockExams.unshift(newItem);

    // Forward to PostgreSQL on Render backend
    try {
      await fetch(`${BACKEND_URL}/admin/exams/confirm`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          id: newItem.id,
          examId: newItem.examId,
          examName: newItem.examName,
          category: newItem.category,
          title: newItem.title,
          subject: newItem.subject,
          unit: newItem.unit,
          contentType: newItem.contentType,
          year: newItem.year,
          difficulty: newItem.difficulty,
          fileUrl: newItem.fileUrl,
          s3Key: newItem.s3Key,
          fileSize: newItem.fileSize,
          description: newItem.description,
          author: newItem.author,
          syllabusUrl: newItem.syllabusUrl,
          examDate: newItem.examDate,
          isFeatured: newItem.isFeatured,
        }),
      });
    } catch (err) {
      console.error("Failed to forward exam to Render backend:", err);
    }

    return NextResponse.json(newItem, { status: 201 });
  } catch (error: any) {
    return NextResponse.json({ error: error?.message || "Failed to save exam resource" }, { status: 500 });
  }
}

export async function DELETE(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const id = searchParams.get("id");
    if (!id) return NextResponse.json({ error: "ID required" }, { status: 400 });

    mockExams = mockExams.filter(i => i.id !== id);

    try {
      await fetch(`${BACKEND_URL}/admin/exams/${id}`, { method: "DELETE" });
    } catch (_) {}

    return NextResponse.json({ success: true, id });
  } catch (error: any) {
    return NextResponse.json({ error: error?.message || "Failed to delete exam resource" }, { status: 500 });
  }
}
