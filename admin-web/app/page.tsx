"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { apiRequest, ApiError } from "../lib/api-client";

interface Overview {
  students: number;
  notes: number;
  jobListings: number;
  examsCount: number;
  results: number;
}

interface ExamVideo {
  id: string;
  title: string;
  subject?: string;
  duration?: string;
  s3Url?: string;
  pdfUrl?: string;
}

interface ExamItem {
  id: string;
  name: string;
  cat: string;
  icon?: string;
  description?: string;
  eligibility?: string;
  ageLimit?: string;
  selectionProcess?: string;
  syllabusSummary?: string;
  videos?: ExamVideo[];
  pdfNotes?: Array<{ id: string; title: string; subject: string; fileUrl: string }>;
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
    stipend?: string;
    applyUrl?: string;
    fileUrl?: string;
    postedAt: string;
  }>;
  recentExams?: ExamItem[];
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

const DEFAULT_EXAMS: ExamItem[] = [
  {
    id: "exam_upsc",
    name: "UPSC Civil Services (IAS / IPS / IFS)",
    cat: "Government",
    icon: "🏛️",
    videos: [],
    pdfNotes: [],
  },
  {
    id: "exam_ssc",
    name: "SSC CGL (Staff Selection Commission)",
    cat: "Government",
    icon: "🏛️",
    videos: [],
    pdfNotes: [],
  },
  {
    id: "exam_banking",
    name: "SBI PO / IBPS PO & Clerk",
    cat: "Banking",
    icon: "🏦",
    videos: [],
    pdfNotes: [],
  },
];

