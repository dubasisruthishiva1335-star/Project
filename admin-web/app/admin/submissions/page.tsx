"use client";

import Link from "next/link";

export default function AdminSubmissionsReviewPage() {
  return (
    <div className="mx-auto max-w-2xl px-4 py-16 text-center">
      <h1 className="text-xl font-bold text-white mb-2">Job & Internship Management</h1>
      <p className="text-sm text-white/60 mb-6">
        All internship listings, placement drives, and government job postings are managed directly under the main dashboard and upload form.
      </p>
      <Link
        href="/admin/internships"
        className="inline-flex items-center rounded-xl bg-blue-600 px-5 py-2.5 text-sm font-semibold text-white hover:bg-blue-500 transition shadow-lg shadow-blue-600/30"
      >
        ← Return to Job & Internship Postings
      </Link>
    </div>
  );
}
