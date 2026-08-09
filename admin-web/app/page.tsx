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

export default function DashboardPage() {
  const router = useRouter();
  const [data, setData] = useState<Overview | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const token = typeof window !== "undefined" ? localStorage.getItem("myvault_admin_token") : null;
    if (!token) {
      router.push("/login");
      return;
    }

    apiRequest<Overview>("/admin/analytics/overview")
      .then(setData)
      .catch((err) => {
        if (err instanceof ApiError && err.status === 401) {
          localStorage.removeItem("myvault_admin_token");
          router.push("/login");
        } else {
          setError(err instanceof ApiError ? err.message : "Failed to load dashboard data.");
        }
      });
  }, [router]);

  const cards: { label: string; value: number | undefined }[] = [
    { label: "Students Registered", value: data?.students },
    { label: "Notes & Academic Materials", value: data?.notes },
    { label: "Job & Internship Listings", value: data?.jobListings },
    { label: "Exam Results Uploaded", value: data?.results },
  ];

  return (
    <div className="px-6 py-10">
      <h1 className="mb-1 text-2xl font-bold">Admin Dashboard</h1>
      <p className="mb-8 text-sm text-white/50">Live analytics and overview from MyVault PostgreSQL database.</p>

      {error && (
        <p className="mb-6 rounded-lg border border-red-400/30 bg-red-400/10 px-3 py-2 text-sm text-red-300">
          {error}
        </p>
      )}

      <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
        {cards.map((c) => (
          <div key={c.label} className="rounded-2xl border border-white/10 bg-white/[0.03] p-5 backdrop-blur-xl">
            <p className="text-3xl font-extrabold text-accentCyan">{c.value ?? "—"}</p>
            <p className="mt-1 text-xs font-medium text-white/60">{c.label}</p>
          </div>
        ))}
      </div>
    </div>
  );
}
