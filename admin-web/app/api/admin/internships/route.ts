import { NextResponse } from "next/server";
import { connectDB } from "@/lib/db";

export interface InternshipItem {
  id: string;
  title: string;
  company: string;
  logo?: string;
  workMode: "REMOTE" | "HYBRID" | "ONSITE";
  location: string;
  category: string;
  openings: number;
  startDate?: string;
  deadline?: string;
  duration?: string;
  stipend: string;
  isPaid: boolean;
  currency: string;
  description: string;
  responsibilities: string[];
  requirements: string[];
  skills: string[];
  eligibleBranches: string[];
  minCgpa: number;
  eligibleGradYears: number[];
  perks: string[];
  contactPhone?: string;
  contactEmail?: string;
  companyWebsite?: string;
  applyUrl?: string;
  questions: Array<{ id: string; question: string; type: string; required: boolean }>;
  status: "DRAFT" | "PUBLISHED" | "CLOSED";
  postedAt: string;
  applicantCount: number;
}

const BACKEND_URL = process.env.NEXT_PUBLIC_BACKEND_URL || "https://project-9zrh.onrender.com";

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const id = searchParams.get("id");
    const status = searchParams.get("status");

    let dbInternships: InternshipItem[] = [];

    // 1. Query MongoDB internships collection
    try {
      const db = await connectDB();
      if (db) {
        const rows = await db.collection("internships").find({}).sort({ createdAt: -1 }).toArray();
        if (Array.isArray(rows) && rows.length > 0) {
          dbInternships = rows.map((r: any) => ({
            id: r.id || (r._id ? r._id.toString() : ""),
            title: r.title,
            company: r.company || "MyVault Partner",
            logo: r.logo || "",
            workMode: r.workMode || "HYBRID",
            location: r.location || "Bengaluru, India",
            category: r.category || "Software Development",
            openings: Number(r.openings || 5),
            duration: r.duration || "6 Months",
            stipend: r.stipend || "₹40,000 / month",
            isPaid: true,
            currency: "INR",
            description: r.description || "",
            contactPhone: r.contactPhone || "",
            contactEmail: r.contactEmail || "",
            companyWebsite: r.companyWebsite || "",
            applyUrl: r.applyUrl || "",
            responsibilities: r.responsibilities || [],
            requirements: r.requirements || [],
            skills: r.skills || ["Full Stack", "Problem Solving"],
            eligibleBranches: r.eligibleBranches || ["ALL"],
            minCgpa: Number(r.minCgpa || 6.5),
            eligibleGradYears: [2026, 2027],
            perks: r.perks || ["PPO Opportunity", "Mentorship"],
            questions: [],
            status: (r.status as any) || "PUBLISHED",
            postedAt: r.postedAt || (r.createdAt ? new Date(r.createdAt).toISOString() : new Date().toISOString()),
            applicantCount: Number(r.applicantCount || 0),
          }));
        }
      }
    } catch (_) {}

    // 2. Fetch from Render backend if MongoDB empty
    if (dbInternships.length === 0) {
      try {
        const res = await fetch(`${BACKEND_URL}/job-listings?type=INTERNSHIP`, { cache: "no-store" });
        if (res.ok) {
          const rows = await res.json();
          if (Array.isArray(rows)) {
            dbInternships = rows
              .filter((r: any) => r.type !== "COURSE" && !r.isLmsEnabled && r.hubType !== "COURSE")
              .map((r: any) => ({
                id: r.id,
                title: r.title,
                company: r.company || "MyVault",
                logo: r.logo || "",
                workMode: r.workMode || (r.work_mode as any) || "HYBRID",
                location: r.location || "Bengaluru, India",
                category: r.category || "Software Development",
                openings: Number(r.openings || r.max_students || 5),
                startDate: r.start_date || r.startDate,
                deadline: r.deadline,
                duration: r.duration || "6 Months",
                stipend: r.stipend || "₹40,000 / month",
                isPaid: true,
                currency: "INR",
                description: r.description || "",
                contactPhone: r.contactPhone || r.contact_phone || "",
                contactEmail: r.contactEmail || r.contact_email || "",
                companyWebsite: r.companyWebsite || r.company_website || "",
                applyUrl: r.applyUrl || r.apply_url || "",
                responsibilities: Array.isArray(r.responsibilities) ? r.responsibilities : (r.responsibilities ? String(r.responsibilities).split("\n") : []),
                requirements: Array.isArray(r.requirements) ? r.requirements : (r.requirements ? String(r.requirements).split("\n") : []),
                skills: Array.isArray(r.skills) ? r.skills : (r.skills ? String(r.skills).split(",") : ["Full Stack", "Problem Solving"]),
                eligibleBranches: Array.isArray(r.eligibleBranches) ? r.eligibleBranches : (r.branch ? [r.branch] : ["ALL"]),
                minCgpa: Number(r.minCgpa || r.min_cgpa || 6.5),
                eligibleGradYears: [2025, 2026, 2027],
                perks: Array.isArray(r.perks) ? r.perks : ["PPO Opportunity", "Mentorship", "Certificate"],
                questions: [],
                status: (r.status as any) || "PUBLISHED",
                postedAt: r.posted_at || r.postedAt || new Date().toISOString(),
                applicantCount: Number(r.applicantCount || r.enrollment_count || 0),
              }));
          }
        }
      } catch (e) {
        console.error("Failed to fetch from backend DB:", e);
      }
    }

    if (id) {
      const found = dbInternships.find(i => i.id === id);
      if (!found) return NextResponse.json({ error: "Internship not found" }, { status: 404 });
      return NextResponse.json(found);
    }
    if (status) {
      return NextResponse.json(dbInternships.filter(i => i.status === status));
    }

    return NextResponse.json(dbInternships);
  } catch (error: any) {
    return NextResponse.json({ error: error?.message || "Internal server error" }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const newInternship: InternshipItem = {
      id: body.id || "int_" + Date.now() + "_" + Math.random().toString(36).substring(2, 7),
      title: body.title,
      company: body.company || "MyVault Partner",
      logo: body.logo || "",
      workMode: body.workMode || "HYBRID",
      location: body.location || "Bengaluru, Karnataka",
      category: body.category || "Software Development",
      openings: Number(body.openings) || 5,
      startDate: body.startDate,
      deadline: body.deadline,
      duration: body.duration || "6 Months",
      stipend: body.stipend || "40,000",
      isPaid: body.isPaid !== false,
      currency: body.currency || "INR",
      description: body.description || "",
      contactPhone: body.contactPhone || body.contact_phone || "",
      contactEmail: body.contactEmail || body.contact_email || "",
      companyWebsite: body.companyWebsite || body.company_website || "",
      applyUrl: body.applyUrl || body.apply_url || "",
      responsibilities: Array.isArray(body.responsibilities) ? body.responsibilities : (body.responsibilities || "").split("\n").filter(Boolean),
      requirements: Array.isArray(body.requirements) ? body.requirements : (body.requirements || "").split("\n").filter(Boolean),
      skills: Array.isArray(body.skills) ? body.skills : (body.skills || "").split(",").map((s: string) => s.trim()).filter(Boolean),
      eligibleBranches: Array.isArray(body.eligibleBranches) && body.eligibleBranches.length > 0 ? body.eligibleBranches : ["ALL"],
      minCgpa: Number(body.minCgpa) || 6.5,
      eligibleGradYears: Array.isArray(body.eligibleGradYears) ? body.eligibleGradYears : [2026, 2027],
      perks: Array.isArray(body.perks) ? body.perks : ["Certificate", "Mentorship", "PPO Conversion"],
      questions: Array.isArray(body.questions) ? body.questions : [],
      status: body.status || "PUBLISHED",
      postedAt: new Date().toISOString(),
      applicantCount: 0,
    };

    // Save to MongoDB
    try {
      const db = await connectDB();
      if (db) {
        await db.collection("internships").insertOne({
          ...newInternship,
          _id: newInternship.id as any,
          createdAt: new Date(),
        });
      }
    } catch (_) {}

    // Sync to PostgreSQL on Render backend
    try {
      await fetch(`${BACKEND_URL}/admin/job-listings/confirm`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(newInternship),
      });
    } catch (err) {
      console.error("Failed to forward internship to Render backend:", err);
    }

    return NextResponse.json(newInternship, { status: 201 });
  } catch (error: any) {
    return NextResponse.json({ error: error?.message || "Failed to create internship" }, { status: 500 });
  }
}

export async function DELETE(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const id = searchParams.get("id");
    if (!id) return NextResponse.json({ error: "ID required" }, { status: 400 });

    try {
      const db = await connectDB();
      if (db) {
        await db.collection("internships").deleteMany({ $or: [{ id }, { _id: id as any }] });
      }
    } catch (_) {}

    try {
      await fetch(`${BACKEND_URL}/admin/job-listings/${id}`, { method: "DELETE" });
    } catch (_) {}

    return NextResponse.json({ success: true, id });
  } catch (error: any) {
    return NextResponse.json({ error: error?.message || "Failed to delete internship" }, { status: 500 });
  }
}
