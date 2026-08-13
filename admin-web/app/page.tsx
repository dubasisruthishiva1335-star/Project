"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { apiRequest, ApiError } from "../lib/api-client";

interface Overview {
  students: number;
  notes: number;
  jobListings: number;
  results: number;
}

interface RecentUploads {
  recentNotes: Array<{
    id: string;
    title: string;
    contentType: string;
    unit?: number;
    fileUrl: string;
    uploadedAt: string;
    subject?: {
      name: string;
      code: string;
      branch: string;
      semester: number;
    };
  }>;
  recentJobs: Array<{
    id: string;
    title: string;
    company: string;
    type: string;
    branch?: string;
    applyUrl?: string;
    fileUrl?: string;
    postedAt: string;
  }>;
  recentResults: Array<{
    id: string;
    hallTicket: string;
    semester: number;
    fileUrl: string;
    uploadedAt: string;
  }>;
}

export default function DashboardPage() {
  const router = useRouter();
  const [data, setData] = useState<Overview | null>(null);
  const [recent, setRecent] = useState<RecentUploads | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState<"notes" | "jobs" | "results">("notes");

  useEffect(() => {
    const token = typeof window !== "undefined" ? localStorage.getItem("myvault_admin_token") : null;
    if (!token) {
      router.push("/login");
      return;
    }

    Promise.all([
      apiRequest<Overview>("/admin/analytics/overview"),
      apiRequest<RecentUploads>("/admin/analytics/recent-uploads"),
    ])
      .then(([overviewData, recentData]) => {
        setData(overviewData);
        setRecent(recentData);
      })
      .catch((err) => {
        if (err instanceof ApiError && err.status === 401) {
          localStorage.removeItem("myvault_admin_token");
          router.push("/login");
        } else {
          setError(err instanceof ApiError ? err.message : "Failed to load dashboard data.");
        }
      });
  }, [router]);

  const cards = [
    { label: "Students Registered", value: data?.students, icon: "🎓", color: "from-blue-500/20 to-cyan-500/20" },
    { label: "Academic Resources Uploaded", value: data?.notes, icon: "📚", color: "from-cyan-500/20 to-teal-500/20" },
    { label: "Job & Career Listings", value: data?.jobListings, icon: "💼", color: "from-purple-500/20 to-indigo-500/20" },
    { label: "Exam Results Uploaded", value: data?.results, icon: "📊", color: "from-amber-500/20 to-yellow-500/20" },
  ];

  const formatCategory = (cat: string) => {
    switch (cat.toUpperCase()) {
      case "NOTES": return "📄 Notes";
      case "VIDEO_LECTURE": return "🎬 Video";
      case "LAB_MANUAL": return "🧪 Lab Manual";
      case "CHEAT_SHEET": return "⚡ Cheat Sheet";
      case "ASSIGNMENT": return "📋 Assignment";
      case "QUESTION_BANK": return "📊 Question Bank";
      case "SYLLABUS": return "📜 Syllabus";
      default: return cat;
    }
  };

  return (
    <div className="mx-auto max-w-7xl px-6 py-10">
      <div className="mb-8">
        <h1 className="bg-gradient-to-r from-accentBlue to-accentCyan bg-clip-text text-2xl font-extrabold text-transparent">
          Admin Control Center
        </h1>
        <p className="mt-1 text-sm text-white/50">
          Live overview and management of all uploaded academic resources, career listings, and student results.
        </p>
      </div>

      {error && (
        <p className="mb-6 rounded-lg border border-red-400/30 bg-red-400/10 px-3 py-2 text-sm text-red-300">
          {error}
        </p>
      )}

      {/* Analytics Grid */}
      <div className="mb-10 grid grid-cols-2 gap-4 sm:grid-cols-4">
        {cards.map((c) => (
          <div
            key={c.label}
            className={`rounded-2xl border border-white/10 bg-gradient-to-br ${c.color} p-5 backdrop-blur-xl`}
          >
            <div className="flex items-center justify-between">
              <span className="text-2xl">{c.icon}</span>
              <p className="text-3xl font-black text-accentCyan">{c.value ?? "—"}</p>
            </div>
            <p className="mt-3 text-xs font-semibold text-white/70">{c.label}</p>
          </div>
        ))}
      </div>

      {/* Uploaded Resources Feed */}
      <div className="rounded-2xl border border-white/10 bg-white/[0.02] p-6 backdrop-blur-xl">
        <div className="mb-6 flex flex-wrap items-center justify-between gap-4">
          <div>
            <h2 className="text-lg font-bold text-white">Recently Uploaded Files & Posts</h2>
            <p className="text-xs text-white/50">Verify what has been uploaded directly to AWS S3 & database</p>
          </div>

          <div className="flex rounded-xl border border-white/10 bg-black/40 p-1">
            <button
              onClick={() => setActiveTab("notes")}
              className={`rounded-lg px-4 py-1.5 text-xs font-semibold transition ${
                activeTab === "notes" ? "bg-accentBlue text-white" : "text-white/60 hover:text-white"
              }`}
            >
              Academic Files ({recent?.recentNotes?.length ?? 0})
            </button>
            <button
              onClick={() => setActiveTab("jobs")}
              className={`rounded-lg px-4 py-1.5 text-xs font-semibold transition ${
                activeTab === "jobs" ? "bg-accentBlue text-white" : "text-white/60 hover:text-white"
              }`}
            >
              Jobs & Internships ({recent?.recentJobs?.length ?? 0})
            </button>
            <button
              onClick={() => setActiveTab("results")}
              className={`rounded-lg px-4 py-1.5 text-xs font-semibold transition ${
                activeTab === "results" ? "bg-accentBlue text-white" : "text-white/60 hover:text-white"
              }`}
            >
              Exam Results ({recent?.recentResults?.length ?? 0})
            </button>
          </div>
        </div>

        {/* Tab 1: Academic Files */}
        {activeTab === "notes" && (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="border-b border-white/10 bg-white/[0.02] text-white/50 uppercase">
                <tr>
                  <th className="px-4 py-3">Resource Title</th>
                  <th className="px-4 py-3">Subject</th>
                  <th className="px-4 py-3">Branch & Sem</th>
                  <th className="px-4 py-3">Unit</th>
                  <th className="px-4 py-3">Category</th>
                  <th className="px-4 py-3">Uploaded Date</th>
                  <th className="px-4 py-3 text-right">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-white/5 text-white/80">
                {recent?.recentNotes && recent.recentNotes.length > 0 ? (
                  recent.recentNotes.map((item) => (
                    <tr key={item.id} className="hover:bg-white/[0.02]">
                      <td className="px-4 py-3 font-semibold text-white">{item.title}</td>
                      <td className="px-4 py-3">
                        <span className="rounded bg-accentBlue/20 px-1.5 py-0.5 text-accentCyan font-mono text-[11px] mr-1.5">
                          {item.subject?.code ?? "GEN"}
                        </span>
                        {item.subject?.name ?? "General"}
                      </td>
                      <td className="px-4 py-3">{item.subject?.branch ?? "GEN"} — Sem {item.subject?.semester ?? 1}</td>
                      <td className="px-4 py-3">Unit {item.unit ?? 1}</td>
                      <td className="px-4 py-3 font-medium text-accentCyan">{formatCategory(item.contentType)}</td>
                      <td className="px-4 py-3 text-white/50">
                        {new Date(item.uploadedAt).toLocaleDateString()}
                      </td>
                      <td className="px-4 py-3 text-right">
                        <a
                          href={item.fileUrl}
                          target="_blank"
                          rel="noreferrer"
                          className="inline-flex items-center rounded-lg bg-accentBlue/20 px-3 py-1 text-xs font-semibold text-accentCyan hover:bg-accentBlue/30"
                        >
                          View PDF ↗
                        </a>
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan={7} className="px-4 py-8 text-center text-white/40">
                      No academic files uploaded yet. Go to <a href="/admin/notes" className="text-accentCyan underline">Upload Academic Resources</a> to post files.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        )}

        {/* Tab 2: Job & Internship Listings */}
        {activeTab === "jobs" && (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="border-b border-white/10 bg-white/[0.02] text-white/50 uppercase">
                <tr>
                  <th className="px-4 py-3">Position Title</th>
                  <th className="px-4 py-3">Company / Org</th>
                  <th className="px-4 py-3">Category</th>
                  <th className="px-4 py-3">Target Branch</th>
                  <th className="px-4 py-3">Posted Date</th>
                  <th className="px-4 py-3 text-right">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-white/5 text-white/80">
                {recent?.recentJobs && recent.recentJobs.length > 0 ? (
                  recent.recentJobs.map((job) => (
                    <tr key={job.id} className="hover:bg-white/[0.02]">
                      <td className="px-4 py-3 font-semibold text-white">{job.title}</td>
                      <td className="px-4 py-3 text-accentCyan font-medium">{job.company}</td>
                      <td className="px-4 py-3">
                        <span className="rounded bg-white/10 px-2 py-0.5 font-semibold text-white/80">
                          {job.type}
                        </span>
                      </td>
                      <td className="px-4 py-3">{job.branch ?? "ALL"}</td>
                      <td className="px-4 py-3 text-white/50">
                        {new Date(job.postedAt).toLocaleDateString()}
                      </td>
                      <td className="px-4 py-3 text-right">
                        {job.applyUrl && (
                          <a
                            href={job.applyUrl}
                            target="_blank"
                            rel="noreferrer"
                            className="inline-flex items-center rounded-lg bg-accentBlue/20 px-3 py-1 text-xs font-semibold text-accentCyan hover:bg-accentBlue/30"
                          >
                            Link ↗
                          </a>
                        )}
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan={6} className="px-4 py-8 text-center text-white/40">
                      No job listings posted yet. Go to <a href="/admin/internships" className="text-accentCyan underline">Upload Career Listings</a> to post listings.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        )}

        {/* Tab 3: Exam Results */}
        {activeTab === "results" && (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="border-b border-white/10 bg-white/[0.02] text-white/50 uppercase">
                <tr>
                  <th className="px-4 py-3">Student Hall Ticket</th>
                  <th className="px-4 py-3">Semester</th>
                  <th className="px-4 py-3">Uploaded Date</th>
                  <th className="px-4 py-3 text-right">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-white/5 text-white/80">
                {recent?.recentResults && recent.recentResults.length > 0 ? (
                  recent.recentResults.map((res) => (
                    <tr key={res.id} className="hover:bg-white/[0.02]">
                      <td className="px-4 py-3 font-semibold text-accentCyan">{res.hallTicket}</td>
                      <td className="px-4 py-3">Semester {res.semester}</td>
                      <td className="px-4 py-3 text-white/50">
                        {new Date(res.uploadedAt).toLocaleDateString()}
                      </td>
                      <td className="px-4 py-3 text-right">
                        <a
                          href={res.fileUrl}
                          target="_blank"
                          rel="noreferrer"
                          className="inline-flex items-center rounded-lg bg-accentBlue/20 px-3 py-1 text-xs font-semibold text-accentCyan hover:bg-accentBlue/30"
                        >
                          View PDF ↗
                        </a>
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan={4} className="px-4 py-8 text-center text-white/40">
                      No exam results uploaded yet. Go to <a href="/admin/results" className="text-accentCyan underline">Upload Exam Results</a> to upload grade sheets.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
