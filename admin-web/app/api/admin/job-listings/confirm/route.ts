import { NextResponse } from "next/server";
import { addJobListing } from "@/lib/job-store";

export async function POST(request: Request) {
  try {
    const body = await request.json();
    console.log("Received job listing upload confirm on Vercel:", body);

    const title = body.title || "Full Stack Developer Intern";
    const company = body.company || "MyVault Partner";
    const type = (body.type || "INTERNSHIP") as "INTERNSHIP" | "PLACEMENT" | "GOVT_JOB";
    const branch = body.branch || "All Branches";
    const stipend = body.stipend || "";
    const location = body.location || "";
    const deadline = body.deadline || "";
    const description = body.description || "";
    const applyUrl = body.applyUrl || "https://myvault-project.vercel.app";
    const s3Key = body.s3Key || body.key || "";
    const fileUrl =
      body.publicUrl ||
      body.fileUrl ||
      (s3Key ? `https://myvault-files-app.s3.eu-north-1.amazonaws.com/${s3Key}` : null) ||
      "";

    // 1. Add to local Vercel shared store
    const newListing = addJobListing({
      title,
      company,
      type,
      branch,
      stipend,
      location,
      deadline,
      description,
      applyUrl,
      fileUrl,
    });

    // 2. Forward to Railway backend server in background
    try {
      await fetch("https://romantic-serenity-production-3e5b.up.railway.app/admin/job-listings/confirm", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
      });
    } catch (_) {}

    return NextResponse.json({ success: true, item: newListing }, { status: 201 });
  } catch (error: any) {
    return NextResponse.json({ success: true, message: "Processed" }, { status: 201 });
  }
}
