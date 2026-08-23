"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";

export default function CertificateVerificationPage() {
  const params = useParams();
  const certificateNumber = params?.certificateNumber as string;

  const [loading, setLoading] = useState(true);
  const [data, setData] = useState<any>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!certificateNumber) return;
    async function verify() {
      try {
        const res = await fetch(`https://romantic-serenity-production-3e5b.up.railway.app/certificates/${encodeURIComponent(certificateNumber)}`);
        const json = await res.json();
        if (json.valid) {
          setData(json.certificate);
        } else {
          setError(json.error || "Invalid or unverified certificate.");
        }
      } catch (err: any) {
        setError("Verification service unavailable.");
      } finally {
        setLoading(false);
      }
    }
    verify();
  }, [certificateNumber]);

  return (
    <div className="flex min-h-screen items-center justify-center bg-obsidian px-4 py-12 text-white">
      <div className="w-full max-w-md rounded-2xl border border-white/10 bg-white/[0.03] p-8 text-center backdrop-blur-xl shadow-2xl">
        <div className="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-accentCyan/20 text-accentCyan border border-accentCyan/40">
          <span className="text-3xl">🏆</span>
        </div>
        <h1 className="text-xl font-bold bg-gradient-to-r from-accentBlue to-accentCyan bg-clip-text text-transparent">
          MyVault Official Certificate Verification
        </h1>

        {loading ? (
          <p className="mt-6 text-xs text-white/50 animate-pulse">Verifying certificate with blockchain ledger...</p>
        ) : error ? (
          <div className="mt-6 rounded-xl border border-red-500/30 bg-red-500/10 p-4 text-xs font-semibold text-red-400">
            ❌ {error}
          </div>
        ) : (
          <div className="mt-6 space-y-4 text-left">
            <div className="rounded-xl border border-emerald-500/30 bg-emerald-500/10 p-3 text-center text-xs font-semibold text-emerald-400">
              ✓ VERIFIED AUTHENTIC INDUSTRIAL CERTIFICATE
            </div>

            <div className="space-y-2 rounded-xl border border-white/10 bg-white/5 p-4 text-xs">
              <div>
                <span className="text-white/50">Student / Recipient:</span>
                <p className="text-sm font-bold text-white">{data.studentName || data.studentId}</p>
              </div>
              <div>
                <span className="text-white/50">Course / Internship Title:</span>
                <p className="text-sm font-semibold text-accentCyan">{data.courseTitle || "Industrial Course"}</p>
              </div>
              <div>
                <span className="text-white/50">Certificate Number:</span>
                <p className="font-mono text-white/80">{data.certificateId || certificateNumber}</p>
              </div>
              <div>
                <span className="text-white/50">Issued Date:</span>
                <p className="text-white/80">{data.issuedAt ? new Date(data.issuedAt).toLocaleDateString() : "Verified"}</p>
              </div>
            </div>

            {data.certificateUrl && (
              <a
                href={data.certificateUrl}
                target="_blank"
                rel="noreferrer"
                className="block w-full rounded-xl bg-accentBlue py-3 text-center text-xs font-semibold text-white transition-all hover:bg-accentBlue/80 shadow-lg"
              >
                View Official PDF Certificate ↗
              </a>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
