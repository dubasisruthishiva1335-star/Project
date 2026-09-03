"use client";

import Link from "next/link";

const PUBLISH_FOLDERS = [
  {
    key: "placements",
    icon: "🏢",
    label: "Campus Placement Drives",
    desc: "Post corporate hiring drives with CTC salary packages & eligibility cutoffs",
    color: "from-purple-500/20 to-violet-500/20",
    border: "border-purple-500/30",
    text: "text-purple-300",
    path: "/admin/publish/placements",
  },
  {
    key: "govtjobs",
    icon: "🏛️",
    label: "Govt Jobs",
    desc: "Post government job notifications (banking, railways, defence, UPSC, etc.)",
    color: "from-amber-500/20 to-yellow-500/20",
    border: "border-amber-500/30",
    text: "text-amber-300",
    path: "/admin/publish/govt-jobs",
  },
  {
    key: "study",
    icon: "📚",
    label: "Study Materials",
    desc: "Upload notes, PDFs, and reference material by branch and semester",
    color: "from-emerald-500/20 to-teal-500/20",
    border: "border-emerald-500/30",
    text: "text-emerald-300",
    path: "/admin/publish/study-materials",
  },
  {
    key: "courses",
    icon: "🎓",
    label: "Courses & Exam Prep",
    desc: "Publish structured courses with video modules, lessons, and exam prep",
    color: "from-cyan-500/20 to-blue-500/20",
    border: "border-cyan-500/30",
    text: "text-cyan-300",
    path: "/admin/publish/courses",
  },
  {
    key: "notices",
    icon: "📢",
    label: "Notices & Circulars",
    desc: "Post general announcements, circular PDFs, and priority alerts",
    color: "from-rose-500/20 to-pink-500/20",
    border: "border-rose-500/30",
    text: "text-rose-300",
    path: "/admin/publish/notices",
  },
];

export default function PublishHome() {
  return (
    <div className="mx-auto max-w-5xl px-4 py-10">
      <div className="mb-8">
        <h1 className="bg-gradient-to-r from-accentBlue to-accentCyan bg-clip-text text-2xl font-black text-transparent">
          📁 Publish Content — Choose Folder
        </h1>
        <p className="mt-1 text-sm text-white/50">
          Choose an individual folder to publish into. Each folder routes strictly to its matching hub in the Mobile App.
        </p>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
        {PUBLISH_FOLDERS.map((f) => (
          <Link
            key={f.key}
            href={f.path}
            className={`group block rounded-2xl border ${f.border} bg-gradient-to-br ${f.color} p-6 backdrop-blur-xl transition-all duration-200 hover:scale-[1.02] hover:border-white/30 hover:shadow-xl`}
          >
            <div className="flex items-center gap-3 mb-3">
              <span className="text-3xl">{f.icon}</span>
              <span className="text-xl opacity-80">📁</span>
            </div>
            <h3 className="text-base font-extrabold text-white mb-1.5 group-hover:text-accentCyan transition-colors">
              {f.label}
            </h3>
            <p className="text-xs text-white/60 leading-relaxed mb-4">{f.desc}</p>

            <div className="flex items-center text-xs font-bold text-accentCyan group-hover:translate-x-1 transition-transform">
              Open Folder & Publish ↗
            </div>
          </Link>
        ))}
      </div>
    </div>
  );
}
