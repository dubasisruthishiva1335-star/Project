"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

export default function NavHeader() {
  const pathname = usePathname();
  const isHomePage = pathname === "/";

  const companyNav = [
    { label: "Services", href: "/#services" },
    { label: "Products", href: "/#products" },
    { label: "CAD & Engineering", href: "/#engineering" },
    { label: "Industries", href: "/#industries" },
    { label: "How We Work", href: "/#process" },
    { label: "Contact", href: "/#contact" },
  ];

  const studentNav = [
    { label: "Home", href: "/" },
    { label: "Academic Hub", href: "/academic-hub" },
    { label: "Internships & Jobs", href: "/jobs" },
    { label: "Results", href: "/results" },
    { label: "Aptitude", href: "/aptitude" },
  ];

  return (
    <header className="sticky top-0 z-50 border-b border-white/10 bg-[#08090D]/90 backdrop-blur-md">
      <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
        {/* Brand */}
        <Link href="/" className="flex items-center gap-2.5">
          <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-gradient-to-tr from-[#4C7CFF] via-[#8B6BFF] to-[#38E4E0] font-extrabold text-[#06070A] shadow-lg shadow-[#4C7CFF]/20">
            M
          </div>
          <span className="font-display text-lg font-bold tracking-tight text-white">
            MyVault Technologies
          </span>
        </Link>

        {/* Navigation Links */}
        <nav className="hidden items-center gap-6 text-xs font-medium md:flex">
          {(isHomePage ? companyNav : studentNav).map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className="text-[#9295A3] transition-colors hover:text-white"
            >
              {item.label}
            </Link>
          ))}
        </nav>

        {/* Header Action CTA */}
        <div className="flex items-center gap-3">
          {isHomePage ? (
            <a
              href="/#contact"
              className="rounded-full border border-white/15 bg-white/5 px-4 py-2 text-xs font-semibold text-white transition-colors hover:bg-white/10"
            >
              Get a Quote
            </a>
          ) : (
            <Link
              href="/myvault-app.apk"
              className="rounded-full border border-[#38E4E0]/40 bg-[#38E4E0]/10 px-4 py-2 text-xs font-semibold text-[#38E4E0] hover:bg-[#38E4E0]/20"
            >
              📲 APK Download
            </Link>
          )}
        </div>
      </div>
    </header>
  );
}
