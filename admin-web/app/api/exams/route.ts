import { NextResponse } from "next/server";
import { uploadedExamResources } from "@/lib/exam-store";

export async function GET() {
  const baseExams = [
    {
      id: "exam_upsc",
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
      id: "exam_ssc",
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
      id: "exam_banking",
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
      id: "exam_rrb",
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
      id: "exam_jee",
      name: "JEE Main / Advanced (Engineering)",
      cat: "Higher Education",
      icon: "🎓",
      description: "Premier national engineering entrance examination for IITs, NITs, IIITs, and CFTIs.",
      eligibility: "Class 12 Passed (PCM)",
      ageLimit: "No Age Limit",
      selectionProcess: "JEE Main CBT ➔ Advanced CBT",
      syllabusSummary: "Physics (Mechanics), Chemistry, Math (Calculus)",
      videos: [],
      pdfNotes: [],
    },
    {
      id: "exam_neet",
      name: "NEET-UG (Medical Entrance)",
      cat: "Higher Education",
      icon: "🩺",
      description: "National entrance examination for MBBS, BDS, BAMS, BHMS, and medical admissions.",
      eligibility: "Class 12 Passed (PCB)",
      ageLimit: "Minimum 17 Years",
      selectionProcess: "OMR Pen & Paper Exam (720 Marks)",
      syllabusSummary: "NCERT Biology, Chemistry & Physics",
      videos: [],
      pdfNotes: [],
    },
    {
      id: "exam_gate",
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
    {
      id: "exam_cat",
      name: "CAT / XAT (Management)",
      cat: "Management",
      icon: "💼",
      description: "Common Admission Test for MBA & PGDM programs at IIMs & top B-schools.",
      eligibility: "Bachelor's Degree",
      ageLimit: "No Age Limit",
      selectionProcess: "CAT Exam ➔ WAT / GD ➔ Interview",
      syllabusSummary: "VARC, DILR & Quantitative Ability",
      videos: [],
      pdfNotes: [],
    },
    {
      id: "exam_ca",
      name: "CA (Chartered Accountant)",
      cat: "Professional",
      icon: "📊",
      description: "ICAI Professional Qualification for Foundation, Intermediate & Final stages.",
      eligibility: "12th Passed / Graduate",
      ageLimit: "No Age Limit",
      selectionProcess: "Foundation ➔ Inter ➔ Articleship ➔ Final",
      syllabusSummary: "Accounting, Law, Costing, Taxation, Auditing",
      videos: [],
      pdfNotes: [],
    },
  ];

  // Map uploaded resources into the matching exam object
  for (const res of uploadedExamResources) {
    let exam = baseExams.find(
      (e) => e.name.toLowerCase().includes(res.examName.toLowerCase()) || res.examName.toLowerCase().includes(e.name.toLowerCase())
    );
    if (!exam) {
      exam = baseExams[0];
    }

    if (res.contentType === "PDF" || res.fileUrl.endsWith(".pdf")) {
      exam.pdfNotes.unshift({
        id: res.id,
        title: res.title,
        subject: res.subject,
        fileUrl: res.fileUrl,
      });
    } else {
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

  return NextResponse.json(baseExams);
}
