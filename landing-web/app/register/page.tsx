"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { apiRequest, setStoredToken, setStoredUser, User } from "../../lib/api-client";

const BRANCHES = ["ECE", "CSE", "AI_ML", "EEE", "MECH", "CIVIL", "GENERAL"];

export default function RegisterPage() {
  const [fullName, setFullName] = useState("");
  const [hallTicket, setHallTicket] = useState("");
  const [email, setEmail] = useState("");
  const [courseType, setCourseType] = useState("btech");
  const [branch, setBranch] = useState("CSE");
  const [year, setYear] = useState(2);
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const router = useRouter();

  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      const res = await apiRequest<{ accessToken: string; user: User }>("/auth/register", {
        method: "POST",
        body: JSON.stringify({
          fullName,
          hallTicket,
          email: email || undefined,
          courseType,
          branch,
          semester: Number(year),
          password,
        }),
      });

      setStoredToken(res.accessToken);
      setStoredUser(res.user);
      router.push("/academic-hub");
    } catch (err: any) {
      setError(err.message || "Registration failed. Please check your details.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <main className="mx-auto flex max-w-lg flex-col justify-center px-6 py-12">
      <div className="rounded-3xl border border-white/10 bg-white/[0.03] p-8 shadow-2xl backdrop-blur-xl">
        <div className="mb-6 text-center">
          <h1 className="text-2xl font-bold">Create Student Account</h1>
          <p className="mt-1 text-sm text-white/50">Register in seconds — no approval required</p>
        </div>

        {error && (
          <div className="mb-6 rounded-xl border border-red-500/30 bg-red-500/10 p-3 text-center text-xs text-red-400">
            {error}
          </div>
        )}

        <form onSubmit={handleRegister} className="space-y-4">
          <div>
            <label className="mb-1 block text-xs font-medium text-white/70">Full Name</label>
            <input
              type="text"
              required
              value={fullName}
              onChange={(e) => setFullName(e.target.value)}
              placeholder="e.g. Reddy Sai Kumar"
              className="w-full rounded-xl border border-white/15 bg-white/5 px-4 py-2.5 text-sm text-white placeholder-white/30 focus:border-accentCyan focus:outline-none"
            />
          </div>

          <div className="grid gap-4 sm:grid-cols-2">
            <div>
              <label className="mb-1 block text-xs font-medium text-white/70">Hall Ticket Number</label>
              <input
                type="text"
                required
                value={hallTicket}
                onChange={(e) => setHallTicket(e.target.value)}
                placeholder="21A91A0501"
                className="w-full rounded-xl border border-white/15 bg-white/5 px-4 py-2.5 text-sm text-white placeholder-white/30 focus:border-accentCyan focus:outline-none"
              />
            </div>
            <div>
              <label className="mb-1 block text-xs font-medium text-white/70">Email (Optional)</label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="student@example.com"
                className="w-full rounded-xl border border-white/15 bg-white/5 px-4 py-2.5 text-sm text-white placeholder-white/30 focus:border-accentCyan focus:outline-none"
              />
            </div>
          </div>

          <div className="grid gap-4 sm:grid-cols-3">
            <div>
              <label className="mb-1 block text-xs font-medium text-white/70">Course</label>
              <select
                value={courseType}
                onChange={(e) => setCourseType(e.target.value)}
                className="w-full rounded-xl border border-white/15 bg-obsidian px-3 py-2.5 text-sm text-white focus:border-accentCyan focus:outline-none"
              >
                <option value="btech">B.Tech</option>
                <option value="degree">Degree</option>
              </select>
            </div>
            <div>
              <label className="mb-1 block text-xs font-medium text-white/70">Branch</label>
              <select
                value={branch}
                onChange={(e) => setBranch(e.target.value)}
                className="w-full rounded-xl border border-white/15 bg-obsidian px-3 py-2.5 text-sm text-white focus:border-accentCyan focus:outline-none"
              >
                {BRANCHES.map((b) => (
                  <option key={b} value={b}>{b}</option>
                ))}
              </select>
            </div>
            <div>
              <label className="mb-1 block text-xs font-medium text-white/70">Year</label>
              <select
                value={year}
                onChange={(e) => setYear(Number(e.target.value))}
                className="w-full rounded-xl border border-white/15 bg-obsidian px-3 py-2.5 text-sm text-white focus:border-accentCyan focus:outline-none"
              >
                {[1, 2, 3, 4].map((y) => (
                  <option key={y} value={y}>Year {y}</option>
                ))}
              </select>
            </div>
          </div>

          <div>
            <label className="mb-1 block text-xs font-medium text-white/70">Password</label>
            <input
              type="password"
              required
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
              className="w-full rounded-xl border border-white/15 bg-white/5 px-4 py-2.5 text-sm text-white placeholder-white/30 focus:border-accentCyan focus:outline-none"
            />
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full rounded-xl bg-gradient-to-r from-accentBlue to-accentCyan py-3 text-sm font-bold text-black shadow-lg shadow-accentBlue/20 transition-all hover:opacity-90 disabled:opacity-50"
          >
            {loading ? "Creating Account..." : "Register"}
          </button>
        </form>

        <div className="mt-6 border-t border-white/10 pt-4 text-center text-xs text-white/50">
          Already have an account?{" "}
          <Link href="/login" className="font-semibold text-accentCyan hover:underline">
            Log In
          </Link>
        </div>
      </div>
    </main>
  );
}
