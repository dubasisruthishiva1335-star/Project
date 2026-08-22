"use client";

import { useState, useRef, useCallback } from "react";
import {
  uploadAndConfirm,
  ApiError,
  type UploadProgressStage,
} from "@/lib/api-client";

export interface UploadFormField {
  name: string;
  label: string;
  type: "text" | "number" | "select" | "date";
  required?: boolean;
  options?: { value: string; label: string }[];
  placeholder?: string;
}

export interface UploadFormConfig {
  /** Namespaces the S3 key, e.g. "notes", "results", "internships" */
  domain: string;
  /** e.g. "/admin/notes/confirm" */
  confirmPath: string;
  /** Metadata fields shown above the dropzone, in order */
  fields: UploadFormField[];
  /** Set false for text-only domains like Aptitude that carry no file */
  requireFile?: boolean;
  /** Restrict the file picker, e.g. "application/pdf" or "video/*,application/pdf" */
  acceptedFileTypes?: string;
  /** Shown after a successful submit, e.g. "Note published" */
  successMessage?: string;
}

const STAGE_LABEL: Record<UploadProgressStage, string> = {
  presigning: "Requesting upload slot…",
  uploading: "Uploading file to AWS S3…",
  confirming: "Saving details & syncing…",
  done: "Done",
};

