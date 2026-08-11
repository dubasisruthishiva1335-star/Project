// lib/api-client.ts
//
// Shared client for the Admin Web app. Every upload page (Notes, Syllabus,
// Question Banks, Lab Manuals, Internships/Placements/Govt Jobs, Results,
// Aptitude, Competitive Exams) goes through the same three calls:
//   1. POST /admin/uploads/presign   -> { uploadUrl, s3Key }
//   2. PUT  <uploadUrl>               -> raw file bytes, direct to S3
//   3. POST /admin/<domain>/confirm   -> persists the DB row for that domain
//
// Adjust API_BASE_URL and the auth-token source to match your actual
// project (this assumes a cookie/localStorage JWT set at login).

const API_BASE_URL =
  process.env.NEXT_PUBLIC_API_BASE_URL ?? "https://romantic-serenity-production-3e5b.up.railway.app";

export class ApiError extends Error {
  status: number;
  body: unknown;
  constructor(message: string, status: number, body: unknown) {
    super(message);
    this.status = status;
    this.body = body;
  }
}

function getAuthToken(): string | null {
  if (typeof window === "undefined") return null;
  return window.localStorage.getItem("myvault_admin_token");
}

export async function apiRequest<T>(
  path: string,
  options: RequestInit = {}
): Promise<T> {
  const token = getAuthToken();

  const res = await fetch(`${API_BASE_URL}${path}`, {
    ...options,
    headers: {
      ...(options.body && !(options.body instanceof FormData)
        ? { "Content-Type": "application/json" }
        : {}),
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...options.headers,
    },
  });

  const isJson = res.headers.get("content-type")?.includes("application/json");
  const body = isJson ? await res.json() : await res.text();

  if (!res.ok) {
    const message =
      isJson && body && typeof body === "object" && "message" in body
        ? String((body as { message: unknown }).message)
        : `Request failed with status ${res.status}`;
    throw new ApiError(message, res.status, body);
  }

  return body as T;
}

export type UploadProgressStage = "presigning" | "uploading" | "confirming" | "done";

export interface PresignResponse {
  uploadUrl: string;
  s3Key: string;
  publicUrl?: string;
}

export interface UploadFileOptions {
  file: File;
  /** e.g. "notes", "syllabus", "results", "internships" — used to namespace the S3 key */
  domain: string;
  /** Extra metadata sent to the presign step (branch/semester help build the S3 key path) */
  presignMeta?: Record<string, string | number | undefined>;
  /** Called as the upload moves through its stages, useful for a progress indicator */
  onProgress?: (stage: UploadProgressStage) => void;
}

/**
 * Step 1 + 2 only: get a presigned URL and PUT the file to S3.
 * Returns the s3Key (and publicUrl if the API returns one) so the caller
 * can then hit whichever domain-specific /admin/<domain>/confirm endpoint
 * applies, along with the rest of that content type's metadata.
 */
export async function uploadFileToS3(
  options: UploadFileOptions
): Promise<{ s3Key: string; publicUrl?: string }> {
  const { file, domain, presignMeta, onProgress } = options;

  onProgress?.("presigning");
  const presign = await apiRequest<PresignResponse>("/admin/uploads/presign", {
    method: "POST",
    body: JSON.stringify({
      domain,
      fileName: file.name,
      contentType: file.type || "application/octet-stream",
      ...presignMeta,
    }),
  });

  onProgress?.("uploading");
  const putRes = await fetch(presign.uploadUrl, {
    method: "PUT",
    headers: { "Content-Type": file.type || "application/octet-stream" },
    body: file,
  });
  if (!putRes.ok) {
    throw new ApiError("File upload to storage failed", putRes.status, null);
  }

  onProgress?.("confirming");
  return { s3Key: presign.s3Key, publicUrl: presign.publicUrl };
}

/**
 * Full three-step flow: presign, PUT to S3, then confirm against a
 * domain-specific endpoint (e.g. "/admin/notes/confirm").
 * `metadata` is whatever fields that domain's confirm DTO expects,
 * beyond the s3Key (title, branch, semester, contentType, etc.).
 */
export async function uploadAndConfirm<TResponse>(
  confirmPath: string,
  options: UploadFileOptions,
  metadata: Record<string, unknown>
): Promise<TResponse> {
  const { s3Key, publicUrl } = await uploadFileToS3(options);

  const result = await apiRequest<TResponse>(confirmPath, {
    method: "POST",
    body: JSON.stringify({ ...metadata, s3Key, publicUrl }),
  });

  options.onProgress?.("done");
  return result;
}
