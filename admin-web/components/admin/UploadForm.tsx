"use client";

// components/admin/UploadForm.tsx
//
// One shared form every content page (Notes, Syllabus, Question Banks,
// Lab Manuals, Internships/Placements/Govt Jobs, Results, Aptitude,
// Competitive Exams) renders with a different `fields` config. Handles:
//   - drag/drop or click-to-browse file selection (skipped if requireFile=false,
//     e.g. Aptitude which is text-only per the backend notes)
//   - metadata fields declared by the page (text / select / date)
//   - the 3-step upload via uploadAndConfirm from lib/api-client
//
// Styled to match the app's "Liquid Glass UI": dark frosted cards,
// blue -> cyan accent gradient, thin hairline borders.

import { useCallback, useRef, useState } from "react";
import { ApiError, uploadAndConfirm, type UploadProgressStage } from "@/lib/api-client";

export type FieldType = "text" | "select" | "date" | "number";

export interface UploadFormField {
  name: string;
  label: string;
  type: FieldType;
  required?: boolean;
  placeholder?: string;
  /** For type: "select" */
  options?: { value: string; label: string }[];
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
  uploading: "Uploading file…",
  confirming: "Saving details…",
  done: "Done",
};

export function UploadForm({ config }: { config: UploadFormConfig }) {
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
        // Text-only domains (e.g. Aptitude) skip the presign/S3 steps entirely.
        setStage("confirming");
        const { apiRequest } = await import("@/lib/api-client");
        await apiRequest(confirmPath, {
          method: "POST",
          body: JSON.stringify(values),
        });
        setStage("done");
      }
      setSuccess(true);
      resetForm();
    } catch (err: any) {
      if (err instanceof ApiError && err.status === 401) {
        if (typeof window !== "undefined") {
          localStorage.removeItem("myvault_admin_token");
          window.location.href = "/login";
        }
      }
      setError(err instanceof ApiError ? err.message : "Something went wrong. Try again.");
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
            <label
              htmlFor={field.name}
              className="mb-1.5 block text-sm font-medium text-white/80"
            >
              {field.label}
              {field.required && <span className="text-cyan-400"> *</span>}
            </label>

            {field.type === "select" ? (
              <select
                id={field.name}
                required={field.required}
                value={values[field.name] ?? ""}
                onChange={(e) => handleFieldChange(field.name, e.target.value)}
                className="w-full rounded-lg border border-white/10 bg-black/40 px-3 py-2 text-sm text-white outline-none focus:border-cyan-400/60 focus:ring-1 focus:ring-cyan-400/60"
              >
                <option value="" disabled>
                  Select {field.label.toLowerCase()}
                </option>
                {field.options?.map((opt) => (
                  <option key={opt.value} value={opt.value}>
                    {opt.label}
                  </option>
                ))}
              </select>
            ) : (
              <input
                id={field.name}
                type={field.type}
                required={field.required}
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

      <button
        type="submit"
        disabled={isSubmitting}
        className="w-full rounded-lg bg-gradient-to-r from-blue-500 to-cyan-400 px-4 py-2.5 text-sm font-semibold text-black transition-opacity disabled:cursor-not-allowed disabled:opacity-60"
      >
        {isSubmitting ? STAGE_LABEL[stage as UploadProgressStage] : "Publish"}
      </button>
    </form>
  );
}