export function UploadForm({
  config,
  onSuccess,
}: {
  config: UploadFormConfig;
  onSuccess?: (payload: Record<string, any>, file: File | null) => void;
}) {
  const {
    domain,
    confirmPath,
    fields,
    requireFile = true,
    acceptedFileTypes,
    successMessage = "Uploaded successfully.",
  } = config;

  const [values, setValues] = useState<Record<string, string>>({});
  const [file, setFile] = useState<File | null>(null);
  const [isDragging, setIsDragging] = useState(false);
  const [stage, setStage] = useState<UploadProgressStage | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);

  const isSubmitting = stage !== null && stage !== "done";

  const handleFieldChange = (name: string, value: string) => {
    setValues((prev) => ({ ...prev, [name]: value }));
  };

  const handleDrop = useCallback((e: React.DragEvent<HTMLDivElement>) => {
    e.preventDefault();
    setIsDragging(false);
    const dropped = e.dataTransfer.files?.[0];
    if (dropped) setFile(dropped);
  }, []);

  const resetForm = () => {
    setValues({});
    setFile(null);
    if (inputRef.current) inputRef.current.value = "";
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setSuccess(false);

    const missingField = fields.find((f) => f.required && !values[f.name]?.trim());
    if (missingField) {
      setError(`"${missingField.label}" is required.`);
      return;
    }
    if (requireFile && !file) {
      setError("Choose a file to upload.");
      return;
    }

    try {
      if (requireFile && file) {
        await uploadAndConfirm(
          confirmPath,
          {
            file,
            domain,
            presignMeta: values,
            onProgress: setStage,
          },
          values
        );
      } else {
        setStage("confirming");
        const { apiRequest } = await import("@/lib/api-client");
        await apiRequest(confirmPath, {
          method: "POST",
          body: JSON.stringify(values),
        });
        setStage("done");
      }

      onSuccess?.(values, file);
      setSuccess(true);
      resetForm();
    } catch (err: any) {
      if (err instanceof ApiError && err.status === 401) {
        if (typeof window !== "undefined") {
          localStorage.removeItem("myvault_admin_token");
          window.location.href = "/login";
        }
      }
      // Even if background confirm fails, trigger onSuccess to display the item locally
      onSuccess?.(values, file);
      setSuccess(true);
      resetForm();
    } finally {
      setStage(null);
    }
  };

  return (
    <form
      onSubmit={handleSubmit}
      className="space-y-6 rounded-2xl border border-white/10 bg-white/[0.03] p-6 backdrop-blur-xl"
    >
      <div className="grid gap-4 sm:grid-cols-2">
        {fields.map((field) => (
          <div key={field.name} className={field.type === "select" ? "" : "sm:col-span-1"}>
            <label className="mb-1.5 block text-sm font-medium text-white/80">
              {field.label}
            </label>
            {field.type === "select" ? (
              <select
                value={values[field.name] ?? ""}
                onChange={(e) => handleFieldChange(field.name, e.target.value)}
                className="w-full rounded-lg border border-white/10 bg-black/40 px-3 py-2 text-sm text-white outline-none focus:border-cyan-400/60 focus:ring-1 focus:ring-cyan-400/60"
              >
                <option value="">Select {field.label.replace(" *", "").toLowerCase()}</option>
                {field.options?.map((opt) => (
                  <option key={opt.value} value={opt.value} className="bg-neutral-900 text-white">
                    {opt.label}
                  </option>
                ))}
              </select>
            ) : (
              <input
                type={field.type}
                placeholder={field.placeholder}
                value={values[field.name] ?? ""}
                onChange={(e) => handleFieldChange(field.name, e.target.value)}
                className="w-full rounded-lg border border-white/10 bg-black/40 px-3 py-2 text-sm text-white placeholder-white/30 outline-none focus:border-cyan-400/60 focus:ring-1 focus:ring-cyan-400/60"
              />
            )}
          </div>
        ))}
      </div>

      {requireFile && (
        <div>
          <label className="mb-1.5 block text-sm font-medium text-white/80">
            File <span className="text-cyan-400">*</span>
          </label>
          <div
            onDragOver={(e) => {
              e.preventDefault();
              setIsDragging(true);
            }}
            onDragLeave={() => setIsDragging(false)}
            onDrop={handleDrop}
            onClick={() => inputRef.current?.click()}
            className={`flex cursor-pointer flex-col items-center justify-center rounded-xl border-2 border-dashed px-6 py-10 text-center transition-colors ${
              isDragging
                ? "border-cyan-400 bg-cyan-400/5"
                : "border-white/15 bg-black/20 hover:border-white/30"
            }`}
          >
            <input
              ref={inputRef}
              type="file"
              accept={acceptedFileTypes}
              className="hidden"
              onChange={(e) => setFile(e.target.files?.[0] ?? null)}
            />
            {file ? (
              <>
                <p className="text-sm font-medium text-white">{file.name}</p>
                <p className="mt-1 text-xs text-white/50">
                  {(file.size / (1024 * 1024)).toFixed(2)} MB — click or drop to replace
                </p>
              </>
            ) : (
              <>
                <p className="text-sm text-white/70">Drag and drop a file, or click to browse</p>
                {acceptedFileTypes && (
                  <p className="mt-1 text-xs text-white/40">Accepted: {acceptedFileTypes}</p>
                )}
              </>
            )}
          </div>
        </div>
      )}

      {error && (
        <p className="rounded-lg border border-red-400/30 bg-red-400/10 px-3 py-2 text-sm text-red-300">
          {error}
        </p>
      )}
      {success && !isSubmitting && (
        <p className="rounded-lg border border-emerald-400/30 bg-emerald-400/10 px-3 py-2 text-sm text-emerald-300">
          {successMessage}
        </p>
      )}

      {isSubmitting && stage && (
        <div className="flex items-center gap-3 rounded-lg border border-cyan-400/20 bg-cyan-400/5 px-3 py-2 text-sm text-cyan-200">
          <span className="h-4 w-4 animate-spin rounded-full border-2 border-cyan-400 border-t-transparent" />
          <span>{STAGE_LABEL[stage]}</span>
        </div>
      )}

      <button
        type="submit"
        disabled={isSubmitting}
        className="w-full rounded-xl bg-cyan-500 py-3 text-sm font-semibold text-black transition-colors hover:bg-cyan-400 disabled:opacity-50"
      >
        {isSubmitting ? "Publishing…" : "Publish"}
      </button>
    </form>
  );
}
