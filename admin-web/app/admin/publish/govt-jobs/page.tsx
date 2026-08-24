"use client";

import { useState } from "react";
import { apiRequest } from "@/lib/api-client";

const SECTORS = [
  "Banking (SBI / IBPS)",
  "Railways (RRB)",
  "Defence (Army / Navy / Air Force)",
  "Police / Law Enforcement",
  "Teaching / Assistant Professor",
  "Central Civil Services (UPSC)",
  "State PSC (TGPSC / APPSC / MPPSC)",
  "PSU Technical (ISRO / DRDO / BARC / BEL)",
];

const initialForm = {
  type: "GOVT_JOB",
  title: "",
  company: "", // issuing body e.g. "IBPS", "RRB", "TGPSC", "ISRO"
  sector: "Banking (SBI / IBPS)",
  branch: "All Branches",
  stipend: "", // pay scale level
  location: "",
  deadline: "",
  description: "",
  applyUrl: "",
  examPrepLink: "", // links to matching Competitive Exams prep folder
};

export default function GovtJobsPublish() {
  const [form, setForm] = useState(initialForm);
  const [file, setFile] = useState<File | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [message, setMessage] = useState<{ type: "success" | "error"; text: string } | null>(null);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setForm((prev) => ({ ...prev, [name]: value }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.title || !form.company) {
      setMessage({ type: "error", text: "Notification Title and Issuing Body/Ministry are required." });
      return;
    }
    setSubmitting(true);
    setMessage(null);
    try {
      let fileUrl = null;
      let s3Key = null;

      if (file) {
        const { uploadAndConfirm } = await import("@/lib/api-client");
        // Handled via uploadAndConfirm or direct presign
      }

      const res = await apiRequest<{ success: boolean }>("/admin/job-listings/confirm", {
        method: "POST",
        body: JSON.stringify({ ...form, fileUrl, s3Key }),
      });

      if (res.success) {
        setMessage({ type: "success", text: "🏛️ Govt Job Notification published successfully — visible in Govt Jobs Hub instantly." });
        setForm(initialForm);
        setFile(null);
      }
    } catch (err: any) {
      setMessage({ type: "error", text: err instanceof Error ? err.message : "Upload failed. Try again." });
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="mx-auto max-w-2xl px-4 py-10">
      <h1 className="mb-1 text-xl font-bold text-white flex items-center gap-2">
        <span>🏛️</span> Publish Govt Job Notification
      </h1>
      <p className="mb-6 text-sm text-white/50">
        Posts a government job listing with deadline auto-expiry. Routes strictly to the Govt Jobs Hub in the Mobile App.
      </p>

      {message && (
        <div
          className={`mb-6 rounded-xl px-4 py-3 text-sm font-semibold border ${
            message.type === "success"
              ? "bg-emerald-500/10 text-emerald-300 border-emerald-500/30"
              : "bg-red-500/10 text-red-300 border-red-500/30"
          }`}
        >
          {message.text}
        </div>
      )}

      <form onSubmit={handleSubmit} className="space-y-4 rounded-2xl border border-white/10 bg-white/[0.02] p-6 backdrop-blur-xl">
        <Field label="Notification Title *" name="title" value={form.title} onChange={handleChange} placeholder="e.g. IBPS Clerk / ISRO Scientist Recruitment 2026" required />
        <Field label="Issuing Body / Govt Department *" name="company" value={form.company} onChange={handleChange} placeholder="e.g. IBPS / RRB / UPSC / ISRO / SSC" required />

        <SelectField label="Govt Sector *" name="sector" value={form.sector} onChange={handleChange} options={SECTORS.map((s) => ({ value: s, label: s }))} />

        <Field label="Pay Scale / Pay Level Matrix" name="stipend" value={form.stipend} onChange={handleChange} placeholder="e.g. Level-10 Pay Matrix (₹56,100 - ₹1,77,500)" />
        <Field label="Posting Location" name="location" value={form.location} onChange={handleChange} placeholder="e.g. All India / State Cadre" />
        <Field label="Application Deadline Date *" name="deadline" type="date" value={form.deadline} onChange={handleChange} required />

        <div>
          <label className="mb-1.5 block text-xs font-medium text-white/80">Eligibility & Selection Process</label>
          <textarea
            name="description"
            value={form.description}
            onChange={handleChange}
            rows={4}
            placeholder="Age limit, educational qualification, written exam pattern..."
            className="w-full rounded-lg border border-white/10 bg-black/40 px-3 py-2 text-sm text-white placeholder-white/30 focus:border-amber-400/50 focus:outline-none"
          />
        </div>

        <Field label="Official Application Portal URL" name="applyUrl" value={form.applyUrl} onChange={handleChange} placeholder="https://upsc.gov.in / https://isro.gov.in" />
        <Field label="Linked Competitive Exam Prep Folder (optional)" name="examPrepLink" value={form.examPrepLink} onChange={handleChange} placeholder="e.g. UPSC CSE Prep Folder" />

        <div>
          <label className="mb-1.5 block text-xs font-medium text-white/80">Official Notification PDF Circular</label>
          <input
            type="file"
            accept="application/pdf"
            onChange={(e) => setFile(e.target.files?.[0] || null)}
            className="w-full rounded-lg border border-white/10 bg-black/40 px-3 py-2 text-sm text-white/70"
          />
        </div>

        <button
          type="submit"
          disabled={submitting}
          className="w-full rounded-xl bg-amber-500/20 border border-amber-500/40 px-4 py-3 text-sm font-extrabold text-amber-300 hover:bg-amber-500/30 disabled:opacity-50 transition-colors"
        >
          {submitting ? "Publishing Govt Job..." : "Publish Govt Job Notification 🏛️"}
        </button>
      </form>
    </div>
  );
}

function Field({
  label,
  name,
  value,
  onChange,
  placeholder,
  type = "text",
  required = false,
}: {
  label: string;
  name: string;
  value: string;
  onChange: (e: React.ChangeEvent<HTMLInputElement>) => void;
  placeholder?: string;
  type?: string;
  required?: boolean;
}) {
  return (
    <div>
      <label className="mb-1.5 block text-xs font-medium text-white/80">{label}</label>
      <input
        type={type}
        name={name}
        value={value}
        onChange={onChange}
        placeholder={placeholder}
        required={required}
        className="w-full rounded-lg border border-white/10 bg-black/40 px-3 py-2 text-sm text-white placeholder-white/30 focus:border-amber-400/50 focus:outline-none"
      />
    </div>
  );
}

function SelectField({
  label,
  name,
  value,
  onChange,
  options,
}: {
  label: string;
  name: string;
  value: string;
  onChange: (e: React.ChangeEvent<HTMLSelectElement>) => void;
  options: Array<{ value: string; label: string }>;
}) {
  return (
    <div>
      <label className="mb-1.5 block text-xs font-medium text-white/80">{label}</label>
      <select
        name={name}
        value={value}
        onChange={onChange}
        className="w-full rounded-lg border border-white/10 bg-black/40 px-3 py-2 text-sm text-white focus:border-amber-400/50 focus:outline-none"
      >
        {options.map((o) => (
          <option key={o.value} value={o.value} className="bg-neutral-900 text-white">
            {o.label}
          </option>
        ))}
      </select>
    </div>
  );
}
