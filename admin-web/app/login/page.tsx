"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { apiRequest, ApiError } from "@/lib/api-client";

interface LoginResponse {
  accessToken: string;
  user: { fullName: string; role: string };
}

export default function LoginPage() {
  const router = useRouter();
  const [hallTicket, setHallTicket] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      const res = await apiRequest<LoginResponse>("/auth/login", {
        method: "POST",
        body: JSON.stringify({ hallTicket, password }),
      });
      if (res.user.role === "STUDENT") {
        setError("This account doesn't have admin access.");
        return;
      }
      window.localStorage.setItem("myvault_admin_token", res.accessToken);
      router.push("/");
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Login failed.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center px-4">
      <form
        onSubmit={handleSubmit}
        className="w-full max-w-sm space-y-5 rounded-2xl border border-white/10 bg-white/[0.03] p-8 backdrop-blur-xl"
      >
        <div>
          <h1 className="bg-gradient-to-r from-accentBlue to-accentCyan bg-clip-text text-xl font-bold text-transparent">
            MyVault Admin
          </h1>
          <p className="mt-1 text-sm text-white/50">Sign in with your admin hall ticket</p>
        </div>

        <div>
          <label className="mb-1.5 block text-sm text-white/80">Hall Ticket</label>
          <input
            value={hallTicket}
            onChange={(e) => setHallTicket(e.target.value)}
            required
            className="w-full rounded-lg border border-white/10 bg-black/40 px-3 py-2 text-sm outline-none focus:border-accentCyan/60"
          />
        </div>
        <div>
          <label className="mb-1.5 block text-sm text-white/80">Password</label>
          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
            className="w-full rounded-lg border border-white/10 bg-black/40 px-3 py-2 text-sm outline-none focus:border-accentCyan/60"
          />
        </div>

        {error && (
          <p className="rounded-lg border border-red-400/30 bg-red-400/10 px-3 py-2 text-sm text-red-300">
            {error}
          </p>
        )}

        <button
          type="submit"
          disabled={loading}
          className="w-full rounded-lg bg-gradient-to-r from-accentBlue to-accentCyan px-4 py-2.5 text-sm font-semibold text-black disabled:opacity-60"
        >
          {loading ? "Signing in…" : "Sign in"}
        </button>
      </form>
    </div>
  );
}
