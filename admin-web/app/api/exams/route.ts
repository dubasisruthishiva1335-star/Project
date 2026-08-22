import { NextResponse } from "next/server";
import { uploadedExamResources } from "@/lib/exam-store";

interface ExamVideo {
  id: string;
  title: string;
  subject?: string;
  duration?: string;
  s3Url?: string;
  pdfUrl?: string;
}

interface ExamPdfNote {
  id: string;
  title: string;
  subject: string;
  fileUrl: string;
}

interface ExamItem {
  id: string;
  name: string;
  cat: string;
  icon: string;
  description: string;
  eligibility: string;
  ageLimit: string;
  selectionProcess: string;
  syllabusSummary: string;
  videos: ExamVideo[];
  pdfNotes: ExamPdfNote[];
}

export async function GET() {
  const baseExams: ExamItem[] = [
    {
      id: "upsc-cse-2026",
      name: "UPSC Civil Services (IAS / IPS / IFS)",
      cat: "Government",
      icon: "🏛️",
      description: "Union Public Service Commission Civil Services Examination preparation roadmap, S3 video series, PYQs & PDF study notes.",
      eligibility: "Graduate in any discipline",
      ageLimit: "21 - 32 Years",
      selectionProcess: "Prelims ➔ Mains ➔ Interview",
      syllabusSummary: "History, Polity, Economy, Geography, Ethics & Current Affairs",
      videos: [],
      pdfNotes: [],
    },
    {
      id: "ssc-cgl-2026",
      name: "SSC CGL (Staff Selection Commission)",
      cat: "Government",
      icon: "🏛️",
      description: "Combined Graduate Level Examination for Group B & C central government posts.",
      eligibility: "Bachelor's Degree in any stream",
      ageLimit: "18 - 30 Years",
      selectionProcess: "Tier-1 CBT ➔ Tier-2 CBT & Speed Test",
      syllabusSummary: "Quantitative Aptitude, Reasoning, English & General Awareness",
      videos: [],
      pdfNotes: [],
    },
    {
      id: "ibps-po-2026",
      name: "SBI PO / IBPS PO & Clerk",
      cat: "Banking",
      icon: "🏦",
      description: "Probationary Officer & Specialist Officer examinations for nationalized banks.",
      eligibility: "Graduate in any discipline",
      ageLimit: "20 - 30 Years",
      selectionProcess: "Prelims ➔ Mains ➔ Interview",
      syllabusSummary: "Data Interpretation, Reasoning, English & Banking Awareness",
      videos: [],
      pdfNotes: [],
    },
    {
      id: "rrb-ntpc-2026",
      name: "RRB NTPC & Railway JE",
      cat: "Railways",
      icon: "🚆",
      description: "Indian Railways recruitment for Non-Technical Popular Categories & Junior Engineer posts.",
      eligibility: "10+2 / Graduate / Diploma / B.Tech",
      ageLimit: "18 - 33 Years",
      selectionProcess: "1st Stage CBT ➔ 2nd Stage CBT ➔ Typing Test",
      syllabusSummary: "General Science, Math & Reasoning",
      videos: [],
      pdfNotes: [],
    },
    {
      id: "gate-cse-2027",
      name: "GATE (Engineering & PSUs)",
      cat: "Higher Education",
      icon: "⚡",
      description: "Graduate Aptitude Test in Engineering for M.Tech & Direct PSU Recruitment.",
      eligibility: "B.Tech / B.E. / M.Sc / MCA",
      ageLimit: "No Age Limit",
      selectionProcess: "CBT Exam (100 Marks)",
      syllabusSummary: "Engineering Math, Aptitude & Core Engineering Subjects",
      videos: [],
      pdfNotes: [],
    },
  ];

  // Map uploaded resources into the matching exam object
  for (const res of uploadedExamResources) {
    const resExam = (res.examName || res.examId || "").toLowerCase();

    let exam = baseExams.find((e) => {
      const name = e.name.toLowerCase();
      const id = e.id.toLowerCase();
      return (
        name.includes(resExam) ||
        resExam.includes(name) ||
        (resExam.includes("upsc") && name.includes("upsc")) ||
        (resExam.includes("ssc") && name.includes("ssc")) ||
        (resExam.includes("ibps") && name.includes("ibps")) ||
        (resExam.includes("rrb") && name.includes("rrb")) ||
        (resExam.includes("gate") && name.includes("gate"))
      );
    });

    if (!exam) {
      exam = baseExams[0];
    }

    if (res.contentType === "PDF" || res.fileUrl.endsWith(".pdf")) {
      if (!exam.pdfNotes.some((p) => p.id === res.id)) {
        exam.pdfNotes.unshift({
          id: res.id,
          title: res.title,
          subject: res.subject,
          fileUrl: res.fileUrl,
        });
      }
    } else {
      if (!exam.videos.some((v) => v.id === res.id)) {
        exam.videos.unshift({
          id: res.id,
          title: res.title,
          subject: res.subject,
          duration: res.duration || "20:00",
          s3Url: res.fileUrl,
          pdfUrl: res.fileUrl,
        });
      }
    }
  }

  return NextResponse.json(baseExams);
}
