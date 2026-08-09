import Link from "next/link";

const FEATURE_CARDS = [
  {
    title: "Academic Hub",
    description: "Branch- & semester-wise notes, question banks, syllabus, and lab manuals.",
    icon: "📚",
    href: "/academic-hub",
    badge: "Notes & Syllabus",
  },
  {
    title: "Internships & Jobs",
    description: "Curated internships, placement drives, and government job postings.",
    icon: "💼",
    href: "/jobs",
    badge: "Placements",
  },
  {
    title: "Semester Results",
    description: "Instant marksheet & memo lookup by Hall Ticket and Semester.",
    icon: "📊",
    href: "/results",
    badge: "Instant Results",
  },
  {
    title: "Aptitude Practice",
    description: "Quantitative, logical, and verbal practice quizzes for recruitment.",
    icon: "🧠",
    href: "/aptitude",
    badge: "Exam Prep",
  },
];

export default function LandingPage() {
  return (
    <main className="mx-auto max-w-6xl px-6 py-12">
      {/* Hero Section */}
      <section className="mb-16 text-center">
        <div className="mb-4 inline-flex items-center gap-2 rounded-full border border-accentCyan/30 bg-accentCyan/10 px-4 py-1 text-xs font-semibold text-accentCyan">
          <span className="h-2 w-2 rounded-full bg-accentCyan animate-pulse"></span>
          Warangal Engineering & Degree Student Portal
        </div>
        <h1 className="mx-auto max-w-4xl text-4xl font-extrabold leading-tight sm:text-6xl">
          Every subject, every result, every job listing —{" "}
          <span className="bg-gradient-to-r from-accentBlue via-accentCyan to-white bg-clip-text text-transparent">
            on Web & Mobile.
          </span>
        </h1>
        <p className="mx-auto mt-6 max-w-2xl text-base text-white/60">
          MyVault is your unified academic portal. Browse subjects, download notes, look up exam results, explore job postings, and practice aptitude tests directly online or on the mobile app.
        </p>

        <div className="mt-8 flex flex-wrap justify-center gap-4">
          <Link
            href="/academic-hub"
            className="rounded-xl bg-gradient-to-r from-accentBlue to-accentCyan px-6 py-3 text-sm font-bold text-black shadow-lg shadow-accentBlue/20 hover:opacity-90"
          >
            Explore Academic Hub →
          </Link>
          <Link
            href="/myvault-app.apk"
            className="rounded-xl border border-white/20 bg-white/5 px-6 py-3 text-sm font-semibold text-white hover:bg-white/10"
          >
            📲 Download Android APK
          </Link>
        </div>
      </section>

      {/* Student Portal Quick Features Grid */}
      <section className="mb-20">
        <h2 className="mb-6 text-xl font-bold text-white">Student Portal Modules</h2>
        <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
          {FEATURE_CARDS.map((card) => (
            <Link
              key={card.title}
              href={card.href}
              className="group flex flex-col justify-between rounded-3xl border border-white/10 bg-white/[0.03] p-6 shadow-xl backdrop-blur-xl transition-all hover:-translate-y-1 hover:border-accentCyan/40 hover:bg-white/[0.06]"
            >
              <div>
                <div className="flex items-center justify-between">
                  <span className="text-3xl">{card.icon}</span>
                  <span className="rounded-full bg-white/10 px-2.5 py-1 text-[10px] font-semibold text-white/70">
                    {card.badge}
                  </span>
                </div>
                <h3 className="mt-4 text-lg font-bold text-white group-hover:text-accentCyan">
                  {card.title}
                </h3>
                <p className="mt-2 text-xs leading-relaxed text-white/50">
                  {card.description}
                </p>
              </div>

              <div className="mt-6 flex items-center text-xs font-semibold text-accentCyan">
                Open Module <span className="ml-1 transition-transform group-hover:translate-x-1">→</span>
              </div>
            </Link>
          ))}
        </div>
      </section>

      {/* Admin Web Link Banner */}
      <section className="rounded-3xl border border-white/10 bg-gradient-to-r from-accentBlue/10 via-accentCyan/10 to-transparent p-8 backdrop-blur-xl flex flex-col sm:flex-row items-center justify-between gap-6">
        <div>
          <h3 className="text-xl font-bold text-white">College Admin Console</h3>
          <p className="mt-1 text-xs text-white/60">
            Faculty and administrators can log in to upload notes, publish results, and post job listings.
          </p>
        </div>
        <a
          href="http://localhost:3001/login"
          target="_blank"
          rel="noreferrer"
          className="whitespace-nowrap rounded-xl bg-white/10 border border-white/20 px-6 py-3 text-xs font-bold text-white hover:bg-white/20"
        >
          Open Admin Web Console ↗
        </a>
      </section>
    </main>
  );
}