export default function DashboardPage() {
  const router = useRouter();
  const [data, setData] = useState<Overview | null>(null);
  const [recent, setRecent] = useState<RecentUploads | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState<"notes" | "placements" | "govtJobs" | "exams" | "students" | "results">("notes");
  const [searchQuery, setSearchQuery] = useState("");
  const [editingItem, setEditingItem] = useState<{ id: string; type: "notes" | "jobs" | "exams"; title: string; subtitle?: string } | null>(null);
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const [viewMode, setViewMode] = useState<"folders" | "table">("folders");

  const refreshData = () => {
    setError(null);
    Promise.all([
      apiRequest<Overview>("/admin/analytics/overview").catch(() => ({ students: 0, notes: 0, jobListings: 0, examsCount: 0, results: 0 })),
      apiRequest<RecentUploads>("/admin/analytics/recent-uploads").catch(() => ({ recentNotes: [], recentJobs: [], recentExams: [], recentResults: [], allStudents: [] })),
      apiRequest<any[]>("/admin/internships").catch(() => []),
      apiRequest<any[]>("/admin/notes").catch(() => []),
    ])
      .then(([overviewData, recentData, internshipsData, notesData]) => {
        const jobsList = (recentData.recentJobs && recentData.recentJobs.length > 0)
          ? recentData.recentJobs
          : (internshipsData || []).map((i: any) => ({
              id: i.id,
              title: i.title,
              company: i.company,
              type: i.type,
              branch: i.branch,
              stipend: i.stipend,
              applyUrl: i.apply_url || i.applyUrl,
              fileUrl: i.file_url || i.fileUrl,
              postedAt: i.posted_at || i.postedAt || new Date().toISOString(),
            }));

        const notesList = (recentData.recentNotes && recentData.recentNotes.length > 0)
          ? recentData.recentNotes
          : (notesData || []).map((n: any) => ({
              id: n.id,
              title: n.title,
              contentType: n.content_type || n.contentType || "NOTES",
              unit: n.unit || 1,
              fileUrl: n.file_url || n.fileUrl,
              uploadedAt: n.uploaded_at || n.uploadedAt || new Date().toISOString(),
              subject: {
                name: n.title,
                code: n.branch || "GEN",
                branch: n.branch || "GEN",
                semester: n.semester || 1,
              },
            }));

        setData({
          ...overviewData,
          jobListings: jobsList.length,
          notes: notesList.length,
        });

        setRecent({
          ...recentData,
          recentJobs: jobsList,
          recentNotes: notesList,
          recentExams: recentData.recentExams && recentData.recentExams.length > 0 ? recentData.recentExams : DEFAULT_EXAMS,
        });
      })
      .catch((err) => {
        if (err instanceof ApiError && err.status === 401) {
          localStorage.removeItem("myvault_admin_token");
          router.push("/login");
        } else {
          setRecent((prev) => prev ?? { recentNotes: [], recentJobs: [], recentExams: DEFAULT_EXAMS, recentResults: [], allStudents: [] });
        }
      });
  };

  useEffect(() => {
    refreshData();
  }, [router]);

  const handleDelete = async (type: "notes" | "jobs" | "exams" | "results", id: string) => {
    if (!confirm("Are you sure you want to delete this item? It will be removed from both Website and Mobile App immediately.")) {
      return;
    }
    setDeletingId(id);
    try {
      const endpoint =
        type === "notes"
          ? `/admin/notes/${id}`
          : type === "jobs"
          ? `/admin/job-listings/${id}`
          : type === "exams"
          ? `/admin/exams/${id}`
          : `/admin/results/${id}`;
      await apiRequest(endpoint, { method: "DELETE" });
      refreshData();
    } catch (err) {
      alert("Failed to delete item: " + (err instanceof Error ? err.message : "Unknown error"));
    } finally {
      setDeletingId(null);
    }
  };

  const handleSaveEdit = async () => {
    if (!editingItem) return;
    try {
      if (editingItem.type === "notes") {
        await apiRequest(`/admin/notes/${editingItem.id}`, {
          method: "PATCH",
          body: JSON.stringify({ title: editingItem.title }),
        });
      } else if (editingItem.type === "jobs") {
        await apiRequest(`/admin/job-listings/${editingItem.id}`, {
          method: "PATCH",
          body: JSON.stringify({ title: editingItem.title, company: editingItem.subtitle }),
        });
      } else {
        await apiRequest(`/admin/exams/${editingItem.id}`, {
          method: "PATCH",
          body: JSON.stringify({ title: editingItem.title }),
        });
      }
      setEditingItem(null);
      refreshData();
    } catch (err) {
      alert("Failed to update item: " + (err instanceof Error ? err.message : "Unknown error"));
    }
  };

  const placementCount = (recent?.recentJobs ?? []).filter(j => j.type === "PLACEMENT").length;
  const govtJobCount = (recent?.recentJobs ?? []).filter(j => j.type === "GOVT_JOB").length;
  const examsList = recent?.recentExams ?? DEFAULT_EXAMS;

  const cards: Array<{
    id: "notes" | "placements" | "govtJobs" | "exams" | "students";
    label: string;
    value: number | undefined;
    icon: string;
    color: string;
  }> = [
    { id: "notes", label: "Academic Notes", value: recent?.recentNotes?.length ?? data?.notes, icon: "📚", color: "from-cyan-500/20 to-teal-500/20" },
    { id: "placements", label: "Campus Placements", value: placementCount, icon: "🏢", color: "from-purple-500/20 to-violet-500/20" },
    { id: "govtJobs", label: "Govt Jobs Hub", value: govtJobCount, icon: "🏛️", color: "from-emerald-500/20 to-green-500/20" },
    { id: "exams", label: "Competitive Exams", value: data?.examsCount ?? examsList.length, icon: "🎓", color: "from-amber-500/20 to-yellow-500/20" },
    { id: "students", label: "Students Registered", value: recent?.allStudents?.length ?? data?.students, icon: "👤", color: "from-indigo-500/20 to-cyan-500/20" },
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

  const filteredExams = (examsList ?? []).filter((e) =>
    e.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    e.cat.toLowerCase().includes(searchQuery.toLowerCase()) ||
    (e.videos ?? []).some((v) => v.title.toLowerCase().includes(searchQuery.toLowerCase()))
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
          Manage everything uploaded to the platform: Academic Resources, Jobs, Competitive Exam Materials, Results, and Students.
        </p>
      </div>

      {error && (
        <p className="mb-6 rounded-lg border border-red-400/30 bg-red-400/10 px-3 py-2 text-sm text-red-300">
          {error}
        </p>
      )}

      {/* Interactive Analytics Grid */}
      <div className="mb-10 grid grid-cols-2 gap-4 sm:grid-cols-5">
        {cards.map((c) => {
          const isSelected = activeTab === c.id;
          return (
            <button
              key={c.id}
              onClick={() => setActiveTab(c.id)}
              className={`text-left transition-all duration-200 rounded-2xl border p-4 backdrop-blur-xl ${
                isSelected
                  ? "border-accentCyan bg-accentBlue/20 shadow-lg shadow-accentCyan/10 scale-[1.02]"
                  : "border-white/10 bg-gradient-to-br " + c.color + " hover:border-white/20 hover:scale-[1.01]"
              }`}
            >
              <div className="flex items-center justify-between">
                <span className="text-2xl">{c.icon}</span>
                <p className="text-2xl font-black text-accentCyan">{c.value ?? "—"}</p>
              </div>
              <p className="mt-2 text-xs font-bold text-white/90">{c.label}</p>
              <p className="mt-0.5 text-[10px] text-accentCyan font-medium">Click to manage ↓</p>
            </button>
          );
        })}
      </div>

      {/* Itemized Management Table */}
      <div className="rounded-2xl border border-white/10 bg-white/[0.02] p-6 backdrop-blur-xl">
        {/* Tab Header & View Toggle (Folders View vs Table View) */}
        <div className="mb-6 flex flex-wrap items-center justify-between gap-4">
          <div>
            <h2 className="text-lg font-bold text-white flex items-center gap-2">
              <span>
                {activeTab === "notes" && "📚 Academic Materials & Study Folders"}
                {activeTab === "placements" && "🏢 Campus Placement Drives Folders"}
                {activeTab === "govtJobs" && "🏛️ Govt Jobs Notifications Folders"}
                {activeTab === "exams" && "🎓 Competitive Exam Video Lectures & Notes"}
                {activeTab === "students" && "👤 Registered Students Directory"}
                {activeTab === "results" && "📊 Exam Results Uploaded"}
              </span>
            </h2>
            <p className="text-xs text-white/50">Organized into folders by Branch, Semester, Subject, and Category — syncs to Website and Mobile App</p>
          </div>

          <div className="flex flex-wrap items-center gap-3">
            {/* View Mode Toggle: Folders vs Table */}
            <div className="flex rounded-xl border border-white/10 bg-black/50 p-1">
              <button
                onClick={() => setViewMode("folders")}
                className={`rounded-lg px-3 py-1 text-xs font-semibold transition ${
                  viewMode === "folders" ? "bg-accentCyan text-black" : "text-white/60 hover:text-white"
                }`}
              >
                📁 Folder View
              </button>
              <button
                onClick={() => setViewMode("table")}
                className={`rounded-lg px-3 py-1 text-xs font-semibold transition ${
                  viewMode === "table" ? "bg-accentCyan text-black" : "text-white/60 hover:text-white"
                }`}
              >
                📋 Table View
              </button>
            </div>

            <input
              type="text"
              placeholder="Search uploaded items or folders..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="rounded-xl border border-white/10 bg-black/50 px-3.5 py-1.5 text-xs text-white placeholder-white/40 focus:border-accentCyan focus:outline-none"
            />
          </div>
        </div>

        {/* Folder Structure View Mode: Academic Notes */}
        {viewMode === "folders" && activeTab === "notes" && (
          <div className="space-y-4">
            {filteredNotes.length === 0 ? (
              <div className="py-12 text-center text-white/40">
                <p className="text-3xl mb-2">📂</p>
                <p className="text-sm font-semibold">No uploaded folders or study materials found.</p>
              </div>
            ) : (
              // Group notes into Branch & Semester Folders
              Object.entries(
                filteredNotes.reduce((acc: any, note) => {
                  const branchKey = `📂 Academic Folder: ${note.subject?.branch || "GENERAL"} — Sem ${note.subject?.semester || 1}`;
                  (acc[branchKey] ||= []).push(note);
                  return acc;
                }, {})
              ).map(([folderName, notesList]: [string, any]) => (
                <div key={folderName} className="rounded-xl border border-white/10 bg-white/[0.02] overflow-hidden backdrop-blur-md">
                  <div className="flex items-center justify-between border-b border-white/10 bg-white/5 px-4 py-3">
                    <div className="flex items-center space-x-3">
                      <span className="text-xl">📁</span>
                      <div>
                        <h3 className="text-sm font-bold text-white">{folderName}</h3>
                        <p className="text-[10px] text-accentCyan">{notesList.length} Uploaded Resource{notesList.length > 1 ? "s" : ""}</p>
                      </div>
                    </div>
                  </div>
                  <div className="divide-y divide-white/5 p-2">
                    {notesList.map((item: any) => (
                      <div key={item.id} className="flex items-center justify-between p-3 rounded-lg hover:bg-white/5 transition-colors">
                        <div className="flex items-center space-x-3">
                          <span className="text-base">{item.contentType === "VIDEO_LECTURE" ? "🎬" : "📄"}</span>
                          <div>
                            <p className="text-xs font-bold text-white">{item.title}</p>
                            <p className="text-[10px] text-white/50">Unit {item.unit || 1} • {formatCategory(item.contentType)} • {new Date(item.uploadedAt).toLocaleDateString()}</p>
                          </div>
                        </div>
                        <div className="flex items-center space-x-2">
                          <a
                            href={item.fileUrl}
                            target="_blank"
                            rel="noreferrer"
                            className="rounded-lg bg-accentBlue/20 px-2.5 py-1 text-xs font-semibold text-accentCyan border border-accentBlue/40 hover:bg-accentBlue/30"
                          >
                            Open ↗
                          </a>
                          <button
                            disabled={deletingId === item.id}
                            onClick={() => handleDelete("notes", item.id)}
                            className="rounded-lg bg-red-500/20 px-2.5 py-1 text-xs font-semibold text-red-300 border border-red-500/30 hover:bg-red-500/30"
                          >
                            Delete
                          </button>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              ))
            )}
          </div>
        )}

        {/* Folder Structure View Mode: Campus Placements */}
        {viewMode === "folders" && activeTab === "placements" && (
          <div className="space-y-4">
            {filteredJobs.filter(j => j.type === "PLACEMENT").length === 0 ? (
              <div className="py-12 text-center text-white/40">
                <p className="text-3xl mb-2">📂</p>
                <p className="text-sm font-semibold">No uploaded Campus Placement Drive folders found.</p>
              </div>
            ) : (
              Object.entries(
                filteredJobs.filter(j => j.type === "PLACEMENT").reduce((acc: any, job) => {
                  const folderKey = `🏢 Campus Placement Drive Folder: ${job.company} (${job.stipend || "CTC Available"})`;
                  (acc[folderKey] ||= []).push(job);
                  return acc;
                }, {})
              ).map(([folderName, jobsList]: [string, any]) => (
                <div key={folderName} className="rounded-xl border border-white/10 bg-white/[0.02] overflow-hidden backdrop-blur-md">
                  <div className="flex items-center justify-between border-b border-white/10 bg-purple-500/10 px-4 py-3">
                    <div className="flex items-center space-x-3">
                      <span className="text-xl">📁</span>
                      <div>
                        <h3 className="text-sm font-bold text-white">{folderName}</h3>
                        <p className="text-[10px] text-purple-300">{jobsList.length} Placement Drive{jobsList.length > 1 ? "s" : ""}</p>
                      </div>
                    </div>
                  </div>
                  <div className="divide-y divide-white/5 p-2">
                    {jobsList.map((item: any) => (
                      <div key={item.id} className="flex items-center justify-between p-3 rounded-lg hover:bg-white/5 transition-colors">
                        <div className="flex items-center space-x-3">
                          <span className="text-base">🏢</span>
                          <div>
                            <p className="text-xs font-bold text-white">{item.title}</p>
                            <p className="text-[10px] text-white/50">{item.company} • {item.branch} • CTC Package: {item.stipend || "TBD"}</p>
                          </div>
                        </div>
                        <div className="flex items-center space-x-2">
                          {item.applyUrl && (
                            <a
                              href={item.applyUrl}
                              target="_blank"
                              rel="noreferrer"
                              className="rounded-lg bg-purple-500/20 px-2.5 py-1 text-xs font-semibold text-purple-300 border border-purple-500/40 hover:bg-purple-500/30"
                            >
                              Drive Portal ↗
                            </a>
                          )}
                          <button
                            disabled={deletingId === item.id}
                            onClick={() => handleDelete("jobs", item.id)}
                            className="rounded-lg bg-red-500/20 px-2.5 py-1 text-xs font-semibold text-red-300 border border-red-500/30 hover:bg-red-500/30"
                          >
                            Delete
                          </button>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              ))
            )}
          </div>
        )}

        {/* Folder Structure View Mode: Govt Jobs */}
        {viewMode === "folders" && activeTab === "govtJobs" && (
          <div className="space-y-4">
            {filteredJobs.filter(j => j.type === "GOVT_JOB").length === 0 ? (
              <div className="py-12 text-center text-white/40">
                <p className="text-3xl mb-2">📂</p>
                <p className="text-sm font-semibold">No uploaded Govt Job Notification folders found.</p>
              </div>
            ) : (
              Object.entries(
                filteredJobs.filter(j => j.type === "GOVT_JOB").reduce((acc: any, job) => {
                  const folderKey = `🏛️ Govt Recruitment Folder: ${job.company} — ${job.title}`;
                  (acc[folderKey] ||= []).push(job);
                  return acc;
                }, {})
              ).map(([folderName, jobsList]: [string, any]) => (
                <div key={folderName} className="rounded-xl border border-white/10 bg-white/[0.02] overflow-hidden backdrop-blur-md">
                  <div className="flex items-center justify-between border-b border-white/10 bg-emerald-500/10 px-4 py-3">
                    <div className="flex items-center space-x-3">
                      <span className="text-xl">📁</span>
                      <div>
                        <h3 className="text-sm font-bold text-white">{folderName}</h3>
                        <p className="text-[10px] text-emerald-300">{jobsList.length} Official Notification{jobsList.length > 1 ? "s" : ""}</p>
                      </div>
                    </div>
                  </div>
                  <div className="divide-y divide-white/5 p-2">
                    {jobsList.map((item: any) => (
                      <div key={item.id} className="flex items-center justify-between p-3 rounded-lg hover:bg-white/5 transition-colors">
                        <div className="flex items-center space-x-3">
                          <span className="text-base">🏛️</span>
                          <div>
                            <p className="text-xs font-bold text-white">{item.title}</p>
                            <p className="text-[10px] text-white/50">{item.company} • Stream: {item.branch} • Pay Matrix: {item.stipend || "Govt Pay Level"}</p>
                          </div>
                        </div>
                        <div className="flex items-center space-x-2">
                          {item.applyUrl && (
                            <a
                              href={item.applyUrl}
                              target="_blank"
                              rel="noreferrer"
                              className="rounded-lg bg-emerald-500/20 px-2.5 py-1 text-xs font-semibold text-emerald-300 border border-emerald-500/40 hover:bg-emerald-500/30"
                            >
                              Govt Portal ↗
                            </a>
                          )}
                          <button
                            disabled={deletingId === item.id}
                            onClick={() => handleDelete("jobs", item.id)}
                            className="rounded-lg bg-red-500/20 px-2.5 py-1 text-xs font-semibold text-red-300 border border-red-500/30 hover:bg-red-500/30"
                          >
                            Delete
                          </button>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              ))
            )}
          </div>
        )}

        {/* Folder Structure View Mode: Competitive Exams */}
        {viewMode === "folders" && activeTab === "exams" && (
          <div className="space-y-4">
            {filteredExams.length === 0 ? (
              <div className="py-12 text-center text-white/40">
                <p className="text-3xl mb-2">📂</p>
                <p className="text-sm font-semibold">No Competitive Exam folders found.</p>
              </div>
            ) : (
              filteredExams.map((exam) => (
                <div key={exam.id} className="rounded-xl border border-white/10 bg-white/[0.02] overflow-hidden backdrop-blur-md">
                  <div className="flex items-center justify-between border-b border-white/10 bg-amber-500/10 px-4 py-3">
                    <div className="flex items-center space-x-3">
                      <span className="text-xl">📁</span>
                      <div>
                        <h3 className="text-sm font-bold text-white">🎓 Competitive Exam Folder: {exam.name} ({exam.cat})</h3>
                        <p className="text-[10px] text-amber-300">{(exam.videos?.length || 0) + (exam.pdfNotes?.length || 0)} Learning Asset{(exam.videos?.length || 0) + (exam.pdfNotes?.length || 0) !== 1 ? "s" : ""}</p>
                      </div>
                    </div>
                  </div>
                  <div className="divide-y divide-white/5 p-2">
                    {(exam.videos ?? []).map((vid) => (
                      <div key={vid.id} className="flex items-center justify-between p-3 rounded-lg hover:bg-white/5 transition-colors">
                        <div className="flex items-center space-x-3">
                          <span className="text-base">🎬</span>
                          <div>
                            <p className="text-xs font-bold text-white">{vid.title}</p>
                            <p className="text-[10px] text-white/50">Subject: {vid.subject || "General"} • Video Lecture</p>
                          </div>
                        </div>
                        <div className="flex items-center space-x-2">
                          {vid.s3Url && (
                            <a
                              href={vid.s3Url}
                              target="_blank"
                              rel="noreferrer"
                              className="rounded-lg bg-amber-500/20 px-2.5 py-1 text-xs font-semibold text-amber-300 border border-amber-500/40 hover:bg-amber-500/30"
                            >
                              Watch Video ↗
                            </a>
                          )}
                          <button
                            disabled={deletingId === vid.id}
                            onClick={() => handleDelete("exams", vid.id)}
                            className="rounded-lg bg-red-500/20 px-2.5 py-1 text-xs font-semibold text-red-300 border border-red-500/30 hover:bg-red-500/30"
                          >
                            Delete
                          </button>
                        </div>
                      </div>
                    ))}
                    {(exam.pdfNotes ?? []).map((pdf) => (
                      <div key={pdf.id} className="flex items-center justify-between p-3 rounded-lg hover:bg-white/5 transition-colors">
                        <div className="flex items-center space-x-3">
                          <span className="text-base">📄</span>
                          <div>
                            <p className="text-xs font-bold text-white">{pdf.title}</p>
                            <p className="text-[10px] text-white/50">Subject: {pdf.subject || "General"} • PDF Study Material</p>
                          </div>
                        </div>
                        <div className="flex items-center space-x-2">
                          {pdf.fileUrl && (
                            <a
                              href={pdf.fileUrl}
                              target="_blank"
                              rel="noreferrer"
                              className="rounded-lg bg-accentBlue/20 px-2.5 py-1 text-xs font-semibold text-accentCyan border border-accentBlue/40 hover:bg-accentBlue/30"
                            >
                              Open PDF ↗
                            </a>
                          )}
                          <button
                            disabled={deletingId === pdf.id}
                            onClick={() => handleDelete("exams", pdf.id)}
                            className="rounded-lg bg-red-500/20 px-2.5 py-1 text-xs font-semibold text-red-300 border border-red-500/30 hover:bg-red-500/30"
                          >
                            Delete
                          </button>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              ))
            )}
          </div>
        )}

        {/* Tab 1: Academic Materials List (Table View) */}
        {viewMode === "table" && activeTab === "notes" && (
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
                  <th className="px-4 py-3 text-right">Actions</th>
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
                        {item.subject?.name ?? "General"}
                      </td>
                      <td className="px-4 py-3">{item.subject?.branch ?? "GEN"} — Sem {item.subject?.semester ?? 1}</td>
                      <td className="px-4 py-3 font-semibold text-white/90">Unit {item.unit ?? 1}</td>
                      <td className="px-4 py-3 font-medium text-accentCyan">{formatCategory(item.contentType)}</td>
                      <td className="px-4 py-3 text-white/50">
                        {new Date(item.uploadedAt).toLocaleDateString()}
                      </td>
                      <td className="px-4 py-3 text-right space-x-2">
                        <a
                          href={item.fileUrl}
                          target="_blank"
                          rel="noreferrer"
                          className="inline-flex items-center rounded-lg bg-accentBlue/20 px-2.5 py-1 text-xs font-semibold text-accentCyan hover:bg-accentBlue/30 border border-accentBlue/40"
                        >
                          View ↗
                        </a>
                        <button
                          onClick={() => setEditingItem({ id: item.id, type: "notes", title: item.title })}
                          className="rounded-lg bg-amber-500/20 px-2.5 py-1 text-xs font-semibold text-amber-300 hover:bg-amber-500/30 border border-amber-500/30"
                        >
                          Edit
                        </button>
                        <button
                          disabled={deletingId === item.id}
                          onClick={() => handleDelete("notes", item.id)}
                          className="rounded-lg bg-red-500/20 px-2.5 py-1 text-xs font-semibold text-red-300 hover:bg-red-500/30 border border-red-500/30 disabled:opacity-50"
                        >
                          Delete
                        </button>
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan={7} className="px-4 py-8 text-center text-white/40">
                      No academic materials found.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        )}

        {/* Tab 2: Campus Placements & Govt Jobs */}
        {(activeTab === "placements" || activeTab === "govtJobs") && (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="border-b border-white/10 bg-white/[0.02] text-white/50 uppercase">
                <tr>
                  <th className="px-4 py-3">Position Title</th>
                  <th className="px-4 py-3">Company / Org</th>
                  <th className="px-4 py-3">Category</th>
                  <th className="px-4 py-3">Target Branch</th>
                  <th className="px-4 py-3">Attachment File</th>
                  <th className="px-4 py-3">Posted Date</th>
                  <th className="px-4 py-3 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-white/5 text-white/80">
                {filteredJobs.filter(j => {
                  if (activeTab === "placements") return j.type === "PLACEMENT";
                  if (activeTab === "govtJobs") return j.type === "GOVT_JOB";
                  return true;
                }).length > 0 ? (
                  filteredJobs.filter(j => {
                    if (activeTab === "placements") return j.type === "PLACEMENT";
                    if (activeTab === "govtJobs") return j.type === "GOVT_JOB";
                    return true;
                  }).map((job) => (
                    <tr key={job.id} className="hover:bg-white/[0.02]">
                      <td className="px-4 py-3 font-semibold text-white">{job.title}</td>
                      <td className="px-4 py-3 text-accentCyan font-medium">{job.company}</td>
                      <td className="px-4 py-3">
                        <span className="rounded bg-white/10 px-2 py-0.5 font-semibold text-white/80">
                          {job.type}
                        </span>
                      </td>
                      <td className="px-4 py-3">{job.branch ?? "ALL"}</td>
                      <td className="px-4 py-3">
                        {job.fileUrl ? (
                          <a
                            href={job.fileUrl}
                            target="_blank"
                            rel="noreferrer"
                            className="inline-flex items-center rounded-md bg-emerald-500/20 px-2 py-0.5 text-xs font-semibold text-emerald-300 hover:bg-emerald-500/30 border border-emerald-500/30"
                          >
                            📄 Attachment ↗
                          </a>
                        ) : (
                          <span className="text-white/40 italic">None</span>
                        )}
                      </td>
                      <td className="px-4 py-3">
                        {job.applyUrl ? (
                          <a
                            href={job.applyUrl}
                            target="_blank"
                            rel="noreferrer"
                            className="inline-flex items-center rounded-md bg-accentBlue/20 px-2 py-0.5 text-xs font-semibold text-accentCyan hover:bg-accentBlue/30 border border-accentBlue/40 truncate max-w-[140px]"
                          >
                            🔗 Apply Link ↗
                          </a>
                        ) : (
                          <span className="text-white/40 italic">None</span>
                        )}
                      </td>
                      <td className="px-4 py-3 text-white/50">
                        {new Date(job.postedAt).toLocaleDateString()}
                      </td>
                      <td className="px-4 py-3 text-right space-x-2">
                        {job.applyUrl && (
                          <a
                            href={job.applyUrl}
                            target="_blank"
                            rel="noreferrer"
                            className="inline-flex items-center rounded-lg bg-accentBlue/20 px-2.5 py-1 text-xs font-semibold text-accentCyan hover:bg-accentBlue/30 border border-accentBlue/40"
                          >
                            Link ↗
                          </a>
                        )}
                        <button
                          onClick={() => setEditingItem({ id: job.id, type: "jobs", title: job.title, subtitle: job.company })}
                          className="rounded-lg bg-amber-500/20 px-2.5 py-1 text-xs font-semibold text-amber-300 hover:bg-amber-500/30 border border-amber-500/30"
                        >
                          Edit
                        </button>
                        <button
                          disabled={deletingId === job.id}
                          onClick={() => handleDelete("jobs", job.id)}
                          className="rounded-lg bg-red-500/20 px-2.5 py-1 text-xs font-semibold text-red-300 hover:bg-red-500/30 border border-red-500/30 disabled:opacity-50"
                        >
                          Delete
                        </button>
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan={8} className="px-4 py-8 text-center text-white/40">
                      No job listings posted.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        )}

        {/* Tab 3: Competitive Exams Uploaded */}
        {activeTab === "exams" && (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="border-b border-white/10 bg-white/[0.02] text-white/50 uppercase">
                <tr>
                  <th className="px-4 py-3">Exam Name</th>
                  <th className="px-4 py-3">Category</th>
                  <th className="px-4 py-3">Lecture / Material Title</th>
                  <th className="px-4 py-3">Subject</th>
                  <th className="px-4 py-3">Type / Duration</th>
                  <th className="px-4 py-3 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-white/5 text-white/80">
                {filteredExams.length > 0 ? (
                  filteredExams.flatMap((exam) => {
                    const videoRows = (exam.videos ?? []).map((v) => ({
                      id: v.id,
                      examName: exam.name,
                      cat: exam.cat,
                      title: v.title,
                      subject: v.subject ?? "General",
                      type: "🎬 Video Stream",
                      duration: v.duration ?? "20:00",
                      url: v.s3Url ?? v.pdfUrl,
                    }));
                    const pdfRows = (exam.pdfNotes ?? []).map((p) => ({
                      id: p.id,
                      examName: exam.name,
                      cat: exam.cat,
                      title: p.title,
                      subject: p.subject ?? "General",
                      type: "📄 PDF Handout",
                      duration: "PDF Note",
                      url: p.fileUrl,
                    }));
                    return [...videoRows, ...pdfRows];
                  }).map((item) => (
                    <tr key={item.id} className="hover:bg-white/[0.02]">
                      <td className="px-4 py-3 font-semibold text-white">{item.examName}</td>
                      <td className="px-4 py-3 text-accentCyan font-medium">{item.cat}</td>
                      <td className="px-4 py-3 font-semibold text-white/90">{item.title}</td>
                      <td className="px-4 py-3">{item.subject}</td>
                      <td className="px-4 py-3">
                        <span className="rounded bg-white/10 px-2 py-0.5 font-semibold text-white/80">
                          {item.type} ({item.duration})
                        </span>
                      </td>
                      <td className="px-4 py-3 text-right space-x-2">
                        {item.url && (
                          <a
                            href={item.url}
                            target="_blank"
                            rel="noreferrer"
                            className="inline-flex items-center rounded-lg bg-accentBlue/20 px-2.5 py-1 text-xs font-semibold text-accentCyan hover:bg-accentBlue/30 border border-accentBlue/40"
                          >
                            Stream ↗
                          </a>
                        )}
                        <button
                          onClick={() => setEditingItem({ id: item.id, type: "exams", title: item.title })}
                          className="rounded-lg bg-amber-500/20 px-2.5 py-1 text-xs font-semibold text-amber-300 hover:bg-amber-500/30 border border-amber-500/30"
                        >
                          Edit
                        </button>
                        <button
                          disabled={deletingId === item.id}
                          onClick={() => handleDelete("exams", item.id)}
                          className="rounded-lg bg-red-500/20 px-2.5 py-1 text-xs font-semibold text-red-300 hover:bg-red-500/30 border border-red-500/30 disabled:opacity-50"
                        >
                          Delete
                        </button>
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan={6} className="px-4 py-8 text-center text-white/40">
                      No competitive exam materials uploaded.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        )}

        {/* Tab 4: Registered Students */}
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

        {/* Tab 5: Exam Results */}
        {activeTab === "results" && (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="border-b border-white/10 bg-white/[0.02] text-white/50 uppercase">
                <tr>
                  <th className="px-4 py-3">Student Hall Ticket</th>
                  <th className="px-4 py-3">Semester</th>
                  <th className="px-4 py-3">Uploaded Date</th>
                  <th className="px-4 py-3 text-right">Actions</th>
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
                      <td className="px-4 py-3 text-right space-x-2">
                        <a
                          href={res.fileUrl}
                          target="_blank"
                          rel="noreferrer"
                          className="inline-flex items-center rounded-lg bg-accentBlue/20 px-2.5 py-1 text-xs font-semibold text-accentCyan hover:bg-accentBlue/30 border border-accentBlue/40"
                        >
                          View PDF ↗
                        </a>
                        <button
                          disabled={deletingId === res.id}
                          onClick={() => handleDelete("results", res.id)}
                          className="rounded-lg bg-red-500/20 px-2.5 py-1 text-xs font-semibold text-red-300 hover:bg-red-500/30 border border-red-500/30 disabled:opacity-50"
                        >
                          Delete
                        </button>
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan={4} className="px-4 py-8 text-center text-white/40">
                      No exam results uploaded yet.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Edit Modal */}
      {editingItem && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 backdrop-blur-sm p-4">
          <div className="w-full max-w-md rounded-2xl border border-white/10 bg-[#0E1017] p-6 shadow-2xl">
            <h3 className="text-lg font-bold text-white mb-4">Edit Item Details</h3>
            
            <div className="space-y-4">
              <div>
                <label className="block text-xs font-medium text-white/70 mb-1">Title</label>
                <input
                  type="text"
                  value={editingItem.title}
                  onChange={(e) => setEditingItem({ ...editingItem, title: e.target.value })}
                  className="w-full rounded-xl border border-white/10 bg-black/50 px-3.5 py-2 text-sm text-white focus:border-accentCyan focus:outline-none"
                />
              </div>

              {editingItem.type === "jobs" && (
                <div>
                  <label className="block text-xs font-medium text-white/70 mb-1">Company / Organization</label>
                  <input
                    type="text"
                    value={editingItem.subtitle ?? ""}
                    onChange={(e) => setEditingItem({ ...editingItem, subtitle: e.target.value })}
                    className="w-full rounded-xl border border-white/10 bg-black/50 px-3.5 py-2 text-sm text-white focus:border-accentCyan focus:outline-none"
                  />
                </div>
              )}
            </div>

            <div className="mt-6 flex justify-end space-x-3">
              <button
                onClick={() => setEditingItem(null)}
                className="rounded-xl border border-white/10 px-4 py-2 text-xs font-semibold text-white/70 hover:bg-white/5"
              >
                Cancel
              </button>
              <button
                onClick={handleSaveEdit}
                className="rounded-xl bg-accentBlue px-4 py-2 text-xs font-semibold text-white hover:bg-accentBlue/80"
              >
                Save Changes
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
