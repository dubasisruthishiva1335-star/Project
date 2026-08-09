"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { getStoredUser, clearAuth, User } from "../lib/api-client";

export default function NavHeader() {
  const [user, setUser] = useState<User | null>(null);
  const [mounted, setMounted] = useState(false);
  const pathname = usePathname();
  const router = useRouter();

  useEffect(() => {
    setMounted(true);
    setUser(getStoredUser());
  }, [pathname]);

  const handleLogout = () => {
    clearAuth();
    setUser(null);
    router.push("/login");
  };

  const navItems = [
    { label: "Home", href: "/" },
    { label: "Academic Hub", href: "/academic-hub" },
    { label: "Internships & Jobs", href: "/jobs" },
    { label: "Results", href: "/results" },
    { label: "Aptitude", href: "/aptitude" },
  ];

  return (
    <header className="sticky top-0 z-50 border-b border-white/10 bg-obsidian/80 backdrop-blur-md">
      <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
        {/* Brand */}
        <Link href="/" className="flex items-center gap-2">
          <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-gradient-to-tr from-accentBlue to-accentCyan font-bold text-black shadow-lg shadow-accentBlue/20">
            MV
          </div>
          <span className="bg-gradient-to-r from-white via-white to-accentCyan bg-clip-text text-xl font-extrabold tracking-tight text-transparent">
            MyVault
          </span>
        </Link>

        {/* Navigation Links */}
        <nav className="hidden items-center gap-1 md:flex">
          {navItems.map((item) => {
            const isActive = pathname === item.href;
            return (
              <Link
                key={item.href}
                href={item.href}
                className={`rounded-lg px-3.5 py-1.5 text-sm font-medium transition-all ${
                  isActive
                    ? "bg-white/10 text-accentCyan shadow-sm"
                    : "text-white/70 hover:bg-white/5 hover:text-white"
                }`}
              >
                {item.label}
              </Link>
            );
          })}
        </nav>

        {/* Actions / Auth */}
        <div className="flex items-center gap-3">
          <Link
            href="/myvault-app.apk"
            className="hidden rounded-lg border border-accentCyan/30 bg-accentCyan/10 px-3.5 py-1.5 text-xs font-semibold text-accentCyan hover:bg-accentCyan/20 sm:inline-block"
          >
            📲 APK Download
          </Link>

          {mounted && user ? (
            <div className="flex items-center gap-3">
              <div className="hidden text-right text-xs sm:block">
                <p className="font-semibold text-white">{user.fullName}</p>
                <p className="text-white/50">{user.branch} • Year {user.semester}</p>
              </div>
              <button
                onClick={handleLogout}
                className="rounded-lg border border-white/15 px-3 py-1.5 text-xs font-medium text-white/80 hover:bg-white/10 hover:text-white"
              >
                Logout
              </button>
            </div>
          ) : (
            <div className="flex items-center gap-2">
              <Link
                href="/login"
                className="rounded-lg px-3 py-1.5 text-xs font-semibold text-white/80 hover:bg-white/10 hover:text-white"
              >
                Log In
              </Link>
              <Link
                href="/register"
                className="rounded-lg bg-gradient-to-r from-accentBlue to-accentCyan px-3.5 py-1.5 text-xs font-semibold text-black shadow-md shadow-accentBlue/20 hover:opacity-90"
              >
                Register
              </Link>
            </div>
          )}
        </div>
      </div>

      {/* Mobile nav bar */}
      <div className="flex border-t border-white/5 px-4 py-2 overflow-x-auto md:hidden">
        {navItems.map((item) => (
          <Link
            key={item.href}
            href={item.href}
            className={`whitespace-nowrap px-3 py-1 text-xs font-medium ${
              pathname === item.href ? "text-accentCyan" : "text-white/60"
            }`}
          >
            {item.label}
          </Link>
        ))}
      </div>
    </header>
  );
}
