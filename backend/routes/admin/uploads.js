const express = require("express");
const { S3Client, PutObjectCommand } = require("@aws-sdk/client-s3");
const { getSignedUrl } = require("@aws-sdk/s3-request-presigner");

const router = express.Router();

const REGION = process.env.AWS_REGION || "eu-north-1";
const S3_BUCKET = process.env.S3_BUCKET_NAME || "myvault-files-app";

const s3Client = new S3Client({
  region: REGION,
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID || "",
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || "",
  },
});

router.post("/presign", async (req, res) => {
  try {
    const { domain = "general", fileName = "file.pdf", contentType = "application/octet-stream" } = req.body;
    const cleanFileName = String(fileName).replace(/[^a-zA-Z0-9._-]/g, "_").slice(0, 150);
    const s3Key = `${domain}/${Date.now()}_${cleanFileName}`;

    const command = new PutObjectCommand({
      Bucket: S3_BUCKET,
      Key: s3Key,
      ContentType: contentType,
    });

    const uploadUrl = await getSignedUrl(s3Client, command, { expiresIn: 3600 });
    const publicUrl = `https://${S3_BUCKET}.s3.${REGION}.amazonaws.com/${s3Key}`;

    res.json({
      success: true,
      uploadUrl,
      s3Key,
      publicUrl,
    });
  } catch (err) {
    console.error("Presign generation error:", err);
    res.status(500).json({ error: "Failed to generate presigned upload URL", details: err.message });
  }
});

module.exports = router;
