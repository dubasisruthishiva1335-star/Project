"use client";

import Link from "next/link";

export default function AdminSubmissionsReviewPage() {
  return (
    <div className="mx-auto max-w-2xl px-4 py-16 text-center">
      <h1 className="text-xl font-bold text-white mb-2">Publishing & Management Hub</h1>
      <p className="text-sm text-white/60 mb-6">
        All campus placement drives, study materials, exam prep, and official circulars are managed directly from the Control Center.
      </p>
      <Link
        href="/admin/publish"
        className="inline-flex items-center rounded-xl bg-accentCyan px-5 py-2.5 text-sm font-semibold text-black hover:bg-cyan-300 transition shadow-lg shadow-cyan-500/20"
      >
        ← Open Publish Folders Grid
      </Link>
    </div>
  );
}
