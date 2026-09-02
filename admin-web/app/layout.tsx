"use client";

import "./globals.css";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";

export default function RootLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const isLoginPage = pathname === "/login";

  const handleLogout = () => {
    if (typeof window !== "undefined") {
      localStorage.removeItem("myvault_admin_token");
      router.push("/login");
    }
  };

  return (
    <html lang="en">
      <body className="min-h-screen bg-obsidian text-white antialiased">
        {isLoginPage ? (
          <main className="min-h-screen">{children}</main>
        ) : (
          <div className="mx-auto flex min-h-screen max-w-6xl">
            <aside className="hidden w-56 shrink-0 flex-col justify-between border-r border-white/10 p-6 sm:flex">
              <div>
                <Link href="/" className="mb-8 block bg-gradient-to-r from-accentBlue to-accentCyan bg-clip-text text-lg font-bold text-transparent">
                  MyVault Admin
                </Link>
                <nav className="space-y-1 text-sm text-white/60">
                  <Link href="/" className={`block rounded-lg px-3 py-2 transition-colors ${pathname === "/" ? "bg-white/10 text-accentCyan font-medium" : "hover:bg-white/5 hover:text-white"}`}>📊 Dashboard</Link>
                  <Link href="/admin/publish" className={`block rounded-lg px-3 py-2 transition-colors ${pathname === "/admin/publish" ? "bg-accentCyan/20 text-accentCyan font-bold border border-accentCyan/40" : "hover:bg-white/5 hover:text-white"}`}>📁 Publish Folders Grid ↗</Link>
                  <Link href="/admin/publish/jobs" className={`block rounded-lg px-3 py-2 transition-colors ${pathname.includes("/jobs") && !pathname.includes("govt") ? "bg-white/10 text-accentCyan font-medium" : "hover:bg-white/5 hover:text-white"}`}>💼 Job Listings</Link>
                  <Link href="/admin/publish/internships" className={`block rounded-lg px-3 py-2 transition-colors ${pathname.includes("/internships") ? "bg-white/10 text-accentCyan font-medium" : "hover:bg-white/5 hover:text-white"}`}>🎓 Internships & LMS</Link>
                  <Link href="/admin/publish/placements" className={`block rounded-lg px-3 py-2 transition-colors ${pathname.includes("/placements") ? "bg-white/10 text-accentCyan font-medium" : "hover:bg-white/5 hover:text-white"}`}>🏢 Campus Placements</Link>
                  <Link href="/admin/publish/govt-jobs" className={`block rounded-lg px-3 py-2 transition-colors ${pathname.includes("/govt-jobs") ? "bg-white/10 text-accentCyan font-medium" : "hover:bg-white/5 hover:text-white"}`}>🏛️ Govt Jobs Hub</Link>
                  <Link href="/admin/publish/study-materials" className={`block rounded-lg px-3 py-2 transition-colors ${pathname.includes("/study-materials") || pathname.includes("/notes") ? "bg-white/10 text-accentCyan font-medium" : "hover:bg-white/5 hover:text-white"}`}>📚 Study Materials</Link>
                  <Link href="/admin/publish/courses" className={`block rounded-lg px-3 py-2 transition-colors ${pathname.includes("/courses") || pathname.includes("/exams") ? "bg-white/10 text-accentCyan font-medium" : "hover:bg-white/5 hover:text-white"}`}>🎓 Courses & Exam Prep</Link>
                  <Link href="/admin/publish/notices" className={`block rounded-lg px-3 py-2 transition-colors ${pathname.includes("/notices") ? "bg-white/10 text-accentCyan font-medium" : "hover:bg-white/5 hover:text-white"}`}>📢 Notices & Circulars</Link>
                  <Link href="/admin/results" className={`block rounded-lg px-3 py-2 transition-colors ${pathname === "/admin/results" ? "bg-white/10 text-accentCyan font-medium" : "hover:bg-white/5 hover:text-white"}`}>📊 Exam Results</Link>
                </nav>
              </div>

              <div className="border-t border-white/10 pt-4">
                <button
                  onClick={handleLogout}
                  className="w-full rounded-lg border border-white/15 px-3 py-2 text-left text-xs font-semibold text-white/70 hover:bg-white/10 hover:text-white"
                >
                  🚪 Sign Out
                </button>
              </div>
            </aside>
            <main className="flex-1">{children}</main>
          </div>
        )}
      </body>
    </html>
  );
}
