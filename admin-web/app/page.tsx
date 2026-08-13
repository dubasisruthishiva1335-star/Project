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
  allStudents: Array<{
    id: string;
    hallTicket: string;
    fullName: string;
    branch: string;
    semester: number;
    createdAt: string;
  }>;
}

export default function DashboardPage() {
  const router = useRouter();
  const [data, setData] = useState<Overview | null>(null);
  const [recent, setRecent] = useState<RecentUploads | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState<"notes" | "jobs" | "students" | "results">("notes");
  const [searchQuery, setSearchQuery] = useState("");

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

  const cards: Array<{
    id: "students" | "notes" | "jobs" | "results";
    label: string;
    value: number | undefined;
    icon: string;
    color: string;
  }> = [
    { id: "notes", label: "Academic Materials Uploaded", value: recent?.recentNotes?.length ?? data?.notes, icon: "📚", color: "from-cyan-500/20 to-teal-500/20" },
    { id: "jobs", label: "Job & Internship Listings", value: recent?.recentJobs?.length ?? data?.jobListings, icon: "💼", color: "from-purple-500/20 to-indigo-500/20" },
    { id: "students", label: "Students Registered", value: recent?.allStudents?.length ?? data?.students, icon: "🎓", color: "from-blue-500/20 to-cyan-500/20" },
    { id: "results", label: "Exam Results Uploaded", value: recent?.recentResults?.length ?? data?.results, icon: "📊", color: "from-amber-500/20 to-yellow-500/20" },
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

  const filteredNotes = (recent?.recentNotes ?? []).filter((n) =>
    n.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
    (n.subject?.name ?? "").toLowerCase().includes(searchQuery.toLowerCase()) ||
    (n.subject?.code ?? "").toLowerCase().includes(searchQuery.toLowerCase())
  );

  const filteredJobs = (recent?.recentJobs ?? []).filter((j) =>
    j.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
    j.company.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const filteredStudents = (recent?.allStudents ?? []).filter((s) =>
    s.fullName.toLowerCase().includes(searchQuery.toLowerCase()) ||
    s.hallTicket.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const filteredResults = (recent?.recentResults ?? []).filter((r) =>
    r.hallTicket.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="mx-auto max-w-7xl px-6 py-10">
      <div className="mb-8">
        <h1 className="bg-gradient-to-r from-accentBlue to-accentCyan bg-clip-text text-2xl font-extrabold text-transparent">
          Admin Control Center
        </h1>
        <p className="mt-1 text-sm text-white/50">
          Live management and itemized preview of all uploaded academic resources, job listings, exam results, and registered students.
        </p>
      </div>

      {error && (
        <p className="mb-6 rounded-lg border border-red-400/30 bg-red-400/10 px-3 py-2 text-sm text-red-300">
          {error}
        </p>
      )}

      {/* Interactive Analytics Grid */}
      <div className="mb-10 grid grid-cols-2 gap-4 sm:grid-cols-4">
        {cards.map((c) => {
          const isSelected = activeTab === c.id;
          return (
            <button
              key={c.id}
              onClick={() => setActiveTab(c.id)}
              className={`text-left transition-all duration-200 rounded-2xl border p-5 backdrop-blur-xl ${
                isSelected
                  ? "border-accentCyan bg-accentBlue/20 shadow-lg shadow-accentCyan/10 scale-[1.02]"
                  : "border-white/10 bg-gradient-to-br " + c.color + " hover:border-white/20 hover:scale-[1.01]"
              }`}
            >
              <div className="flex items-center justify-between">
                <span className="text-2xl">{c.icon}</span>
                <p className="text-3xl font-black text-accentCyan">{c.value ?? "—"}</p>
              </div>
              <p className="mt-3 text-xs font-bold text-white/90">{c.label}</p>
              <p className="mt-0.5 text-[11px] text-accentCyan font-medium">Click to view items ↓</p>
            </button>
          );
        })}
      </div>

      {/* Itemized Feed Section */}
      <div className="rounded-2xl border border-white/10 bg-white/[0.02] p-6 backdrop-blur-xl">
        <div className="mb-6 flex flex-wrap items-center justify-between gap-4">
          <div>
            <h2 className="text-lg font-bold text-white flex items-center gap-2">
              <span>
                {activeTab === "notes" && "📚 Academic Materials List"}
                {activeTab === "jobs" && "💼 Job & Internship Listings"}
                {activeTab === "students" && "🎓 Registered Students Directory"}
                {activeTab === "results" && "📊 Uploaded Exam Results"}
              </span>
            </h2>
            <p className="text-xs text-white/50">
              Showing total uploaded items stored in AWS S3 and database
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-3">
            {/* Search Input */}
            <input
              type="text"
              placeholder="Search items..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="rounded-xl border border-white/10 bg-black/50 px-3.5 py-1.5 text-xs text-white placeholder-white/40 focus:border-accentCyan focus:outline-none"
            />

            {/* Filter Navigation Tabs */}
            <div className="flex rounded-xl border border-white/10 bg-black/40 p-1">
              <button
                onClick={() => setActiveTab("notes")}
                className={`rounded-lg px-3 py-1.5 text-xs font-semibold transition ${
                  activeTab === "notes" ? "bg-accentBlue text-white" : "text-white/60 hover:text-white"
                }`}
              >
                Academic Materials ({recent?.recentNotes?.length ?? 0})
              </button>
              <button
                onClick={() => setActiveTab("jobs")}
                className={`rounded-lg px-3 py-1.5 text-xs font-semibold transition ${
                  activeTab === "jobs" ? "bg-accentBlue text-white" : "text-white/60 hover:text-white"
                }`}
              >
                Jobs ({recent?.recentJobs?.length ?? 0})
              </button>
              <button
                onClick={() => setActiveTab("students")}
                className={`rounded-lg px-3 py-1.5 text-xs font-semibold transition ${
                  activeTab === "students" ? "bg-accentBlue text-white" : "text-white/60 hover:text-white"
                }`}
              >
                Students ({recent?.allStudents?.length ?? 0})
              </button>
              <button
                onClick={() => setActiveTab("results")}
                className={`rounded-lg px-3 py-1.5 text-xs font-semibold transition ${
                  activeTab === "results" ? "bg-accentBlue text-white" : "text-white/60 hover:text-white"
                }`}
              >
                Results ({recent?.recentResults?.length ?? 0})
              </button>
            </div>
          </div>
        </div>

        {/* Tab 1: Academic Materials List */}
        {activeTab === "notes" && (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="border-b border-white/10 bg-white/[0.02] text-white/50 uppercase">
                <tr>
                  <th className="px-4 py-3">Resource Title</th>
                  <th className="px-4 py-3">Subject Name & Code</th>
                  <th className="px-4 py-3">Branch & Semester</th>
                  <th className="px-4 py-3">Unit</th>
                  <th className="px-4 py-3">Category</th>
                  <th className="px-4 py-3">Uploaded Date</th>
                  <th className="px-4 py-3 text-right">Preview Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-white/5 text-white/80">
                {filteredNotes.length > 0 ? (
                  filteredNotes.map((item) => (
                    <tr key={item.id} className="hover:bg-white/[0.02]">
                      <td className="px-4 py-3 font-semibold text-white">{item.title}</td>
                      <td className="px-4 py-3">
                        <span className="rounded bg-accentBlue/20 px-1.5 py-0.5 text-accentCyan font-mono text-[11px] mr-1.5 font-bold">
                          {item.subject?.code ?? "GEN"}
                        </span>
                        {item.subject?.name ?? "General Subject"}
                      </td>
                      <td className="px-4 py-3">{item.subject?.branch ?? "GEN"} — Sem {item.subject?.semester ?? 1}</td>
                      <td className="px-4 py-3 font-semibold text-white/90">Unit {item.unit ?? 1}</td>
                      <td className="px-4 py-3 font-medium text-accentCyan">{formatCategory(item.contentType)}</td>
                      <td className="px-4 py-3 text-white/50">
                        {new Date(item.uploadedAt).toLocaleDateString()}
                      </td>
                      <td className="px-4 py-3 text-right">
                        <a
                          href={item.fileUrl}
                          target="_blank"
                          rel="noreferrer"
                          className="inline-flex items-center rounded-lg bg-accentBlue/20 px-3 py-1 text-xs font-semibold text-accentCyan hover:bg-accentBlue/30 border border-accentBlue/40"
                        >
                          View PDF ↗
                        </a>
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan={7} className="px-4 py-8 text-center text-white/40">
                      No academic materials found. <a href="/admin/notes" className="text-accentCyan underline font-semibold">Click here to upload notes, videos, or lab manuals</a>.
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
                  <th className="px-4 py-3">Listing Category</th>
                  <th className="px-4 py-3">Target Branch</th>
                  <th className="px-4 py-3">Posted Date</th>
                  <th className="px-4 py-3 text-right">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-white/5 text-white/80">
                {filteredJobs.length > 0 ? (
                  filteredJobs.map((job) => (
                    <tr key={job.id} className="hover:bg-white/[0.02]">
                      <td className="px-4 py-3 font-semibold text-white">{job.title}</td>
                      <td className="px-4 py-3 text-accentCyan font-medium">{job.company}</td>
                      <td className="px-4 py-3">
                        <span className="rounded bg-white/10 px-2 py-0.5 font-semibold text-white/80">
                          {job.type}
                        </span>
                      </td>
                      <td className="px-4 py-3">{job.branch ?? "ALL BRANCHES"}</td>
                      <td className="px-4 py-3 text-white/50">
                        {new Date(job.postedAt).toLocaleDateString()}
                      </td>
                      <td className="px-4 py-3 text-right">
                        {job.applyUrl && (
                          <a
                            href={job.applyUrl}
                            target="_blank"
                            rel="noreferrer"
                            className="inline-flex items-center rounded-lg bg-accentBlue/20 px-3 py-1 text-xs font-semibold text-accentCyan hover:bg-accentBlue/30 border border-accentBlue/40"
                          >
                            Application Link ↗
                          </a>
                        )}
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan={6} className="px-4 py-8 text-center text-white/40">
                      No job listings posted. <a href="/admin/internships" className="text-accentCyan underline font-semibold">Click here to add internship or placement drive</a>.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        )}

        {/* Tab 3: Registered Students */}
        {activeTab === "students" && (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="border-b border-white/10 bg-white/[0.02] text-white/50 uppercase">
                <tr>
                  <th className="px-4 py-3">Student Name</th>
                  <th className="px-4 py-3">Hall Ticket Number</th>
                  <th className="px-4 py-3">Branch</th>
                  <th className="px-4 py-3">Semester</th>
                  <th className="px-4 py-3">Registered Date</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-white/5 text-white/80">
                {filteredStudents.length > 0 ? (
                  filteredStudents.map((s) => (
                    <tr key={s.id} className="hover:bg-white/[0.02]">
                      <td className="px-4 py-3 font-semibold text-white">{s.fullName}</td>
                      <td className="px-4 py-3 text-accentCyan font-mono font-bold">{s.hallTicket}</td>
                      <td className="px-4 py-3">{s.branch}</td>
                      <td className="px-4 py-3">Semester {s.semester}</td>
                      <td className="px-4 py-3 text-white/50">
                        {new Date(s.createdAt).toLocaleDateString()}
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan={5} className="px-4 py-8 text-center text-white/40">
                      No registered students found.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        )}

        {/* Tab 4: Exam Results */}
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
                {filteredResults.length > 0 ? (
                  filteredResults.map((res) => (
                    <tr key={res.id} className="hover:bg-white/[0.02]">
                      <td className="px-4 py-3 font-semibold text-accentCyan font-mono font-bold">{res.hallTicket}</td>
                      <td className="px-4 py-3">Semester {res.semester}</td>
                      <td className="px-4 py-3 text-white/50">
                        {new Date(res.uploadedAt).toLocaleDateString()}
                      </td>
                      <td className="px-4 py-3 text-right">
                        <a
                          href={res.fileUrl}
                          target="_blank"
                          rel="noreferrer"
                          className="inline-flex items-center rounded-lg bg-accentBlue/20 px-3 py-1 text-xs font-semibold text-accentCyan hover:bg-accentBlue/30 border border-accentBlue/40"
                        >
                          View Grade Sheet PDF ↗
                        </a>
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan={4} className="px-4 py-8 text-center text-white/40">
                      No exam results uploaded yet. <a href="/admin/results" className="text-accentCyan underline font-semibold">Click here to upload semester results</a>.
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
