import { NextResponse } from "next/server";
import { addJobListing } from "@/lib/job-store";

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const authHeader = request.headers.get("authorization") || "";

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

    // 2. Forward to Railway backend server
    try {
      const headers: Record<string, string> = { "Content-Type": "application/json" };
      if (authHeader) headers["Authorization"] = authHeader;

      const railwayRes = await fetch("https://romantic-serenity-production-3e5b.up.railway.app/admin/job-listings/confirm", {
        method: "POST",
        headers,
        body: JSON.stringify(body),
      });
      console.log("Railway confirm status:", railwayRes.status);
    } catch (e: any) {
      console.error("Failed forwarding to Railway:", e.message);
    }

    return NextResponse.json({ success: true, item: newListing }, { status: 201 });
  } catch (error: any) {
    return NextResponse.json({ success: true, message: "Processed" }, { status: 201 });
  }
}
