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

let mockApplications: CandidateApplication[] = [];

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
      list = list.filter(a => (a as any).studentId === studentId);
    }
    if (status) {
      list = list.filter(a => a.status === status);
    }

    return NextResponse.json(list);
  } catch (error: any) {
    return NextResponse.json({ error: error?.message || "Failed to fetch candidate applications" }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const newApp: CandidateApplication = {
      id: "app_" + Date.now() + "_" + Math.random().toString(36).substring(2, 6),
      internshipId: body.internshipId,
      internshipTitle: body.internshipTitle,
      company: body.company,
      studentName: body.studentName,
      studentEmail: body.studentEmail,
      studentPhone: body.studentPhone,
      hallTicket: body.hallTicket,
      branch: body.branch,
      cgpa: Number(body.cgpa) || 7.0,
      gradYear: Number(body.gradYear) || 2026,
      skills: Array.isArray(body.skills) ? body.skills : [],
      resumeUrl: body.resumeUrl || "",
      coverNote: body.coverNote || "",
      answers: body.answers || {},
      matchScore: 85,
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
    if (!id) return NextResponse.json({ error: "Application ID required" }, { status: 400 });

    const target = mockApplications.find(a => a.id === id);
    if (!target) return NextResponse.json({ error: "Application not found" }, { status: 404 });

    if (status) target.status = status;
    if (notes !== undefined) target.notes = notes;
    if (interviewDate !== undefined) target.interviewDate = interviewDate;

    return NextResponse.json(target);
  } catch (error: any) {
    return NextResponse.json({ error: error?.message || "Failed to update status" }, { status: 500 });
  }
}
