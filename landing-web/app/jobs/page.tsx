"use client";

import { useEffect, useState } from "react";
import { apiRequest } from "../../lib/api-client";

interface JobListing {
  id: string;
  type: "INTERNSHIP" | "PLACEMENT" | "GOVT_JOB";
  title: string;
  company: string;
  description?: string;
  applyUrl: string;
  deadline?: string;
  fileUrl?: string;
  branch?: string;
  postedAt: string;
}

export default function JobsPage() {
  const [type, setType] = useState<string>("ALL");
  const [jobs, setJobs] = useState<JobListing[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchJobs = async () => {
    setLoading(true);
    setError(null);
    try {
      const url = type === "ALL" ? "/job-listings" : `/job-listings?type=${type}`;
      const res = await apiRequest<JobListing[]>(url);
      setJobs(res);
    } catch (err: any) {
      setError(err.message || "Failed to load job listings");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchJobs();
  }, [type]);

  const typeTabs = [
    { label: "All Opportunities", value: "ALL" },
    { label: "Internships", value: "INTERNSHIP" },
    { label: "Placements", value: "PLACEMENT" },
    { label: "Govt Jobs", value: "GOVT_JOB" },
  ];

  return (
    <main className="mx-auto max-w-5xl px-6 py-10">
      <div className="mb-8 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-3xl font-bold">Internships & Opportunities</h1>
          <p className="mt-1 text-sm text-white/50">
            Curated internships, campus placements & government job notifications
          </p>
        </div>

        {/* Category Tabs */}
        <div className="flex flex-wrap gap-1.5 rounded-2xl border border-white/10 bg-white/[0.03] p-1.5 backdrop-blur-xl">
          {typeTabs.map((t) => (
            <button
              key={t.value}
              onClick={() => setType(t.value)}
              className={`rounded-xl px-3 py-1.5 text-xs font-semibold transition-all ${
                type === t.value
                  ? "bg-gradient-to-r from-accentBlue to-accentCyan text-black shadow-md"
                  : "text-white/70 hover:bg-white/5 hover:text-white"
              }`}
            >
              {t.label}
            </button>
          ))}
        </div>
      </div>

      {error && (
        <div className="mb-6 rounded-xl border border-amber-500/30 bg-amber-500/10 p-3 text-xs text-amber-300">
          {error}
        </div>
      )}

      {loading ? (
        <div className="flex h-64 items-center justify-center">
          <div className="h-8 w-8 animate-spin rounded-full border-2 border-accentCyan border-t-transparent"></div>
        </div>
      ) : jobs.length === 0 ? (
        <div className="rounded-3xl border border-dashed border-white/15 p-12 text-center text-white/40">
          <p className="text-lg font-medium">No job listings found</p>
          <p className="mt-1 text-xs">Check back soon for new postings!</p>
        </div>
      ) : (
        <div className="grid gap-4 sm:grid-cols-2">
          {jobs.map((job) => (
            <div
              key={job.id}
              className="flex flex-col justify-between rounded-2xl border border-white/10 bg-white/[0.03] p-6 shadow-xl backdrop-blur-xl transition-all hover:border-white/20"
            >
              <div>
                <div className="flex items-center justify-between">
                  <span
                    className={`rounded-md px-2.5 py-1 text-[10px] font-extrabold uppercase tracking-wider ${
                      job.type === "INTERNSHIP"
                        ? "bg-purple-500/20 text-purple-300"
                        : job.type === "GOVT_JOB"
                        ? "bg-amber-500/20 text-amber-300"
                        : "bg-emerald-500/20 text-emerald-300"
                    }`}
                  >
                    {job.type.replace("_", " ")}
                  </span>
                  {job.branch && (
                    <span className="text-xs text-white/40">{job.branch}</span>
                  )}
                </div>

                <h3 className="mt-3 text-lg font-bold text-white">{job.title}</h3>
                <p className="text-sm font-medium text-accentCyan">{job.company}</p>

                {job.description && (
                  <p className="mt-2 text-xs text-white/60 line-clamp-3">
                    {job.description}
                  </p>
                )}
              </div>

              <div className="mt-6 flex items-center justify-between border-t border-white/10 pt-4">
                <span className="text-[11px] text-white/40">
                  Posted {new Date(job.postedAt).toLocaleDateString()}
                </span>
                <a
                  href={job.applyUrl}
                  target="_blank"
                  rel="noreferrer"
                  className="rounded-xl bg-white/10 px-4 py-2 text-xs font-semibold text-white transition-colors hover:bg-accentCyan hover:text-black"
                >
                  Apply Now →
                </a>
              </div>
            </div>
          ))}
        </div>
      )}
    </main>
  );
}
