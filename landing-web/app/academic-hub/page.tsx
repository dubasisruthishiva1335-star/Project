"use client";

import { useEffect, useState } from "react";
import { apiRequest } from "../../lib/api-client";

const BRANCHES = ["CSE", "ECE", "AI_ML", "EEE", "MECH", "CIVIL", "GENERAL"];

interface SubjectContent {
  id: string;
  title: string;
  contentType: "NOTES" | "QUESTION_BANK" | "SYLLABUS" | "LAB_MANUAL";
  fileUrl: string;
  uploadedAt: string;
}

interface Subject {
  id: string;
  name: string;
  code: string;
  branch: string;
  semester: number;
  contents: SubjectContent[];
}

export default function AcademicHubPage() {
  const [branch, setBranch] = useState("CSE");
  const [year, setYear] = useState(2);
  const [subjects, setSubjects] = useState<Subject[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchSubjects = async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await apiRequest<Subject[]>(
        `/subjects?branch=${branch}&year=${year}`
      );
      setSubjects(res);
    } catch (err: any) {
      setError(err.message || "Failed to load subjects");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchSubjects();
  }, [branch, year]);

  return (
    <main className="mx-auto max-w-5xl px-6 py-10">
      <div className="mb-8 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-3xl font-bold">Academic Hub</h1>
          <p className="mt-1 text-sm text-white/50">
            Browse branch & year-wise notes, syllabus, question banks & lab manuals
          </p>
        </div>

        {/* Filter Bar */}
        <div className="flex items-center gap-3 rounded-2xl border border-white/10 bg-white/[0.03] p-2.5 backdrop-blur-xl">
          <div>
            <label className="mr-2 text-xs text-white/60 font-medium">Branch:</label>
            <select
              value={branch}
              onChange={(e) => setBranch(e.target.value)}
              className="rounded-lg border border-white/15 bg-obsidian px-3 py-1.5 text-xs text-white focus:border-accentCyan focus:outline-none"
            >
              {BRANCHES.map((b) => (
                <option key={b} value={b}>
                  {b}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="mr-2 text-xs text-white/60 font-medium">Year:</label>
            <select
              value={year}
              onChange={(e) => setYear(Number(e.target.value))}
              className="rounded-lg border border-white/15 bg-obsidian px-3 py-1.5 text-xs text-white focus:border-accentCyan focus:outline-none"
            >
              {[1, 2, 3, 4].map((y) => (
                <option key={y} value={y}>
                  Year {y}
                </option>
              ))}
            </select>
          </div>
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
      ) : subjects.length === 0 ? (
        <div className="rounded-3xl border border-dashed border-white/15 p-12 text-center text-white/40">
          <p className="text-lg font-medium">No subjects found</p>
          <p className="mt-1 text-xs">
            No active content for {branch} Year {year} yet.
          </p>
        </div>
      ) : (
        <div className="grid gap-6 sm:grid-cols-2">
          {subjects.map((subject) => (
            <div
              key={subject.id}
              className="flex flex-col justify-between rounded-2xl border border-white/10 bg-white/[0.03] p-6 shadow-xl backdrop-blur-xl transition-all hover:border-white/20"
            >
              <div>
                <div className="flex items-center justify-between">
                  <span className="rounded-md bg-accentCyan/10 px-2.5 py-1 text-xs font-bold text-accentCyan">
                    {subject.code}
                  </span>
                  <span className="text-xs text-white/40">
                    Year {year} • {subject.branch}
                  </span>
                </div>

                <h3 className="mt-3 text-xl font-bold text-white">
                  {subject.name}
                </h3>

                {/* Content badges / files */}
                <div className="mt-4 space-y-2">
                  {subject.contents && subject.contents.length > 0 ? (
                    subject.contents.map((content) => (
                      <a
                        key={content.id}
                        href={content.fileUrl}
                        target="_blank"
                        rel="noreferrer"
                        className="flex items-center justify-between rounded-xl border border-white/10 bg-white/5 px-3.5 py-2.5 text-xs transition-colors hover:bg-white/10"
                      >
                        <span className="font-medium text-white/90">
                          📄 {content.title}
                        </span>
                        <span className="rounded bg-accentBlue/20 px-2 py-0.5 text-[10px] font-semibold text-accentBlue">
                          {content.contentType}
                        </span>
                      </a>
                    ))
                  ) : (
                    <p className="text-xs text-white/40 italic">
                      No files uploaded for this subject yet.
                    </p>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </main>
  );
}
