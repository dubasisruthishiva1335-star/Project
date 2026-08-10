"use client";

import { useEffect } from "react";

export default function LandingPage() {
  useEffect(() => {
    // Redirect directly to the Admin Website Console
    if (typeof window !== "undefined") {
      window.location.href = "http://localhost:3001/login";
    }
  }, []);

  return (
    <div className="flex min-h-screen items-center justify-center bg-[#08090D] text-white">
      <div className="text-center">
        <div className="mx-auto mb-4 h-10 w-10 animate-spin rounded-full border-2 border-cyan-400 border-t-transparent"></div>
        <p className="text-sm font-semibold text-white/70">Opening Admin Web Console...</p>
        <a
          href="http://localhost:3001/login"
          className="mt-4 inline-block text-xs font-medium text-cyan-400 underline"
        >
          Click here if not redirected automatically ↗
        </a>
      </div>
    </div>
  );
}
