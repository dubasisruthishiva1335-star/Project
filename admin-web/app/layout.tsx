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
                  <Link href="/admin/publish/study-materials" className={`block rounded-lg px-3 py-2 transition-colors ${pathname.includes("/study-materials") || pathname.includes("/notes") ? "bg-white/10 text-accentCyan font-medium" : "hover:bg-white/5 hover:text-white"}`}>📚 Study Materials</Link>
                  <Link href="/admin/internships" className={`block rounded-lg px-3 py-2 transition-colors ${pathname.includes("/internships") ? "bg-white/10 text-accentCyan font-medium" : "hover:bg-white/5 hover:text-white"}`}>💼 Internship Hub</Link>
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
