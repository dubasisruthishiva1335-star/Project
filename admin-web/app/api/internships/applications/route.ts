import { NextResponse } from "next/server";

export interface CandidateApplication {
  id: string;
  internshipId: string;
  internshipTitle: string;
  company: string;
  studentName: string;
  studentEmail: string;
  studentPhone: string;
  hallTicket: string;
  branch: string;
  cgpa: number;
  gradYear: number;
  skills: string[];
  resumeUrl: string;
  coverNote?: string;
  answers: Record<string, string>;
  matchScore: number;
  status: "SUBMITTED" | "UNDER_REVIEW" | "SHORTLISTED" | "INTERVIEW" | "SELECTED" | "REJECTED";
  interviewDate?: string;
  appliedAt: string;
  notes?: string;
}

let mockApplications: CandidateApplication[] = [
  {
    id: "app_10491",
    internshipId: "int_google_swe",
    internshipTitle: "Software Engineering Intern",
    company: "Google",
    studentName: "Rahul Kumar",
    studentEmail: "rahul.kumar@college.edu",
    studentPhone: "+91 98765 43210",
    hallTicket: "21A91A0501",
    branch: "CSE",
    cgpa: 8.8,
    gradYear: 2026,
    skills: ["Python", "C++", "Data Structures", "Algorithms", "System Design"],
    resumeUrl: "https://myvault-files-app.s3.eu-north-1.amazonaws.com/resumes/Rahul_Kumar_Resume.pdf",
    coverNote: "Passionate about building scalable distributed systems with 400+ problems solved on LeetCode.",
    answers: {
      q1: "Built a distributed cache in Go supporting LRU eviction and raft consensus.",
      q2: "Yes, available full-time for 6 months."
    },
    matchScore: 95,
    status: "SHORTLISTED",
    appliedAt: new Date(Date.now() - 1 * 86400000).toISOString(),
    notes: "Strong DS/Algo problem-solving profile. Recommend for technical screening round."
  },
  {
    id: "app_10492",
    internshipId: "int_msft_ai",
    internshipTitle: "AI & Machine Learning Engineering Intern",
    company: "Microsoft",
    studentName: "Priya Sharma",
    studentEmail: "priya.s@college.edu",
    studentPhone: "+91 98450 11223",
    hallTicket: "21A91A0544",
    branch: "AI_ML",
    cgpa: 9.1,
    gradYear: 2026,
    skills: ["Python", "PyTorch", "Generative AI", "Azure", "NLP"],
    resumeUrl: "https://myvault-files-app.s3.eu-north-1.amazonaws.com/resumes/Priya_Sharma_Resume.pdf",
    coverNote: "Published a research paper on LoRA fine-tuning for domain-specific LLMs.",
    answers: {
      q1: "Fine-tuned Llama 3 8B using QLoRA and built a RAG pipeline with Qdrant and Azure OpenAI."
    },
    matchScore: 92,
    status: "INTERVIEW",
    interviewDate: "2026-09-18T11:00:00Z",
    appliedAt: new Date(Date.now() - 2 * 86400000).toISOString(),
    notes: "Technical interview scheduled with Azure AI engineering team on Sep 18."
  },
  {
    id: "app_10493",
    internshipId: "int_amazon_sde",
    internshipTitle: "SDE Cloud Intern (AWS)",
    company: "Amazon Web Services",
    studentName: "Arjun Reddy",
    studentEmail: "arjun.r@college.edu",
    studentPhone: "+91 97000 88990",
    hallTicket: "21A91A0412",
    branch: "ECE",
    cgpa: 8.2,
    gradYear: 2026,
    skills: ["Java", "AWS", "Node.js", "Docker", "REST APIs"],
    resumeUrl: "https://myvault-files-app.s3.eu-north-1.amazonaws.com/resumes/Arjun_Reddy_Resume.pdf",
    coverNote: "AWS Certified Cloud Practitioner with hands-on experience in serverless architectures.",
    answers: {
      q1: "https://github.com/arjunreddy/aws-serverless-ecommerce-api"
    },
    matchScore: 88,
    status: "UNDER_REVIEW",
    appliedAt: new Date(Date.now() - 3 * 86400000).toISOString(),
  }
];

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const internshipId = searchParams.get("internshipId");
    const studentId = searchParams.get("studentId");
    const status = searchParams.get("status");

    let list = [...mockApplications];
    if (internshipId) {
      list = list.filter(a => a.internshipId === internshipId);
    }
    if (studentId) {
      list = list.filter(a => a.hallTicket === studentId || a.studentEmail === studentId);
    }
    if (status && status !== "ALL") {
      list = list.filter(a => a.status === status);
    }

    return NextResponse.json(list);
  } catch (error: any) {
    return NextResponse.json({ error: error?.message || "Internal server error" }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const newApp: CandidateApplication = {
      id: "app_" + Math.floor(10000 + Math.random() * 90000),
      internshipId: body.internshipId,
      internshipTitle: body.internshipTitle || "Software Internship",
      company: body.company || "Partner Company",
      studentName: body.studentName || "Student Applicant",
      studentEmail: body.studentEmail || "student@myvault.edu",
      studentPhone: body.studentPhone || "+91 99999 99999",
      hallTicket: body.hallTicket || "21A91A0500",
      branch: body.branch || "CSE",
      cgpa: Number(body.cgpa) || 8.0,
      gradYear: Number(body.gradYear) || 2026,
      skills: Array.isArray(body.skills) ? body.skills : ["Problem Solving", "Engineering"],
      resumeUrl: body.resumeUrl || "https://myvault-files-app.s3.eu-north-1.amazonaws.com/resumes/default_resume.pdf",
      coverNote: body.coverNote || "",
      answers: body.answers || {},
      matchScore: Number(body.matchScore) || Math.floor(82 + Math.random() * 16),
      status: "SUBMITTED",
      appliedAt: new Date().toISOString(),
    };

    mockApplications.unshift(newApp);
    return NextResponse.json(newApp, { status: 201 });
  } catch (error: any) {
    return NextResponse.json({ error: error?.message || "Failed to submit application" }, { status: 500 });
  }
}

export async function PATCH(request: Request) {
  try {
    const body = await request.json();
    const { id, status, notes, interviewDate } = body;
    const index = mockApplications.findIndex(a => a.id === id);
    if (index === -1) {
      return NextResponse.json({ error: "Application not found" }, { status: 404 });
    }

    if (status) mockApplications[index].status = status;
    if (notes !== undefined) mockApplications[index].notes = notes;
    if (interviewDate !== undefined) mockApplications[index].interviewDate = interviewDate;

    return NextResponse.json(mockApplications[index]);
  } catch (error: any) {
    return NextResponse.json({ error: error?.message || "Failed to update application" }, { status: 500 });
  }
}