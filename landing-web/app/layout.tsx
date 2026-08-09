import type { Metadata } from "next";
import "./globals.css";
import NavHeader from "../components/NavHeader";

export const metadata: Metadata = {
  title: "MyVault — Academics, Results, Internships & Placements",
  description:
    "MyVault brings notes, results, internships, and placement listings for engineering and degree students into one platform. Register and get started in minutes.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className="bg-obsidian text-white antialiased selection:bg-accentCyan/30 flex min-h-screen flex-col">
        <NavHeader />
        <div className="flex-1">{children}</div>
        <footer className="border-t border-white/10 py-8 text-center text-xs text-white/40">
          <p>© {new Date().getFullYear()} MyVault. All rights reserved. Self-service student portal.</p>
        </footer>
      </body>
    </html>
  );
}
