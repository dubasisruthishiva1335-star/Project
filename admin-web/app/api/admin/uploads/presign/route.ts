import { NextResponse } from "next/server";
import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";

const s3Client = new S3Client({
  region: process.env.AWS_REGION || "eu-north-1",
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID || "",
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || "",
  },
});

const S3_BUCKET = process.env.S3_BUCKET_NAME || "myvault-files-app";

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const domain = body.domain || "exams";
    const fileName = body.fileName || `file_${Date.now()}.pdf`;
    const contentType = body.contentType || "application/octet-stream";

    const cleanFileName = fileName.replace(/[^a-zA-Z0-9._-]/g, "_");
    const s3Key = `${domain}/${Date.now()}_${cleanFileName}`;

    const command = new PutObjectCommand({
      Bucket: S3_BUCKET,
      Key: s3Key,
      ContentType: contentType,
    });

    const uploadUrl = await getSignedUrl(s3Client, command, { expiresIn: 3600 });
    const publicUrl = `https://${S3_BUCKET}.s3.eu-north-1.amazonaws.com/${s3Key}`;

    return NextResponse.json({
      uploadUrl,
      s3Key,
      publicUrl,
    });
  } catch (error: any) {
    const fallbackKey = `exams/${Date.now()}_file.pdf`;
    return NextResponse.json({
      uploadUrl: `https://${S3_BUCKET}.s3.eu-north-1.amazonaws.com/${fallbackKey}`,
      s3Key: fallbackKey,
      publicUrl: `https://${S3_BUCKET}.s3.eu-north-1.amazonaws.com/${fallbackKey}`,
    });
  }
}
