"use client";

import { useState } from "react";
import { apiRequest } from "../../lib/api-client";

interface ExamResult {
  id: string;
  hallTicket: string;
  semester: number;
  fileUrl: string;
  uploadedAt: string;
}

export default function ResultsPage() {
  const [hallTicket, setHallTicket] = useState("21A91A0501");
  const [year, setYear] = useState<number | "">("");
  const [results, setResults] = useState<ExamResult[] | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSearch = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!hallTicket.trim()) return;
    setLoading(true);
    setError(null);

    try {
      let query = `?hallTicket=${encodeURIComponent(hallTicket.trim())}`;
      if (year) query += `&year=${year}`;
      const data = await apiRequest<ExamResult[]>(`/results${query}`);
      setResults(data);
    } catch (err: any) {
      setError(err.message || "Could not retrieve results");
    } finally {
      setLoading(false);
    }
  };

  return (
    <main className="mx-auto max-w-4xl px-6 py-12">
      <div className="mb-8 text-center">
        <h1 className="text-3xl font-bold">Exam Results</h1>
        <p className="mt-1 text-sm text-white/50">
          Enter your Hall Ticket number to instantly view published marksheets & memo PDFs
        </p>
      </div>

      {/* Search Card */}
      <div className="mx-auto mb-10 max-w-xl rounded-3xl border border-white/10 bg-white/[0.03] p-6 shadow-2xl backdrop-blur-xl">
        <form onSubmit={handleSearch} className="space-y-4">
          <div>
            <label className="mb-1 block text-xs font-medium text-white/70">
              Hall Ticket Number
            </label>
            <input
              type="text"
              required
              value={hallTicket}
              onChange={(e) => setHallTicket(e.target.value)}
              placeholder="e.g. 21A91A0501"
              className="w-full rounded-xl border border-white/15 bg-white/5 px-4 py-2.5 text-sm text-white uppercase placeholder-white/30 focus:border-accentCyan focus:outline-none"
            />
          </div>

          <div>
            <label className="mb-1 block text-xs font-medium text-white/70">
              Year (Optional)
            </label>
            <select
              value={year}
              onChange={(e) =>
                setYear(e.target.value ? Number(e.target.value) : "")
              }
              className="w-full rounded-xl border border-white/15 bg-obsidian px-4 py-2.5 text-sm text-white focus:border-accentCyan focus:outline-none"
            >
              <option value="">All Years</option>
              {[1, 2, 3, 4].map((y) => (
                <option key={y} value={y}>
                  Year {y}
                </option>
              ))}
            </select>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full rounded-xl bg-gradient-to-r from-accentBlue to-accentCyan py-3 text-sm font-bold text-black shadow-lg shadow-accentBlue/20 transition-all hover:opacity-90 disabled:opacity-50"
          >
            {loading ? "Searching..." : "Search Results"}
          </button>
        </form>
      </div>

      {/* Results Display */}
      {error && (
        <div className="mx-auto max-w-xl rounded-xl border border-amber-500/30 bg-amber-500/10 p-4 text-center text-xs text-amber-300">
          {error}
        </div>
      )}

      {results !== null && (
        <div className="space-y-4">
          <h2 className="text-lg font-semibold text-white/80">
            Results for <span className="text-accentCyan">{hallTicket}</span>
          </h2>

          {results.length === 0 ? (
            <div className="rounded-2xl border border-white/10 bg-white/5 p-8 text-center text-white/40">
              No results found for Hall Ticket {hallTicket}.
            </div>
          ) : (
            <div className="grid gap-4 sm:grid-cols-2">
              {results.map((res) => (
                <div
                  key={res.id}
                  className="flex items-center justify-between rounded-2xl border border-white/10 bg-white/[0.03] p-5 backdrop-blur-xl"
                >
                  <div>
                    <span className="rounded-md bg-accentCyan/10 px-2.5 py-1 text-xs font-bold text-accentCyan">
                      Year {res.semester}
                    </span>
                    <p className="mt-2 text-xs text-white/40">
                      Published {new Date(res.uploadedAt).toLocaleDateString()}
                    </p>
                  </div>

                  <a
                    href={res.fileUrl}
                    target="_blank"
                    rel="noreferrer"
                    className="rounded-xl bg-white/10 px-4 py-2 text-xs font-semibold text-white hover:bg-accentCyan hover:text-black"
                  >
                    View Result PDF 📄
                  </a>
                </div>
              ))}
            </div>
          )}
        </div>
      )}
    </main>
  );
}
