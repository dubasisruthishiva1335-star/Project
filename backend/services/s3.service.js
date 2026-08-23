const crypto = require("crypto");
const { S3Client, PutObjectCommand } = require("@aws-sdk/client-s3");
const { getSignedUrl } = require("@aws-sdk/s3-request-presigner");

const REGION = process.env.AWS_REGION || "eu-north-1";
const BUCKET = process.env.S3_BUCKET_NAME || "myvault-files-app";

const s3 = new S3Client({
  region: REGION,
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID || "",
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || "",
  },
});

function publicS3Url(key) {
  return `https://${BUCKET}.s3.${REGION}.amazonaws.com/${key}`;
}

/**
 * Returns a real presigned PUT URL the browser can upload directly to.
 * The backend never sees or forwards the file bytes.
 */
async function createPresignedUploadUrl({
  filename = "file",
  contentType = "application/octet-stream",
  folder = "lessons",
  expiresIn = 900,
}) {
  const safeFilename = String(filename)
    .replace(/[^a-zA-Z0-9._-]/g, "_")
    .slice(0, 180);

  const key = `internships/${folder}/${Date.now()}_${crypto
    .randomBytes(6)
    .toString("hex")}_${safeFilename}`;

  const command = new PutObjectCommand({
    Bucket: BUCKET,
    Key: key,
    ContentType: contentType,
  });

  const uploadUrl = await getSignedUrl(s3, command, { expiresIn });

  return {
    uploadUrl,
    key,
    fileUrl: publicS3Url(key),
    expiresIn,
  };
}

/**
 * Uploads a buffer directly (used server-side, e.g. for generated certificate PDFs).
 */
async function uploadBuffer({ key, body, contentType, contentDisposition }) {
  await s3.send(
    new PutObjectCommand({
      Bucket: BUCKET,
      Key: key,
      Body: body,
      ContentType: contentType,
      ...(contentDisposition ? { ContentDisposition: contentDisposition } : {}),
    })
  );

  return publicS3Url(key);
}

module.exports = {
  s3,
  BUCKET,
  REGION,
  publicS3Url,
  createPresignedUploadUrl,
  uploadBuffer,
};
