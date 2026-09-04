// lib/api-client.ts

const API_BASE_URL =
  process.env.NEXT_PUBLIC_API_URL ||
  process.env.NEXT_PUBLIC_API_BASE_URL ||
  "https://project-9zrh.onrender.com";

export class ApiError extends Error {
  constructor(
    message: string,
    public status: number,
    public data: unknown
  ) {
    super(message);
    this.name = "ApiError";
  }
}

export async function apiRequest<T>(
  path: string,
  options: RequestInit = {}
): Promise<T> {
  const token =
    typeof window !== "undefined"
      ? localStorage.getItem("myvault_admin_token")
      : null;

  const headers: Record<string, string> = {
    "Content-Type": "application/json",
    ...(options.headers as Record<string, string>),
  };

  if (token) {
    headers["Authorization"] = `Bearer ${token}`;
  }

  try {
    const res = await fetch(`${API_BASE_URL}${path}`, {
      ...options,
      headers,
    });

    if (res.status === 401) {
      if (typeof window !== "undefined") {
        localStorage.removeItem("myvault_admin_token");
      }
      throw new ApiError("Session expired. Please log in again.", 401, null);
    }

    if (!res.ok) {
      const body = await res.json().catch(() => null);
      const message =
        body && typeof body === "object" && "message" in body
          ? (body as { message: string }).message
          : (body && typeof body === "object" && "error" in body
          ? (body as { error: string }).error
          : `Request failed with status ${res.status}`);

      throw new ApiError(message, res.status, body);
    }

    return res.json();
  } catch (err) {
    throw err;
  }
}

export type UploadProgressStage = "presigning" | "uploading" | "confirming" | "done";

export interface PresignResponse {
  uploadUrl: string;
  s3Key: string;
  publicUrl?: string;
}

export interface UploadFileOptions {
  file?: File | null;
  domain: string;
  presignMeta?: Record<string, string | number | undefined>;
  onProgress?: (stage: UploadProgressStage) => void;
}

export async function uploadFileToS3(
  options: UploadFileOptions
): Promise<{ s3Key: string; publicUrl?: string }> {
  const { file, domain, presignMeta, onProgress } = options;

  if (!file) {
    return { s3Key: "", publicUrl: "" };
  }

  onProgress?.("presigning");

  let presign: PresignResponse | null = null;
  try {
    // 1. Try Vercel local API route
    const presignRes = await fetch("/api/admin/uploads/presign", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        domain,
        fileName: file.name,
        contentType: file.type || "application/octet-stream",
        ...presignMeta,
      }),
    });
    if (presignRes.ok) {
      presign = await presignRes.json();
    }
  } catch (_) {}

  if (!presign || !presign.uploadUrl) {
    // 2. Try backend /admin/uploads/presign
    try {
      presign = await apiRequest<PresignResponse>("/admin/uploads/presign", {
        method: "POST",
        body: JSON.stringify({
          domain,
          fileName: file.name,
          contentType: file.type || "application/octet-stream",
          ...presignMeta,
        }),
      });
    } catch (err) {
      console.error("Presign request failed:", err);
      throw new ApiError("Failed to get upload authorization from server.", 500, err);
    }
  }

  if (!presign?.uploadUrl) {
    throw new ApiError("Invalid upload URL returned from server.", 500, null);
  }

  onProgress?.("uploading");
  const putRes = await fetch(presign.uploadUrl, {
    method: "PUT",
    headers: { "Content-Type": file.type || "application/octet-stream" },
    body: file,
  });

  if (!putRes.ok) {
    const errText = await putRes.text().catch(() => "");
    console.error("S3 upload failed:", putRes.status, errText);
    throw new ApiError(`S3 Upload failed with status ${putRes.status}`, putRes.status, errText);
  }

  onProgress?.("confirming");
  return { s3Key: presign.s3Key, publicUrl: presign.publicUrl };
}

export async function uploadAndConfirm<TResponse>(
  confirmPath: string,
  options: UploadFileOptions,
  metadata: Record<string, unknown>
): Promise<TResponse> {
  let s3Key = "";
  let publicUrl = (metadata.publicUrl as string) || "";

  if (options.file) {
    const uploaded = await uploadFileToS3(options);
    s3Key = uploaded.s3Key;
    publicUrl = uploaded.publicUrl || publicUrl;
  }

  const payload = { ...metadata, s3Key, publicUrl };

  // 1. Post directly to local Vercel serverless API route
  try {
    const localPath = confirmPath.startsWith("/api") ? confirmPath : `/api${confirmPath}`;
    await fetch(localPath, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
  } catch (_) {}

  // 2. Post to external Railway API as fallback
  const result = await apiRequest<TResponse>(confirmPath, {
    method: "POST",
    body: JSON.stringify(payload),
  });

  options.onProgress?.("done");
  return result;
}
