"use client";

import { useEffect, useState, useMemo } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { apiRequest, ApiError } from "../lib/api-client";
import { getPersistedUploads, savePersistedUpload, removePersistedUpload } from "../lib/uploads-store";

export interface UnifiedUploadItem {
  id: string;
  hubType: "NOTE" | "COMPETITIVE_EXAM" | "COURSE" | "INTERNSHIP";
  hubLabel: string;
  title: string;
  subtitle: string;
  category: string;
  formatOrType: string;
  fileUrl?: string;
  externalUrl?: string;
  fileSize?: string;
  authorOrCompany?: string;
  uploadedAt: string;
  badgeColor: string;
  extraMeta?: string;
  rawItem?: any;
}

interface StudentItem {
  id: string;
  hallTicket: string;
  fullName: string;
  branch: string;
  semester: number;
  createdAt: string;
}

export default function DashboardPage() {
  const router = useRouter();
  const [isLoading, setIsLoading] = useState(true);
  const [allItems, setAllItems] = useState<UnifiedUploadItem[]>([]);
  const [students, setStudents] = useState<StudentItem[]>([]);
  const [searchQuery, setSearchQuery] = useState("");
  const [activeTab, setActiveTab] = useState<"ALL" | "NOTE" | "COMPETITIVE_EXAM" | "COURSE" | "INTERNSHIP" | "STUDENTS">("ALL");
  const [viewMode, setViewMode] = useState<"cards" | "table">("cards");
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const fetchAllData = async () => {
    setIsLoading(true);
    setError(null);

    try {
      const [notesRes, subjectsRes, recentRes, examsRes, coursesRes, internshipsRes] = await Promise.all([
        apiRequest<any[]>("/admin/notes").catch(() => []),
        apiRequest<any[]>("/subjects").catch(() => []),
        apiRequest<any>("/admin/analytics/recent-uploads").catch(() => ({ recentNotes: [], allStudents: [] })),
        fetch("/api/admin/competitive-exams").then((r) => r.json()).catch(() => ({ exams: [] })),
        fetch("/api/admin/courses").then((r) => r.json()).catch(() => ({ courses: [] })),
        fetch("/api/admin/internships").then((r) => r.json()).catch(() => ({ internships: [] })),
      ]);

      const items: UnifiedUploadItem[] = [];

      // 1. Process Academic Notes
      const combinedNotesMap = new Map<string, any>();
      (subjectsRes || []).forEach((s: any) => {
        (s.contents || []).forEach((c: any) => {
          if (c && c.id) {
            combinedNotesMap.set(c.id, {
              ...c,
              subjectName: s.name,
              branch: s.branch || "ENGG",
              semester: s.semester || 1,
            });
          }
        });
      });

      (notesRes || []).forEach((n: any) => {
        if (n && n.id) {
          combinedNotesMap.set(n.id, {
            ...n,
            subjectName: n.title,
            branch: n.branch || "ENGG",
            semester: n.semester || 1,
          });
        }
      });

      (recentRes?.recentNotes || []).forEach((n: any) => {
        if (n && n.id && !combinedNotesMap.has(n.id)) {
          combinedNotesMap.set(n.id, n);
        }
      });

      combinedNotesMap.forEach((n) => {
        items.push({
          id: n.id,
          hubType: "NOTE",
          hubLabel: "Academic Study Material",
          title: n.title || "Academic Material",
          subtitle: n.subjectName ? `Subject: ${n.subjectName}` : `${n.branch || "Core"} • Sem ${n.semester || 1}`,
          category: n.branch || "Engineering",
          formatOrType: n.contentType || n.content_type || "PDF Note",
          fileUrl: n.fileUrl || n.file_url,
          uploadedAt: n.uploadedAt || n.uploaded_at || new Date().toISOString(),
          badgeColor: "bg-cyan-500/20 text-accentCyan border-cyan-500/30",
          extraMeta: `Unit ${n.unit || 1} • Sem ${n.semester || 1}`,
          rawItem: n,
        });
      });

      // 2. Process Competitive Exams
      const examsList: any[] = Array.isArray(examsRes) ? examsRes : (examsRes?.exams || []);
      examsList.forEach((e: any) => {
        items.push({
          id: e.id,
          hubType: "COMPETITIVE_EXAM",
          hubLabel: "Competitive Exam & PYQ",
          title: e.title || e.examName || e.exam_name,
          subtitle: `${e.examName || e.exam_name || "Exam Prep"} • Topic: ${e.subject || "Full Syllabus"}`,
          category: e.category || "ENGINEERING",
          formatOrType: (e.contentType || e.content_type || "PYQ_PAPER").replace("_", " "),
          fileUrl: e.fileUrl || e.file_url,
          externalUrl: e.syllabusUrl || e.syllabus_url,
          fileSize: e.fileSize || e.file_size || "PDF",
          authorOrCompany: e.author || "Faculty Team",
          uploadedAt: e.uploadedAt || e.uploaded_at || new Date().toISOString(),
          badgeColor: "bg-purple-500/20 text-purple-300 border-purple-500/30",
          extraMeta: `Target: ${e.year || 2026} • Exam Date: ${e.examDate || e.exam_date || "Scheduled"}`,
          rawItem: e,
        });
      });

      // 3. Process Video Courses
      const coursesList: any[] = Array.isArray(coursesRes) ? coursesRes : (coursesRes?.courses || []);
      coursesList.forEach((c: any) => {
        items.push({
          id: c.id,
          hubType: "COURSE",
          hubLabel: "Video Course & Quizzes",
          title: c.title,
          subtitle: `${c.modulesCount || 4} Modules • ${c.lessonsCount || 20} Video Lessons • ${c.quizzesCount || 5} AI Quizzes`,
          category: c.category || "Development",
          formatOrType: `Level: ${c.level || "All Levels"}`,
          fileUrl: c.thumbnail,
          authorOrCompany: c.instructor || "MyVault Academy",
          uploadedAt: c.postedAt || c.posted_at || new Date().toISOString(),
          badgeColor: "bg-emerald-500/20 text-emerald-300 border-emerald-500/30",
          extraMeta: `Passing Score: ${c.passingScore || 70}% • 24h Certificate Seal`,
          rawItem: c,
        });
      });

      // 4. Process Internships
      const internshipsList: any[] = Array.isArray(internshipsRes) ? internshipsRes : (internshipsRes?.internships || []);
      internshipsList.forEach((i: any) => {
        items.push({
          id: i.id,
          hubType: "INTERNSHIP",
          hubLabel: "Career & Internship",
          title: i.title,
          subtitle: `${i.company} • ${i.location || "Remote"} (${i.workMode || i.work_mode || "Hybrid"})`,
          category: i.category || "Engineering",
          formatOrType: i.stipend || "Paid Internship",
          externalUrl: i.applyUrl || i.apply_url || i.companyWebsite || i.company_website,
          authorOrCompany: i.company,
          uploadedAt: i.postedAt || i.posted_at || new Date().toISOString(),
          badgeColor: "bg-blue-500/20 text-blue-300 border-blue-500/30",
          extraMeta: `${i.openings || i.max_students || 1} Openings • Min CGPA: ${i.minCgpa || 7.0}`,
          rawItem: i,
        });
      });

      // Merge with locally persisted uploads for resilient permanent offline/online retention
      const persisted = getPersistedUploads();
      const existingIds = new Set(items.map(i => i.id));
      persisted.forEach(p => {
        if (!existingIds.has(p.id)) {
          items.push(p);
        }
      });

      // Sort newest first
      items.sort((a, b) => new Date(b.uploadedAt).getTime() - new Date(a.uploadedAt).getTime());

      // Persist all active items to local permanent storage
      items.forEach(item => savePersistedUpload(item));

      setAllItems(items);
      setStudents(recentRes?.allStudents || []);
    } catch (err) {
      if (err instanceof ApiError && err.status === 401) {
        localStorage.removeItem("myvault_admin_token");
        router.push("/login");
      } else {
        const persisted = getPersistedUploads();
        if (persisted.length > 0) {
          setAllItems(persisted);
        }
        setError("Network sync active. Showing permanently stored records.");
      }
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchAllData();
  }, []);

  const handleDeleteItem = async (item: UnifiedUploadItem) => {
    if (!confirm(`Are you sure you want to delete "${item.title}"?\n\nThis will permanently remove it from the Admin Portal and Mobile App.`)) {
      return;
    }

    setDeletingId(item.id);
    try {
      // 1. Remove from local permanent cache immediately
      removePersistedUpload(item.id);

      // 2. Remove from backend & Vercel API
      if (item.hubType === "NOTE") {
        await apiRequest(`/admin/notes/${item.id}`, { method: "DELETE" }).catch(() => {});
        await fetch(`/api/admin/notes?id=${item.id}`, { method: "DELETE" }).catch(() => {});
      } else if (item.hubType === "COMPETITIVE_EXAM") {
        await fetch(`/api/admin/competitive-exams?id=${item.id}`, { method: "DELETE" }).catch(() => {});
        await apiRequest(`/admin/exams/${item.id}`, { method: "DELETE" }).catch(() => {});
      } else if (item.hubType === "COURSE") {
        await fetch(`/api/admin/courses?id=${item.id}`, { method: "DELETE" }).catch(() => {});
      } else if (item.hubType === "INTERNSHIP") {
        await fetch(`/api/admin/internships?id=${item.id}`, { method: "DELETE" }).catch(() => {});
        await apiRequest(`/admin/internships/${item.id}`, { method: "DELETE" }).catch(() => {});
      }

      // Refresh list
      setAllItems((prev) => prev.filter((i) => i.id !== item.id));
    } catch (err) {
      alert("Failed to delete item: " + (err instanceof Error ? err.message : "Unknown error"));
    } finally {
      setDeletingId(null);
    }
  };

  // Metrics
  const metrics = useMemo(() => {
    const notesCount = allItems.filter((i) => i.hubType === "NOTE").length;
    const examsCount = allItems.filter((i) => i.hubType === "COMPETITIVE_EXAM").length;
    const coursesCount = allItems.filter((i) => i.hubType === "COURSE").length;
    const internshipsCount = allItems.filter((i) => i.hubType === "INTERNSHIP").length;
    const totalUploads = allItems.length;
    const studentsCount = students.length;

    return { totalUploads, notesCount, examsCount, coursesCount, internshipsCount, studentsCount };
  }, [allItems, students]);

  // Filtering
  const filteredItems = useMemo(() => {
    return allItems.filter((item) => {
      const matchesTab = activeTab === "ALL" || item.hubType === activeTab;
      const query = searchQuery.toLowerCase();
      const matchesSearch =
        !query ||
        item.title.toLowerCase().includes(query) ||
        item.subtitle.toLowerCase().includes(query) ||
        item.category.toLowerCase().includes(query) ||
        (item.authorOrCompany && item.authorOrCompany.toLowerCase().includes(query)) ||
        item.formatOrType.toLowerCase().includes(query);

      return matchesTab && matchesSearch;
    });
  }, [allItems, activeTab, searchQuery]);

  const filteredStudents = useMemo(() => {
    const query = searchQuery.toLowerCase();
    return students.filter(
      (s) =>
        !query ||
        s.fullName.toLowerCase().includes(query) ||
        s.hallTicket.toLowerCase().includes(query) ||
        s.branch.toLowerCase().includes(query)
    );
  }, [students, searchQuery]);

  return (
    <div className="mx-auto max-w-7xl px-4 py-8 sm:px-6">
      {/* Header Banner */}
      <div className="mb-8 flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
        <div>
          <div className="flex items-center gap-3">
            <span className="flex h-10 w-10 items-center justify-center rounded-xl bg-accentBlue/20 text-xl border border-accentBlue/30">
              📊
            </span>
            <div>
              <h1 className="bg-gradient-to-r from-accentBlue via-accentCyan to-white bg-clip-text text-2xl font-black tracking-tight text-transparent sm:text-3xl">
                Admin Control Center & Master Upload Hub
              </h1>
              <p className="text-xs text-white/60 sm:text-sm">
                Real-time dashboard displaying all uploaded files, notes, exams, courses, and opportunities across MyVault.
              </p>
            </div>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="flex flex-wrap items-center gap-2">
          <button
            onClick={fetchAllData}
            disabled={isLoading}
            className="flex items-center gap-1.5 rounded-xl border border-white/10 bg-white/5 px-3 py-2 text-xs font-semibold text-white/80 transition hover:bg-white/10 hover:text-white"
          >
            <span className={isLoading ? "animate-spin" : ""}>🔄</span> Refresh
          </button>
          <Link
            href="/admin/publish/study-materials"
            className="flex items-center gap-1.5 rounded-xl border border-cyan-500/30 bg-cyan-500/10 px-3.5 py-2 text-xs font-semibold text-accentCyan transition hover:bg-cyan-500/20"
          >
            ➕ Upload Notes
          </Link>
          <Link
            href="/admin/competitive-exams"
            className="flex items-center gap-1.5 rounded-xl border border-purple-500/30 bg-purple-500/10 px-3.5 py-2 text-xs font-semibold text-purple-300 transition hover:bg-purple-500/20"
          >
            🎯 Upload Exam PYQ
          </Link>
          <Link
            href="/admin/courses"
            className="flex items-center gap-1.5 rounded-xl border border-emerald-500/30 bg-emerald-500/10 px-3.5 py-2 text-xs font-semibold text-emerald-300 transition hover:bg-emerald-500/20"
          >
            🎓 Create Course
          </Link>
          <Link
            href="/admin/internships"
            className="flex items-center gap-1.5 rounded-xl border border-blue-500/30 bg-blue-500/10 px-3.5 py-2 text-xs font-semibold text-blue-300 transition hover:bg-blue-500/20"
          >
            💼 Post Internship
          </Link>
        </div>
      </div>

      {/* Metric Cards */}
      <div className="mb-8 grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-6">
        <div
          onClick={() => setActiveTab("ALL")}
          className={`cursor-pointer rounded-2xl border p-4 transition-all ${
            activeTab === "ALL"
              ? "border-accentCyan bg-accentCyan/10 shadow-lg shadow-cyan-500/10"
              : "border-white/10 bg-white/[0.02] hover:border-white/20 hover:bg-white/[0.04]"
          }`}
        >
          <div className="flex items-center justify-between">
            <span className="text-xl">📁</span>
            <span className="rounded-md bg-white/10 px-1.5 py-0.5 text-[10px] font-bold text-white/70">ALL</span>
          </div>
          <p className="mt-2 text-2xl font-black text-white">{metrics.totalUploads}</p>
          <p className="text-[11px] font-medium text-white/50">Total Uploaded Items</p>
        </div>

        <div
          onClick={() => setActiveTab("NOTE")}
          className={`cursor-pointer rounded-2xl border p-4 transition-all ${
            activeTab === "NOTE"
              ? "border-cyan-500 bg-cyan-500/10 shadow-lg shadow-cyan-500/10"
              : "border-white/10 bg-white/[0.02] hover:border-white/20 hover:bg-white/[0.04]"
          }`}
        >
          <div className="flex items-center justify-between">
            <span className="text-xl">📚</span>
            <span className="rounded-md bg-cyan-500/20 px-1.5 py-0.5 text-[10px] font-bold text-accentCyan">NOTES</span>
          </div>
          <p className="mt-2 text-2xl font-black text-white">{metrics.notesCount}</p>
          <p className="text-[11px] font-medium text-white/50">Study Notes & PDFs</p>
        </div>

        <div
          onClick={() => setActiveTab("COMPETITIVE_EXAM")}
          className={`cursor-pointer rounded-2xl border p-4 transition-all ${
            activeTab === "COMPETITIVE_EXAM"
              ? "border-purple-500 bg-purple-500/10 shadow-lg shadow-purple-500/10"
              : "border-white/10 bg-white/[0.02] hover:border-white/20 hover:bg-white/[0.04]"
          }`}
        >
          <div className="flex items-center justify-between">
            <span className="text-xl">🎯</span>
            <span className="rounded-md bg-purple-500/20 px-1.5 py-0.5 text-[10px] font-bold text-purple-300">EXAMS</span>
          </div>
          <p className="mt-2 text-2xl font-black text-white">{metrics.examsCount}</p>
          <p className="text-[11px] font-medium text-white/50">Exam Papers & PYQs</p>
        </div>

        <div
          onClick={() => setActiveTab("COURSE")}
          className={`cursor-pointer rounded-2xl border p-4 transition-all ${
            activeTab === "COURSE"
              ? "border-emerald-500 bg-emerald-500/10 shadow-lg shadow-emerald-500/10"
              : "border-white/10 bg-white/[0.02] hover:border-white/20 hover:bg-white/[0.04]"
          }`}
        >
          <div className="flex items-center justify-between">
            <span className="text-xl">🎓</span>
            <span className="rounded-md bg-emerald-500/20 px-1.5 py-0.5 text-[10px] font-bold text-emerald-300">LMS</span>
          </div>
          <p className="mt-2 text-2xl font-black text-white">{metrics.coursesCount}</p>
          <p className="text-[11px] font-medium text-white/50">Video Courses</p>
        </div>

        <div
          onClick={() => setActiveTab("INTERNSHIP")}
          className={`cursor-pointer rounded-2xl border p-4 transition-all ${
            activeTab === "INTERNSHIP"
              ? "border-blue-500 bg-blue-500/10 shadow-lg shadow-blue-500/10"
              : "border-white/10 bg-white/[0.02] hover:border-white/20 hover:bg-white/[0.04]"
          }`}
        >
          <div className="flex items-center justify-between">
            <span className="text-xl">💼</span>
            <span className="rounded-md bg-blue-500/20 px-1.5 py-0.5 text-[10px] font-bold text-blue-300">CAREER</span>
          </div>
          <p className="mt-2 text-2xl font-black text-white">{metrics.internshipsCount}</p>
          <p className="text-[11px] font-medium text-white/50">Internship Postings</p>
        </div>

        <div
          onClick={() => setActiveTab("STUDENTS")}
          className={`cursor-pointer rounded-2xl border p-4 transition-all ${
            activeTab === "STUDENTS"
              ? "border-amber-500 bg-amber-500/10 shadow-lg shadow-amber-500/10"
              : "border-white/10 bg-white/[0.02] hover:border-white/20 hover:bg-white/[0.04]"
          }`}
        >
          <div className="flex items-center justify-between">
            <span className="text-xl">👤</span>
            <span className="rounded-md bg-amber-500/20 px-1.5 py-0.5 text-[10px] font-bold text-amber-300">USERS</span>
          </div>
          <p className="mt-2 text-2xl font-black text-white">{metrics.studentsCount}</p>
          <p className="text-[11px] font-medium text-white/50">Registered Students</p>
        </div>
      </div>

      {/* Search & Navigation Bar */}
      <div className="mb-6 flex flex-col gap-4 rounded-2xl border border-white/10 bg-white/[0.02] p-4 sm:flex-row sm:items-center sm:justify-between">
        {/* Tab Filters */}
        <div className="flex flex-wrap items-center gap-1.5 overflow-x-auto pb-1 sm:pb-0">
          <button
            onClick={() => setActiveTab("ALL")}
            className={`rounded-xl px-3 py-1.5 text-xs font-semibold transition ${
              activeTab === "ALL" ? "bg-accentBlue text-white" : "text-white/60 hover:bg-white/5 hover:text-white"
            }`}
          >
            🌟 All Contents ({allItems.length})
          </button>
          <button
            onClick={() => setActiveTab("NOTE")}
            className={`rounded-xl px-3 py-1.5 text-xs font-semibold transition ${
              activeTab === "NOTE" ? "bg-cyan-500 text-black font-bold" : "text-white/60 hover:bg-white/5 hover:text-white"
            }`}
          >
            📚 Study Notes ({metrics.notesCount})
          </button>
          <button
            onClick={() => setActiveTab("COMPETITIVE_EXAM")}
            className={`rounded-xl px-3 py-1.5 text-xs font-semibold transition ${
              activeTab === "COMPETITIVE_EXAM" ? "bg-purple-600 text-white" : "text-white/60 hover:bg-white/5 hover:text-white"
            }`}
          >
            🎯 Competitive Exams ({metrics.examsCount})
          </button>
          <button
            onClick={() => setActiveTab("COURSE")}
            className={`rounded-xl px-3 py-1.5 text-xs font-semibold transition ${
              activeTab === "COURSE" ? "bg-emerald-600 text-white" : "text-white/60 hover:bg-white/5 hover:text-white"
            }`}
          >
            🎓 Video Courses ({metrics.coursesCount})
          </button>
          <button
            onClick={() => setActiveTab("INTERNSHIP")}
            className={`rounded-xl px-3 py-1.5 text-xs font-semibold transition ${
              activeTab === "INTERNSHIP" ? "bg-blue-600 text-white" : "text-white/60 hover:bg-white/5 hover:text-white"
            }`}
          >
            💼 Internships ({metrics.internshipsCount})
          </button>
          <button
            onClick={() => setActiveTab("STUDENTS")}
            className={`rounded-xl px-3 py-1.5 text-xs font-semibold transition ${
              activeTab === "STUDENTS" ? "bg-amber-600 text-white" : "text-white/60 hover:bg-white/5 hover:text-white"
            }`}
          >
            👤 Students ({metrics.studentsCount})
          </button>
        </div>

        {/* Search Input & View Mode */}
        <div className="flex items-center gap-2">
          <div className="relative w-full sm:w-64">
            <span className="absolute left-3 top-2.5 text-xs text-white/40">🔍</span>
            <input
              type="text"
              placeholder="Search all uploaded assets..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full rounded-xl border border-white/10 bg-white/5 py-1.5 pl-8 pr-3 text-xs text-white placeholder-white/30 focus:border-accentCyan focus:outline-none"
            />
          </div>

          <div className="flex rounded-xl border border-white/10 bg-white/5 p-0.5">
            <button
              onClick={() => setViewMode("cards")}
              className={`rounded-lg px-2.5 py-1 text-xs transition ${
                viewMode === "cards" ? "bg-white/20 text-white" : "text-white/40 hover:text-white"
              }`}
              title="Card Grid View"
            >
              ⊞ Grid
            </button>
            <button
              onClick={() => setViewMode("table")}
              className={`rounded-lg px-2.5 py-1 text-xs transition ${
                viewMode === "table" ? "bg-white/20 text-white" : "text-white/40 hover:text-white"
              }`}
              title="Table View"
            >
              ≡ Table
            </button>
          </div>
        </div>
      </div>

      {/* Main Content Area */}
      {isLoading ? (
        <div className="flex flex-col items-center justify-center rounded-3xl border border-white/10 bg-white/[0.01] py-24">
          <div className="h-10 w-10 animate-spin rounded-full border-2 border-accentCyan border-t-transparent"></div>
          <p className="mt-4 text-sm text-white/60">Scanning and aggregating uploaded files & content...</p>
        </div>
      ) : activeTab === "STUDENTS" ? (
        /* Students Table */
        <div className="overflow-hidden rounded-2xl border border-white/10 bg-white/[0.02]">
          <div className="border-b border-white/10 p-4">
            <h2 className="text-sm font-bold text-white">Registered Students Database ({filteredStudents.length})</h2>
          </div>
          {filteredStudents.length === 0 ? (
            <div className="p-8 text-center text-xs text-white/40">No student records found.</div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="border-b border-white/10 bg-white/5 text-[11px] font-semibold text-white/60">
                  <tr>
                    <th className="p-3">Student Name</th>
                    <th className="p-3">Hall Ticket / Roll No</th>
                    <th className="p-3">Branch</th>
                    <th className="p-3">Semester</th>
                    <th className="p-3">Registered Date</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-white/5">
                  {filteredStudents.map((s) => (
                    <tr key={s.id} className="hover:bg-white/[0.02]">
                      <td className="p-3 font-medium text-white">{s.fullName}</td>
                      <td className="p-3 font-mono text-accentCyan">{s.hallTicket}</td>
                      <td className="p-3 text-white/70">{s.branch}</td>
                      <td className="p-3 text-white/70">Sem {s.semester}</td>
                      <td className="p-3 text-white/40">{new Date(s.createdAt).toLocaleDateString()}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      ) : filteredItems.length === 0 ? (
        <div className="flex flex-col items-center justify-center rounded-3xl border border-white/10 bg-white/[0.01] py-20 text-center">
          <span className="text-4xl">📂</span>
          <p className="mt-3 text-base font-semibold text-white">No uploaded contents match your search</p>
          <p className="mt-1 text-xs text-white/40">Try adjusting your filters or search query, or upload new files using the top buttons.</p>
        </div>
      ) : viewMode === "cards" ? (
        /* Card Grid View */
        <div className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3">
          {filteredItems.map((item) => (
            <div
              key={item.id}
              className="flex flex-col justify-between rounded-2xl border border-white/10 bg-white/[0.02] p-5 backdrop-blur-sm transition hover:border-white/20 hover:bg-white/[0.04]"
            >
              <div>
                {/* Hub Badge & Actions */}
                <div className="flex items-center justify-between gap-2">
                  <span className={`inline-flex items-center gap-1 rounded-lg border px-2.5 py-1 text-[11px] font-bold ${item.badgeColor}`}>
                    {item.hubType === "NOTE" && "📚"}
                    {item.hubType === "COMPETITIVE_EXAM" && "🎯"}
                    {item.hubType === "COURSE" && "🎓"}
                    {item.hubType === "INTERNSHIP" && "💼"}
                    {item.hubLabel}
                  </span>
                  <div className="flex items-center gap-1">
                    <span className="rounded bg-white/5 px-2 py-0.5 text-[10px] font-mono text-white/40">
                      {item.formatOrType}
                    </span>
                    <button
                      onClick={() => handleDeleteItem(item)}
                      disabled={deletingId === item.id}
                      className="rounded p-1 text-white/30 transition hover:bg-red-500/20 hover:text-red-400"
                      title="Permanently Delete Item"
                    >
                      {deletingId === item.id ? "⏳" : "🗑️"}
                    </button>
                  </div>
                </div>

                {/* Title & Subtitle */}
                <h3 className="mt-3 line-clamp-2 text-sm font-bold text-white group-hover:text-accentCyan">
                  {item.title}
                </h3>
                <p className="mt-1 line-clamp-2 text-xs text-white/60">{item.subtitle}</p>

                {/* Extra Metadata */}
                {item.extraMeta && (
                  <p className="mt-2 text-[11px] font-medium text-white/40">
                    ℹ️ {item.extraMeta}
                  </p>
                )}
              </div>

              {/* Bottom Footer & Links */}
              <div className="mt-4 border-t border-white/5 pt-3">
                <div className="flex items-center justify-between text-[11px] text-white/40">
                  <span>📅 {new Date(item.uploadedAt).toLocaleDateString()}</span>
                  {item.fileSize && <span>📦 {item.fileSize}</span>}
                </div>

                <div className="mt-2.5 flex items-center gap-2">
                  {item.fileUrl && (
                    <a
                      href={item.fileUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="flex-1 rounded-lg border border-accentCyan/30 bg-accentCyan/10 py-1.5 text-center text-xs font-bold text-accentCyan transition hover:bg-accentCyan/20"
                    >
                      👁️ Open File ↗
                    </a>
                  )}
                  {item.externalUrl && (
                    <a
                      href={item.externalUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="flex-1 rounded-lg border border-white/10 bg-white/5 py-1.5 text-center text-xs font-semibold text-white/80 transition hover:bg-white/10 hover:text-white"
                    >
                      🔗 Link ↗
                    </a>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      ) : (
        /* Table View */
        <div className="overflow-hidden rounded-2xl border border-white/10 bg-white/[0.02]">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="border-b border-white/10 bg-white/5 text-[11px] font-semibold text-white/60">
                <tr>
                  <th className="p-3">Category</th>
                  <th className="p-3">Title & Information</th>
                  <th className="p-3">Format / Type</th>
                  <th className="p-3">Author / Credit</th>
                  <th className="p-3">Uploaded Date</th>
                  <th className="p-3 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-white/5">
                {filteredItems.map((item) => (
                  <tr key={item.id} className="hover:bg-white/[0.02]">
                    <td className="p-3">
                      <span className={`inline-flex rounded-md border px-2 py-0.5 text-[10px] font-bold ${item.badgeColor}`}>
                        {item.hubType === "NOTE" && "📚 Notes"}
                        {item.hubType === "COMPETITIVE_EXAM" && "🎯 Exam"}
                        {item.hubType === "COURSE" && "🎓 Course"}
                        {item.hubType === "INTERNSHIP" && "💼 Job"}
                      </span>
                    </td>
                    <td className="p-3">
                      <div className="font-semibold text-white">{item.title}</div>
                      <div className="text-[11px] text-white/50">{item.subtitle}</div>
                    </td>
                    <td className="p-3 font-mono text-white/70">{item.formatOrType}</td>
                    <td className="p-3 text-white/60">{item.authorOrCompany || "MyVault Team"}</td>
                    <td className="p-3 text-white/40">{new Date(item.uploadedAt).toLocaleDateString()}</td>
                    <td className="p-3 text-right">
                      <div className="flex items-center justify-end gap-2">
                        {item.fileUrl && (
                          <a
                            href={item.fileUrl}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="rounded bg-accentCyan/10 px-2 py-1 text-[11px] font-bold text-accentCyan hover:bg-accentCyan/20"
                          >
                            👁️ View
                          </a>
                        )}
                        {item.externalUrl && (
                          <a
                            href={item.externalUrl}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="rounded bg-white/10 px-2 py-1 text-[11px] font-semibold text-white/80 hover:bg-white/20"
                          >
                            🔗 Link
                          </a>
                        )}
                        <button
                          onClick={() => handleDeleteItem(item)}
                          disabled={deletingId === item.id}
                          className="rounded p-1 text-white/30 hover:bg-red-500/20 hover:text-red-400"
                          title="Delete"
                        >
                          🗑️
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}
