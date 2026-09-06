"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { apiRequest, ApiError } from "../lib/api-client";

interface Overview {
  students: number;
  notes: number;
}

interface NoteItem {
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
}

interface StudentItem {
  id: string;
  hallTicket: string;
  fullName: string;
  branch: string;
  semester: number;
  createdAt: string;
}

interface RecentUploads {
  recentNotes: NoteItem[];
  allStudents: StudentItem[];
}

export default function DashboardPage() {
  const router = useRouter();
  const [data, setData] = useState<Overview | null>(null);
  const [recent, setRecent] = useState<RecentUploads | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState<"notes" | "students">("notes");
  const [searchQuery, setSearchQuery] = useState("");
  const [editingItem, setEditingItem] = useState<{ id: string; title: string } | null>(null);
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const [viewMode, setViewMode] = useState<"folders" | "table">("folders");

  const refreshData = () => {
    setError(null);
    Promise.all([
      apiRequest<Overview>("/admin/analytics/overview").catch(() => ({ students: 0, notes: 0 })),
      apiRequest<RecentUploads>("/admin/analytics/recent-uploads").catch(() => ({ recentNotes: [], allStudents: [] })),
      apiRequest<any[]>("/admin/notes").catch(() => []),
      apiRequest<any[]>("/subjects").catch(() => []),
    ])
      .then(([overviewData, recentData, notesData, subjectsData]) => {
        const subjectsNotes: NoteItem[] = (subjectsData || []).flatMap((s: any) =>
          (s.contents || []).map((c: any) => ({
            id: c.id,
            title: c.title || s.name,
            contentType: c.contentType || "NOTES",
            unit: c.unit || 1,
            fileUrl: c.fileUrl,
            uploadedAt: c.uploadedAt || new Date().toISOString(),
            subject: {
              name: s.name,
              code: s.code || s.branch || "GEN",
              branch: s.branch || "GEN",
              semester: s.semester || 1,
            },
          }))
        );

        const rawNotes = (notesData || []).map((n: any) => ({
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

        const combinedNotesMap = new Map<string, NoteItem>();
        [...subjectsNotes, ...rawNotes, ...(recentData.recentNotes || [])].forEach((item) => {
          if (item && item.id) {
            combinedNotesMap.set(item.id, item);
          }
        });

        const notesList = Array.from(combinedNotesMap.values());

        setData({
          students: overviewData.students || (recentData.allStudents?.length ?? 0),
          notes: notesList.length,
        });

        setRecent({
          recentNotes: notesList,
          allStudents: recentData.allStudents || [],
        });
      })
      .catch((err) => {
        if (err instanceof ApiError && err.status === 401) {
          localStorage.removeItem("myvault_admin_token");
          router.push("/login");
        } else {
          setRecent((prev) => prev ?? { recentNotes: [], allStudents: [] });
        }
      });
  };

  useEffect(() => {
    refreshData();
  }, [router]);

  const handleDelete = async (id: string) => {
    if (!confirm("Are you sure you want to delete this study material? It will be removed immediately.")) {
      return;
    }
    setDeletingId(id);
    try {
      await apiRequest(`/admin/notes/${id}`, { method: "DELETE" });
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
      await apiRequest(`/admin/notes/${editingItem.id}`, {
        method: "PATCH",
        body: JSON.stringify({ title: editingItem.title }),
      });
      setEditingItem(null);
      refreshData();
    } catch (err) {
      alert("Failed to update item: " + (err instanceof Error ? err.message : "Unknown error"));
    }
  };

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

  const filteredStudents = (recent?.allStudents ?? []).filter((s) =>
    s.fullName.toLowerCase().includes(searchQuery.toLowerCase()) ||
    s.hallTicket.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const cards: Array<{
    id: "notes" | "students";
    label: string;
    value: number | undefined;
    icon: string;
    color: string;
  }> = [
    { id: "notes", label: "Academic Notes & Study Materials", value: recent?.recentNotes?.length ?? data?.notes, icon: "📚", color: "from-cyan-500/20 to-teal-500/20" },
    { id: "students", label: "Students Registered", value: recent?.allStudents?.length ?? data?.students, icon: "👤", color: "from-indigo-500/20 to-cyan-500/20" },
  ];

  return (
    <div className="mx-auto max-w-7xl px-6 py-10">
      <div className="mb-8 flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="bg-gradient-to-r from-accentBlue to-accentCyan bg-clip-text text-2xl font-extrabold text-transparent">
            Admin Control Center
          </h1>
          <p className="mt-1 text-sm text-white/50">
            Manage Academic Study Materials, Lecture Notes, and Registered Students.
          </p>
        </div>

        <Link
          href="/admin/publish/study-materials"
          className="inline-flex items-center gap-2 rounded-xl bg-accentCyan px-4 py-2 text-xs font-bold text-black hover:bg-cyan-300 transition shadow-lg shadow-cyan-500/20"
        >
          <span>➕</span> Publish Study Material
        </Link>
      </div>

      {error && (
        <p className="mb-6 rounded-lg border border-red-400/30 bg-red-400/10 px-3 py-2 text-sm text-red-300">
          {error}
        </p>
      )}

      {/* Analytics Grid */}
      <div className="mb-10 grid grid-cols-1 gap-4 sm:grid-cols-2">
        {cards.map((c) => {
          const isSelected = activeTab === c.id;
          return (
            <button
              key={c.id}
              onClick={() => setActiveTab(c.id)}
              className={`text-left transition-all duration-200 rounded-2xl border p-5 backdrop-blur-xl ${
                isSelected
                  ? "border-accentCyan bg-accentBlue/20 shadow-lg shadow-accentCyan/10 scale-[1.01]"
                  : "border-white/10 bg-gradient-to-br " + c.color + " hover:border-white/20"
              }`}
            >
              <div className="flex items-center justify-between">
                <span className="text-3xl">{c.icon}</span>
                <p className="text-3xl font-black text-accentCyan">{c.value ?? "—"}</p>
              </div>
              <p className="mt-3 text-sm font-bold text-white/90">{c.label}</p>
              <p className="mt-0.5 text-xs text-accentCyan font-medium">Click to manage ↓</p>
            </button>
          );
        })}
      </div>

      {/* Itemized Management Table */}
      <div className="rounded-2xl border border-white/10 bg-white/[0.02] p-6 backdrop-blur-xl">
        {/* Tab Header & Search / View Toggle */}
        <div className="mb-6 flex flex-wrap items-center justify-between gap-4">
          <div>
            <h2 className="text-lg font-bold text-white flex items-center gap-2">
              <span>
                {activeTab === "notes" && "📚 Academic Materials & Study Folders"}
                {activeTab === "students" && "👤 Registered Students Directory"}
              </span>
            </h2>
            <p className="text-xs text-white/50">
              {activeTab === "notes"
                ? "Organized into folders by Branch, Semester, Subject, and Category — syncs to Website and Mobile App"
                : "Active registered student profiles on the platform"}
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-3">
            {activeTab === "notes" && (
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
            )}

            <input
              type="text"
              placeholder="Search uploaded items..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="rounded-xl border border-white/10 bg-black/50 px-3.5 py-1.5 text-xs text-white placeholder-white/40 focus:border-accentCyan focus:outline-none"
            />
          </div>
        </div>

        {/* Tab 1: Folder View for Academic Notes */}
        {activeTab === "notes" && viewMode === "folders" && (
          <div className="space-y-4">
            {filteredNotes.length === 0 ? (
              <div className="py-12 text-center text-white/40">
                <p className="text-3xl mb-2">📂</p>
                <p className="text-sm font-semibold">No uploaded folders or study materials found.</p>
              </div>
            ) : (
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
                    {notesList.map((item: NoteItem) => (
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
                            onClick={() => handleDelete(item.id)}
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

        {/* Tab 1: Table View for Academic Notes */}
        {activeTab === "notes" && viewMode === "table" && (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="border-b border-white/10 bg-white/[0.02] text-white/50 uppercase">
                <tr>
                  <th className="px-4 py-3">Resource Title</th>
                  <th className="px-4 py-3">Subject / Course</th>
                  <th className="px-4 py-3">Branch & Sem</th>
                  <th className="px-4 py-3">Unit</th>
                  <th className="px-4 py-3">Type</th>
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
                      <td className="px-4 py-3 text-white/50">{new Date(item.uploadedAt).toLocaleDateString()}</td>
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
                          onClick={() => setEditingItem({ id: item.id, title: item.title })}
                          className="rounded-lg bg-amber-500/20 px-2.5 py-1 text-xs font-semibold text-amber-300 hover:bg-amber-500/30 border border-amber-500/30"
                        >
                          Edit
                        </button>
                        <button
                          disabled={deletingId === item.id}
                          onClick={() => handleDelete(item.id)}
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

        {/* Tab 2: Registered Students */}
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
                      <td className="px-4 py-3 text-white/50">{new Date(s.createdAt).toLocaleDateString()}</td>
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
      </div>

      {/* Edit Modal */}
      {editingItem && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 backdrop-blur-sm p-4">
          <div className="w-full max-w-md rounded-2xl border border-white/10 bg-[#0E1017] p-6 shadow-2xl">
            <h3 className="text-lg font-bold text-white mb-4">Edit Material Title</h3>
            
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
