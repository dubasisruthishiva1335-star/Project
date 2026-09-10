import { NextRequest, NextResponse } from "next/server";
import { s3Client } from "@/lib/s3";
import { PutObjectCommand } from "@aws-sdk/client-s3";
import { connectDB } from "@/lib/db";

export async function POST(req: NextRequest) {
  try {
    const formData = await req.formData();
    const file = formData.get("file") as File | null;
    const title = (formData.get("title") as string) || (file ? file.name : "Untitled Asset");
    const category = (formData.get("category") as string) || "notes"; // notes, exams, courses, internships

    if (!file) {
      return NextResponse.json({ error: "No file provided" }, { status: 400 });
    }

    const buffer = Buffer.from(await file.arrayBuffer());
    const fileName = `${Date.now()}-${file.name.replace(/\s+/g, "-")}`;
    const s3Key = `${category}/${fileName}`;
    const bucketName = process.env.AWS_BUCKET_NAME || "myvault-files-app";
    const region = process.env.AWS_REGION || "eu-north-1";

    // 1. Upload to AWS S3 - 100% PERMANENT
    await s3Client.send(
      new PutObjectCommand({
        Bucket: bucketName,
        Key: s3Key,
        Body: buffer,
        ContentType: file.type || "application/octet-stream",
      })
    );

    const fileUrl = `https://${bucketName}.s3.${region}.amazonaws.com/${s3Key}`;

    // 2. Save to PERSISTENT DATABASE
    const db = await connectDB();
    if (db) {
      await db.collection(category).insertOne({
        title,
        fileName: file.name,
        s3Key,
        url: fileUrl,
        category,
        fileSize: file.size,
        contentType: file.type,
        createdAt: new Date(),
      });
    }

    return NextResponse.json({
      success: true,
      url: fileUrl,
      s3Key,
      title,
      category,
      fileName: file.name,
    });
  } catch (err: any) {
    console.error("Upload API error:", err);
    return NextResponse.json({ error: err.message || "Failed to upload file to S3" }, { status: 500 });
  }
}
