"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { apiRequest, setStoredToken, setStoredUser, User } from "../../lib/api-client";

export default function LoginPage() {
  const [hallTicket, setHallTicket] = useState("21A91A0501");
  const [password, setPassword] = useState("21A91A0501");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const router = useRouter();

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      const res = await apiRequest<{ accessToken: string; user: User }>("/auth/login", {
        method: "POST",
        body: JSON.stringify({ hallTicket, password }),
      });

      setStoredToken(res.accessToken);
      setStoredUser(res.user);

      if (res.user.role === "ADMIN" || res.user.role === "SUPER_ADMIN") {
        window.location.href = "http://localhost:3001/admin/notes";
      } else {
        router.push("/academic-hub");
      }
    } catch (err: any) {
      setError(err.message || "Failed to log in. Please check credentials.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <main className="mx-auto flex max-w-md flex-col justify-center px-6 py-16">
      <div className="rounded-3xl border border-white/10 bg-white/[0.03] p-8 shadow-2xl backdrop-blur-xl">
        <div className="mb-6 text-center">
          <h1 className="text-2xl font-bold">Welcome Back</h1>
          <p className="mt-1 text-sm text-white/50">Log in to access your MyVault portal</p>
        </div>

        {error && (
          <div className="mb-6 rounded-xl border border-red-500/30 bg-red-500/10 p-3 text-center text-xs text-red-400">
            {error}
          </div>
        )}

        <form onSubmit={handleLogin} className="space-y-4">
          <div>
            <label className="mb-1 block text-xs font-medium text-white/70">Hall Ticket Number / Username</label>
            <input
              type="text"
              required
              value={hallTicket}
              onChange={(e) => setHallTicket(e.target.value)}
              placeholder="e.g. 21A91A0501"
              className="w-full rounded-xl border border-white/15 bg-white/5 px-4 py-2.5 text-sm text-white placeholder-white/30 focus:border-accentCyan focus:outline-none"
            />
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
            {loading ? "Signing In..." : "Sign In"}
          </button>
        </form>

        <div className="mt-6 border-t border-white/10 pt-4 text-center text-xs text-white/50">
          <p>
            Demo logins: Student (<button onClick={() => { setHallTicket("21A91A0501"); setPassword("21A91A0501"); }} className="text-accentCyan underline">21A91A0501</button>) • Admin (<button onClick={() => { setHallTicket("ADMIN001"); setPassword("admin123"); }} className="text-accentCyan underline">ADMIN001</button>)
          </p>
          <p className="mt-3">
            Don&apos;t have an account?{" "}
            <Link href="/register" className="font-semibold text-accentCyan hover:underline">
              Register Here
            </Link>
          </p>
        </div>
      </div>
    </main>
  );
}
