"use client";

import { useEffect, useState } from "react";
import Link from "next/link";

interface InternshipItem {
  id: string;
  title: string;
  company: string;
  logo?: string;
  workMode: "REMOTE" | "HYBRID" | "ONSITE";
  location: string;
  category: string;
  openings: number;
  startDate?: string;
  deadline?: string;
  duration?: string;
  stipend: string;
  isPaid: boolean;
  currency: string;
  description: string;
  responsibilities: string[];
  requirements: string[];
  skills: string[];
  eligibleBranches: string[];
  minCgpa: number;
  eligibleGradYears: number[];
  perks: string[];
  questions: Array<{ id: string; question: string; type: string; required: boolean }>;
  status: "DRAFT" | "PUBLISHED" | "CLOSED";
  postedAt: string;
  applicantCount: number;
}

interface CandidateApplication {
  id: string;
  internshipId: string;
  internshipTitle: string;
  company: string;
  studentName: string;
  studentEmail: string;
  studentPhone: string;
  hallTicket: string;
  branch: string;
  cgpa: number;
  gradYear: number;
  skills: string[];
  resumeUrl: string;
  coverNote?: string;
  answers: Record<string, string>;
  matchScore: number;
  status: "SUBMITTED" | "UNDER_REVIEW" | "SHORTLISTED" | "INTERVIEW" | "SELECTED" | "REJECTED";
  interviewDate?: string;
  appliedAt: string;
  notes?: string;
}

const BRANCH_OPTIONS = ["CSE", "ECE", "AI_ML", "EEE", "MECH", "CIVIL", "ALL"];
const STAGES = [
  { key: "ALL", label: "All Applicants" },
  { key: "SUBMITTED", label: "New / Submitted" },
  { key: "UNDER_REVIEW", label: "Screening" },
  { key: "SHORTLISTED", label: "Shortlisted" },
  { key: "INTERVIEW", label: "In Interview" },
  { key: "SELECTED", label: "Offered / Selected" },
  { key: "REJECTED", label: "Archived / Rejected" },
];

export default function AdminInternshipsPage() {
  const [activeTab, setActiveTab] = useState<"internships" | "pipeline" | "create">("internships");
  const [internships, setInternships] = useState<InternshipItem[]>([]);
  const [applications, setApplications] = useState<CandidateApplication[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState("");
  const [pipelineFilter, setPipelineFilter] = useState("ALL");
  const [selectedCandidate, setSelectedCandidate] = useState<CandidateApplication | null>(null);
  const [message, setMessage] = useState<{ type: "success" | "error"; text: string } | null>(null);
  const [wizardStep, setWizardStep] = useState(1);
  const [wizardForm, setWizardForm] = useState({
    title: "",
    company: "",
    logo: "",
    workMode: "HYBRID" as "REMOTE" | "HYBRID" | "ONSITE",
    location: "Bengaluru, Karnataka",
    category: "Software Engineering",
    openings: 5,
    duration: "6 Months",
    deadline: "",
    stipend: "40,000",
    isPaid: true,
    currency: "INR",
    description: "",
    responsibilitiesRaw: "Design and implement scalable RESTful APIs.\nCollaborate with senior engineers on core product features.\nWrite unit tests and optimize database performance.",
    requirementsRaw: "Proficiency in Python, Java, or TypeScript.\nSolid foundation in Data Structures and Algorithms.\nUnderstanding of databases (PostgreSQL/MongoDB) and Git.",
    skillsRaw: "Python, Data Structures, Algorithms, SQL, Git, REST APIs",
    eligibleBranches: ["CSE", "ECE", "AI_ML"],
    minCgpa: 7.0,
    eligibleGradYears: [2026, 2027],
    perksRaw: "PPO / Full-time Conversion, Mentorship, Certificate, Flexible Hours",
    q1: "Describe a project you built recently and the key technical decisions you made.",
    q2: "Are you available full-time for a 6-month internship?",
  });

  const fetchData = async () => {
    try {
      setLoading(true);
      const [intRes, appRes] = await Promise.all([
        fetch("/api/admin/internships").then(r => r.json()).catch(() => []),
        fetch("/api/internships/applications").then(r => r.json()).catch(() => []),
      ]);
      if (Array.isArray(intRes)) setInternships(intRes);
      if (Array.isArray(appRes)) setApplications(appRes);
    } catch (_) {
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  const handleUpdateStatus = async (appId: string, newStatus: string) => {
    try {
      const res = await fetch("/api/internships/applications", {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ id: appId, status: newStatus }),
      });
      if (res.ok) {
        const updated = await res.json();
        setApplications(prev => prev.map(a => a.id === appId ? updated : a));
        if (selectedCandidate?.id === appId) {
          setSelectedCandidate(updated);
        }
        setMessage({ type: "success", text: "Candidate moved to " + newStatus + " successfully." });
      }
    } catch (err: any) {
      setMessage({ type: "error", text: "Failed to update status." });
    }
  };

  const handleDeleteInternship = async (id: string) => {
    if (!confirm("Are you sure you want to delete this internship posting?")) return;
    try {
      await fetch("/api/admin/internships?id=" + id, { method: "DELETE" });
      setInternships(prev => prev.filter(i => i.id !== id));
      setMessage({ type: "success", text: "Internship posting deleted." });
    } catch (_) {
      setMessage({ type: "error", text: "Failed to delete internship." });
    }
  };

  const handleCreateInternship = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!wizardForm.title || !wizardForm.company) {
      setMessage({ type: "error", text: "Role title and company name are required." });
      return;
    }

    try {
      const payload = {
        title: wizardForm.title,
        company: wizardForm.company,
        logo: wizardForm.logo,
        workMode: wizardForm.workMode,
        location: wizardForm.location,
        category: wizardForm.category,
        openings: wizardForm.openings,
        duration: wizardForm.duration,
        deadline: wizardForm.deadline,
        stipend: wizardForm.stipend,
        isPaid: wizardForm.isPaid,
        currency: wizardForm.currency,
        description: wizardForm.description || ("Join " + wizardForm.company + " as a " + wizardForm.title + "."),
        responsibilities: wizardForm.responsibilitiesRaw.split("\n").filter(Boolean),
        requirements: wizardForm.requirementsRaw.split("\n").filter(Boolean),
        skills: wizardForm.skillsRaw.split(",").map(s => s.trim()).filter(Boolean),
        eligibleBranches: wizardForm.eligibleBranches,
        minCgpa: wizardForm.minCgpa,
        eligibleGradYears: wizardForm.eligibleGradYears,
        perks: wizardForm.perksRaw.split(",").map(s => s.trim()).filter(Boolean),
        questions: [
          ...(wizardForm.q1 ? [{ id: "q1", question: wizardForm.q1, type: "textarea", required: true }] : []),
          ...(wizardForm.q2 ? [{ id: "q2", question: wizardForm.q2, type: "text", required: true }] : []),
        ],
        status: "PUBLISHED",
      };

      const res = await fetch("/api/admin/internships", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });

      if (res.ok) {
        const created = await res.json();
        setInternships(prev => [created, ...prev]);
        setMessage({ type: "success", text: "🎉 " + created.title + " at " + created.company + " published successfully!" });
        setActiveTab("internships");
        setWizardStep(1);
      }
    } catch (_) {
      setMessage({ type: "error", text: "Failed to create internship posting." });
    }
  };

  const filteredInternships = internships.filter(i =>
    i.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
    i.company.toLowerCase().includes(searchQuery.toLowerCase()) ||
    i.location.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const filteredApps = applications.filter(a => {
    const matchesFilter = pipelineFilter === "ALL" || a.status === pipelineFilter;
    const matchesQuery =
      a.studentName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      a.internshipTitle.toLowerCase().includes(searchQuery.toLowerCase()) ||
      a.company.toLowerCase().includes(searchQuery.toLowerCase()) ||
      a.hallTicket.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesFilter && matchesQuery;
  });

  const totalOpenings = internships.reduce((sum, i) => sum + (i.openings || 1), 0);
  const totalApps = applications.length;
  const inInterview = applications.filter(a => a.status === "INTERVIEW").length;
  const selectedCount = applications.filter(a => a.status === "SELECTED").length;

  return (
    <div className="mx-auto max-w-7xl px-6 py-10">
      <div className="mb-8 flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="bg-gradient-to-r from-accentBlue to-accentCyan bg-clip-text text-2xl font-extrabold text-transparent flex items-center gap-2">
            <span>💼</span> Advanced Internship Hub & Recruitment Platform
          </h1>
          <p className="mt-1 text-sm text-white/50">
            Create, configure, publish opportunities, and manage candidate recruitment pipelines.
          </p>
        </div>
        <div className="flex items-center gap-3">
          <button
            onClick={() => { setActiveTab("create"); setWizardStep(1); }}
            className="inline-flex items-center gap-2 rounded-xl bg-accentCyan px-4 py-2 text-xs font-bold text-black hover:bg-cyan-300 transition shadow-lg shadow-cyan-500/20"
          >
            <span>➕</span> Create New Internship
          </button>
        </div>
      </div>

      {message && (
        <div className={"mb-6 rounded-xl px-4 py-3 text-xs font-semibold border flex items-center justify-between " + (message.type === "success" ? "bg-emerald-500/10 text-emerald-300 border-emerald-500/30" : "bg-red-500/10 text-red-300 border-red-500/30")}>
          <span>{message.text}</span>
          <button onClick={() => setMessage(null)} className="opacity-70 hover:opacity-100">✕</button>
        </div>
      )}

      <div className="mb-8 grid grid-cols-2 gap-4 sm:grid-cols-4">
        <div className="rounded-2xl border border-white/10 bg-gradient-to-br from-cyan-500/10 to-teal-500/10 p-5 backdrop-blur-xl">
          <div className="flex items-center justify-between">
            <span className="text-2xl">🏢</span>
            <span className="text-2xl font-black text-accentCyan">{internships.length}</span>
          </div>
          <p className="mt-2 text-xs font-bold text-white/90">Active Opportunities</p>
          <p className="text-[10px] text-white/50">{totalOpenings} Total Openings</p>
        </div>
        <div className="rounded-2xl border border-white/10 bg-gradient-to-br from-indigo-500/10 to-blue-500/10 p-5 backdrop-blur-xl">
          <div className="flex items-center justify-between">
            <span className="text-2xl">📥</span>
            <span className="text-2xl font-black text-indigo-400">{totalApps}</span>
          </div>
          <p className="mt-2 text-xs font-bold text-white/90">Applications Received</p>
          <p className="text-[10px] text-white/50">Across All Positions</p>
        </div>
        <div className="rounded-2xl border border-white/10 bg-gradient-to-br from-purple-500/10 to-pink-500/10 p-5 backdrop-blur-xl">
          <div className="flex items-center justify-between">
            <span className="text-2xl">🎙️</span>
            <span className="text-2xl font-black text-purple-400">{inInterview}</span>
          </div>
          <p className="mt-2 text-xs font-bold text-white/90">In Interview Stage</p>
          <p className="text-[10px] text-white/50">Scheduled Technical & HR</p>
        </div>
        <div className="rounded-2xl border border-white/10 bg-gradient-to-br from-emerald-500/10 to-cyan-500/10 p-5 backdrop-blur-xl">
          <div className="flex items-center justify-between">
            <span className="text-2xl">🎉</span>
            <span className="text-2xl font-black text-emerald-400">{selectedCount}</span>
          </div>
          <p className="mt-2 text-xs font-bold text-white/90">Offers & Placed</p>
          <p className="text-[10px] text-white/50">Final Selection Rate</p>
        </div>
      </div>

      <div className="mb-6 flex flex-wrap items-center justify-between gap-4 border-b border-white/10 pb-4">
        <div className="flex items-center gap-2">
          <button
            onClick={() => setActiveTab("internships")}
            className={"rounded-xl px-4 py-2 text-xs font-bold transition " + (activeTab === "internships" ? "bg-accentCyan text-black shadow-lg shadow-cyan-500/20" : "bg-white/5 text-white/70 hover:bg-white/10 hover:text-white")}
          >
            📋 Published Opportunities ({internships.length})
          </button>
          <button
            onClick={() => setActiveTab("pipeline")}
            className={"rounded-xl px-4 py-2 text-xs font-bold transition " + (activeTab === "pipeline" ? "bg-accentCyan text-black shadow-lg shadow-cyan-500/20" : "bg-white/5 text-white/70 hover:bg-white/10 hover:text-white")}
          >
            👥 Candidate Recruitment Pipeline ({applications.length})
          </button>
          <button
            onClick={() => { setActiveTab("create"); setWizardStep(1); }}
            className={"rounded-xl px-4 py-2 text-xs font-bold transition " + (activeTab === "create" ? "bg-accentCyan text-black shadow-lg shadow-cyan-500/20" : "bg-white/5 text-white/70 hover:bg-white/10 hover:text-white")}
          >
            ✨ Create Internship Wizard
          </button>
        </div>
        <input
          type="text"
          placeholder="Search roles, companies, candidates..."
          value={searchQuery}
          onChange={e => setSearchQuery(e.target.value)}
          className="rounded-xl border border-white/10 bg-black/50 px-3.5 py-1.5 text-xs text-white placeholder-white/40 focus:border-accentCyan focus:outline-none w-64"
        />
      </div>

      {activeTab === "internships" && (
        <div className="space-y-4">
          <div className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3">
            {filteredInternships.map(item => (
              <div key={item.id} className="rounded-2xl border border-white/10 bg-white/[0.02] p-5 backdrop-blur-xl flex flex-col justify-between hover:border-white/20 transition-all">
                <div>
                  <div className="flex items-start justify-between gap-3 mb-3">
                    <div className="flex items-center gap-3">
                      <div className="h-10 w-10 rounded-xl bg-white/10 flex items-center justify-center font-bold text-lg text-white border border-white/10">
                        {item.company.charAt(0)}
                      </div>
                      <div>
                        <h3 className="text-sm font-bold text-white line-clamp-1">{item.title}</h3>
                        <p className="text-xs text-accentCyan font-medium">{item.company}</p>
                      </div>
                    </div>
                    <span className="rounded-full bg-emerald-500/20 px-2.5 py-0.5 text-[10px] font-bold text-emerald-300 border border-emerald-500/30">
                      {item.status}
                    </span>
                  </div>
                  <div className="flex flex-wrap items-center gap-2 mb-3 text-[11px] text-white/70">
                    <span className="rounded-md bg-white/5 px-2 py-0.5">📍 {item.location}</span>
                    <span className="rounded-md bg-accentBlue/20 px-2 py-0.5 text-accentCyan font-bold">💰 ₹{item.stipend}/mo</span>
                    <span className="rounded-md bg-white/5 px-2 py-0.5">⏱ {item.duration}</span>
                  </div>
                  <p className="text-xs text-white/60 line-clamp-2 mb-3">{item.description}</p>
                  <div className="flex flex-wrap gap-1.5 mb-4">
                    {item.skills.slice(0, 4).map(s => (
                      <span key={s} className="rounded bg-white/10 px-2 py-0.5 text-[10px] font-medium text-white/80">
                        {s}
                      </span>
                    ))}
                  </div>
                </div>
                <div className="pt-3 border-t border-white/10 flex items-center justify-between text-xs">
                  <span className="text-[11px] text-white/50">
                    📥 <strong className="text-white">{item.applicantCount}</strong> applicants
                  </span>
                  <div className="flex items-center gap-2">
                    <button
                      onClick={() => { setPipelineFilter("ALL"); setSearchQuery(item.company); setActiveTab("pipeline"); }}
                      className="rounded-lg bg-accentBlue/20 px-2.5 py-1 text-xs font-semibold text-accentCyan border border-accentBlue/40 hover:bg-accentBlue/30"
                    >
                      Pipeline ↗
                    </button>
                    <button
                      onClick={() => handleDeleteInternship(item.id)}
                      className="rounded-lg bg-red-500/20 px-2 py-1 text-xs font-semibold text-red-300 border border-red-500/30 hover:bg-red-500/30"
                    >
                      ✕
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {activeTab === "pipeline" && (
        <div className="rounded-2xl border border-white/10 bg-white/[0.02] p-6 backdrop-blur-xl">
          <div className="mb-6 flex flex-wrap items-center gap-2">
            {STAGES.map(stage => {
              const count = stage.key === "ALL" ? applications.length : applications.filter(a => a.status === stage.key).length;
              const isSelected = pipelineFilter === stage.key;
              return (
                <button
                  key={stage.key}
                  onClick={() => setPipelineFilter(stage.key)}
                  className={"rounded-xl px-3.5 py-1.5 text-xs font-bold transition border " + (isSelected ? "bg-accentCyan text-black border-accentCyan shadow-lg shadow-cyan-500/20" : "bg-white/5 text-white/70 border-white/10 hover:bg-white/10 hover:text-white")}
                >
                  {stage.label} ({count})
                </button>
              );
            })}
          </div>
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="border-b border-white/10 bg-white/[0.02] text-white/50 uppercase">
                <tr>
                  <th className="px-4 py-3">Candidate</th>
                  <th className="px-4 py-3">Role Applied</th>
                  <th className="px-4 py-3">Academic Match</th>
                  <th className="px-4 py-3">Stage / Status</th>
                  <th className="px-4 py-3">Resume</th>
                  <th className="px-4 py-3 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-white/5 text-white/80">
                {filteredApps.length > 0 ? (
                  filteredApps.map(app => (
                    <tr key={app.id} className="hover:bg-white/[0.02]">
                      <td className="px-4 py-3">
                        <p className="font-bold text-white">{app.studentName}</p>
                        <p className="text-[10px] text-white/40">{app.hallTicket} • {app.studentEmail}</p>
                      </td>
                      <td className="px-4 py-3">
                        <p className="font-semibold text-white">{app.internshipTitle}</p>
                        <p className="text-[10px] text-accentCyan">{app.company}</p>
                      </td>
                      <td className="px-4 py-3">
                        <div className="flex items-center gap-2">
                          <span className="rounded bg-emerald-500/20 px-2 py-0.5 text-xs font-black text-emerald-300 border border-emerald-500/30">
                            {app.matchScore}% Match
                          </span>
                          <span className="text-[10px] text-white/50">{app.branch} • CGPA {app.cgpa}</span>
                        </div>
                      </td>
                      <td className="px-4 py-3">
                        <select
                          value={app.status}
                          onChange={e => handleUpdateStatus(app.id, e.target.value)}
                          className="rounded-lg border border-white/10 bg-black/60 px-2.5 py-1 text-xs font-semibold text-white focus:border-accentCyan focus:outline-none"
                        >
                          <option value="SUBMITTED">Submitted</option>
                          <option value="UNDER_REVIEW">Screening / Review</option>
                          <option value="SHORTLISTED">Shortlisted</option>
                          <option value="INTERVIEW">Interview Scheduled</option>
                          <option value="SELECTED">Selected / Offer</option>
                          <option value="REJECTED">Rejected</option>
                        </select>
                      </td>
                      <td className="px-4 py-3">
                        <a
                          href={app.resumeUrl}
                          target="_blank"
                          rel="noreferrer"
                          className="inline-flex items-center gap-1 rounded bg-accentBlue/20 px-2 py-1 text-xs font-semibold text-accentCyan border border-accentBlue/30 hover:bg-accentBlue/30"
                        >
                          📄 Resume ↗
                        </a>
                      </td>
                      <td className="px-4 py-3 text-right">
                        <button
                          onClick={() => setSelectedCandidate(app)}
                          className="rounded-lg bg-white/10 px-3 py-1 text-xs font-semibold text-white hover:bg-white/20"
                        >
                          View Details 🔍
                        </button>
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan={6} className="px-4 py-12 text-center text-white/40">
                      No applications found for this filter.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {activeTab === "create" && (
        <div className="mx-auto max-w-3xl rounded-2xl border border-white/10 bg-white/[0.02] p-8 backdrop-blur-xl">
          <div className="mb-8 flex items-center justify-between border-b border-white/10 pb-4">
            {[
              { num: 1, label: "Role Info" },
              { num: 2, label: "JD & Skills" },
              { num: 3, label: "Eligibility" },
              { num: 4, label: "Perks" },
              { num: 5, label: "Preview & Publish" },
            ].map(s => (
              <button
                key={s.num}
                type="button"
                onClick={() => setWizardStep(s.num)}
                className={"flex items-center gap-2 text-xs font-bold transition " + (wizardStep === s.num ? "text-accentCyan" : wizardStep > s.num ? "text-emerald-400" : "text-white/40")}
              >
                <span className={"h-6 w-6 rounded-full flex items-center justify-center text-[11px] " + (wizardStep === s.num ? "bg-accentCyan text-black" : wizardStep > s.num ? "bg-emerald-500/20 text-emerald-300 border border-emerald-500/30" : "bg-white/10 text-white/50")}>
                  {wizardStep > s.num ? "✓" : s.num}
                </span>
                <span className="hidden sm:inline">{s.label}</span>
              </button>
            ))}
          </div>

          <form onSubmit={handleCreateInternship} className="space-y-6">
            {wizardStep === 1 && (
              <div className="space-y-4">
                <h3 className="text-base font-bold text-white mb-2">Step 1: Role & Company Details</h3>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="mb-1 block text-xs font-medium text-white/80">Internship Role Title *</label>
                    <input
                      type="text"
                      required
                      placeholder="e.g. Software Engineering Intern"
                      value={wizardForm.title}
                      onChange={e => setWizardForm({ ...wizardForm, title: e.target.value })}
                      className="w-full rounded-xl border border-white/10 bg-black/50 px-3.5 py-2 text-sm text-white focus:border-accentCyan focus:outline-none"
                    />
                  </div>
                  <div>
                    <label className="mb-1 block text-xs font-medium text-white/80">Company / Organization *</label>
                    <input
                      type="text"
                      required
                      placeholder="e.g. Google, Microsoft, Adobe"
                      value={wizardForm.company}
                      onChange={e => setWizardForm({ ...wizardForm, company: e.target.value })}
                      className="w-full rounded-xl border border-white/10 bg-black/50 px-3.5 py-2 text-sm text-white focus:border-accentCyan focus:outline-none"
                    />
                  </div>
                </div>
                <div className="grid grid-cols-3 gap-4">
                  <div>
                    <label className="mb-1 block text-xs font-medium text-white/80">Work Mode</label>
                    <select
                      value={wizardForm.workMode}
                      onChange={e => setWizardForm({ ...wizardForm, workMode: e.target.value as any })}
                      className="w-full rounded-xl border border-white/10 bg-black/50 px-3 py-2 text-sm text-white focus:border-accentCyan focus:outline-none"
                    >
                      <option value="HYBRID">Hybrid</option>
                      <option value="REMOTE">100% Remote</option>
                      <option value="ONSITE">On-Site</option>
                    </select>
                  </div>
                  <div>
                    <label className="mb-1 block text-xs font-medium text-white/80">Location</label>
                    <input
                      type="text"
                      placeholder="e.g. Hyderabad / Bengaluru"
                      value={wizardForm.location}
                      onChange={e => setWizardForm({ ...wizardForm, location: e.target.value })}
                      className="w-full rounded-xl border border-white/10 bg-black/50 px-3.5 py-2 text-sm text-white focus:border-accentCyan focus:outline-none"
                    />
                  </div>
                  <div>
                    <label className="mb-1 block text-xs font-medium text-white/80">Openings</label>
                    <input
                      type="number"
                      min={1}
                      value={wizardForm.openings}
                      onChange={e => setWizardForm({ ...wizardForm, openings: Number(e.target.value) })}
                      className="w-full rounded-xl border border-white/10 bg-black/50 px-3.5 py-2 text-sm text-white focus:border-accentCyan focus:outline-none"
                    />
                  </div>
                </div>
              </div>
            )}

            {wizardStep === 2 && (
              <div className="space-y-4">
                <h3 className="text-base font-bold text-white mb-2">Step 2: Job Description & Required Skills</h3>
                <div>
                  <label className="mb-1 block text-xs font-medium text-white/80">About the Role</label>
                  <textarea
                    rows={3}
                    placeholder="Provide overview of the team and mission..."
                    value={wizardForm.description}
                    onChange={e => setWizardForm({ ...wizardForm, description: e.target.value })}
                    className="w-full rounded-xl border border-white/10 bg-black/50 px-3.5 py-2 text-sm text-white focus:border-accentCyan focus:outline-none"
                  />
                </div>
                <div>
                  <label className="mb-1 block text-xs font-medium text-white/80">Key Responsibilities (One per line)</label>
                  <textarea
                    rows={3}
                    value={wizardForm.responsibilitiesRaw}
                    onChange={e => setWizardForm({ ...wizardForm, responsibilitiesRaw: e.target.value })}
                    className="w-full rounded-xl border border-white/10 bg-black/50 px-3.5 py-2 text-sm text-white focus:border-accentCyan focus:outline-none"
                  />
                </div>
                <div>
                  <label className="mb-1 block text-xs font-medium text-white/80">Required Skills (Comma-separated tags)</label>
                  <input
                    type="text"
                    placeholder="Python, React, SQL, Cloud, Git"
                    value={wizardForm.skillsRaw}
                    onChange={e => setWizardForm({ ...wizardForm, skillsRaw: e.target.value })}
                    className="w-full rounded-xl border border-white/10 bg-black/50 px-3.5 py-2 text-sm text-white focus:border-accentCyan focus:outline-none"
                  />
                </div>
              </div>
            )}

            {wizardStep === 3 && (
              <div className="space-y-4">
                <h3 className="text-base font-bold text-white mb-2">Step 3: Eligibility Engine</h3>
                <div>
                  <label className="mb-2 block text-xs font-medium text-white/80">Eligible Branches</label>
                  <div className="flex flex-wrap gap-2">
                    {BRANCH_OPTIONS.map(b => {
                      const isSelected = wizardForm.eligibleBranches.includes(b);
                      return (
                        <button
                          key={b}
                          type="button"
                          onClick={() => {
                            const next = isSelected
                              ? wizardForm.eligibleBranches.filter(x => x !== b)
                              : [...wizardForm.eligibleBranches, b];
                            setWizardForm({ ...wizardForm, eligibleBranches: next });
                          }}
                          className={"rounded-lg px-3 py-1.5 text-xs font-bold transition border " + (isSelected ? "bg-accentCyan text-black border-accentCyan" : "bg-white/5 text-white/60 border-white/10 hover:bg-white/10")}
                        >
                          {isSelected ? "✓ " : "+ "}{b}
                        </button>
                      );
                    })}
                  </div>
                </div>
                <div className="grid grid-cols-2 gap-4 pt-2">
                  <div>
                    <label className="mb-1 block text-xs font-medium text-white/80">Minimum CGPA</label>
                    <input
                      type="number"
                      step="0.1"
                      min="0"
                      max="10"
                      value={wizardForm.minCgpa}
                      onChange={e => setWizardForm({ ...wizardForm, minCgpa: Number(e.target.value) })}
                      className="w-full rounded-xl border border-white/10 bg-black/50 px-3.5 py-2 text-sm text-white focus:border-accentCyan focus:outline-none"
                    />
                  </div>
                  <div>
                    <label className="mb-1 block text-xs font-medium text-white/80">Duration</label>
                    <input
                      type="text"
                      value={wizardForm.duration}
                      onChange={e => setWizardForm({ ...wizardForm, duration: e.target.value })}
                      className="w-full rounded-xl border border-white/10 bg-black/50 px-3.5 py-2 text-sm text-white focus:border-accentCyan focus:outline-none"
                    />
                  </div>
                </div>
              </div>
            )}

            {wizardStep === 4 && (
              <div className="space-y-4">
                <h3 className="text-base font-bold text-white mb-2">Step 4: Compensation & Perks</h3>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="mb-1 block text-xs font-medium text-white/80">Monthly Stipend (INR ₹)</label>
                    <input
                      type="text"
                      placeholder="e.g. 50,000"
                      value={wizardForm.stipend}
                      onChange={e => setWizardForm({ ...wizardForm, stipend: e.target.value })}
                      className="w-full rounded-xl border border-white/10 bg-black/50 px-3.5 py-2 text-sm text-white focus:border-accentCyan focus:outline-none"
                    />
                  </div>
                  <div>
                    <label className="mb-1 block text-xs font-medium text-white/80">Application Deadline</label>
                    <input
                      type="date"
                      value={wizardForm.deadline}
                      onChange={e => setWizardForm({ ...wizardForm, deadline: e.target.value })}
                      className="w-full rounded-xl border border-white/10 bg-black/50 px-3.5 py-2 text-sm text-white focus:border-accentCyan focus:outline-none"
                    />
                  </div>
                </div>
                <div>
                  <label className="mb-1 block text-xs font-medium text-white/80">Perks & Benefits (Comma-separated)</label>
                  <input
                    type="text"
                    value={wizardForm.perksRaw}
                    onChange={e => setWizardForm({ ...wizardForm, perksRaw: e.target.value })}
                    className="w-full rounded-xl border border-white/10 bg-black/50 px-3.5 py-2 text-sm text-white focus:border-accentCyan focus:outline-none"
                  />
                </div>
              </div>
            )}

            {wizardStep === 5 && (
              <div className="space-y-4">
                <h3 className="text-base font-bold text-white mb-2">Step 5: Live Student Preview</h3>
                <div className="rounded-2xl border border-accentCyan/30 bg-accentBlue/10 p-6 backdrop-blur-xl">
                  <div className="flex items-start justify-between gap-4 mb-3">
                    <div>
                      <h4 className="text-base font-bold text-white">{wizardForm.title || "Software Engineering Intern"}</h4>
                      <p className="text-xs font-semibold text-accentCyan">{wizardForm.company || "Company Name"} • 📍 {wizardForm.location} ({wizardForm.workMode})</p>
                    </div>
                    <span className="rounded-full bg-emerald-500/20 px-3 py-1 text-xs font-bold text-emerald-300 border border-emerald-500/30">
                      ₹{wizardForm.stipend}/mo
                    </span>
                  </div>
                  <p className="text-xs text-white/70 mb-4">{wizardForm.description || "Exciting opportunity to build real-world software solutions."}</p>
                  <div className="flex flex-wrap gap-1.5 mb-4">
                    {wizardForm.skillsRaw.split(",").map(s => (
                      <span key={s} className="rounded bg-white/10 px-2 py-0.5 text-[10px] text-white/90">
                        {s.trim()}
                      </span>
                    ))}
                  </div>
                  <div className="pt-3 border-t border-white/10 text-xs text-white/50 flex items-center justify-between">
                    <span>Eligible: {wizardForm.eligibleBranches.join(", ")} • Min CGPA {wizardForm.minCgpa}</span>
                    <span className="text-emerald-400 font-bold">1-Click Publish Ready ✓</span>
                  </div>
                </div>
              </div>
            )}

            <div className="flex items-center justify-between pt-4 border-t border-white/10">
              {wizardStep > 1 ? (
                <button
                  type="button"
                  onClick={() => setWizardStep(prev => prev - 1)}
                  className="rounded-xl border border-white/10 px-4 py-2 text-xs font-semibold text-white/70 hover:bg-white/5"
                >
                  ← Previous
                </button>
              ) : <div />}
              {wizardStep < 5 ? (
                <button
                  type="button"
                  onClick={() => setWizardStep(prev => prev + 1)}
                  className="rounded-xl bg-accentCyan px-5 py-2 text-xs font-bold text-black hover:bg-cyan-300 transition shadow-lg shadow-cyan-500/20"
                >
                  Next Step →
                </button>
              ) : (
                <button
                  type="submit"
                  className="rounded-xl bg-emerald-400 px-6 py-2.5 text-xs font-black text-black hover:bg-emerald-300 transition shadow-lg shadow-emerald-500/20"
                >
                  🚀 Publish Internship to Mobile App
                </button>
              )}
            </div>
          </form>
        </div>
      )}

      {selectedCandidate && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 backdrop-blur-sm p-4">
          <div className="w-full max-w-2xl rounded-2xl border border-white/10 bg-[#0E1017] p-6 shadow-2xl max-h-[90vh] overflow-y-auto">
            <div className="flex items-start justify-between mb-4 border-b border-white/10 pb-3">
              <div>
                <h3 className="text-lg font-bold text-white">{selectedCandidate.studentName}</h3>
                <p className="text-xs text-accentCyan">{selectedCandidate.internshipTitle} @ {selectedCandidate.company}</p>
              </div>
              <button
                onClick={() => setSelectedCandidate(null)}
                className="rounded-lg bg-white/10 px-2.5 py-1 text-xs text-white/70 hover:bg-white/20"
              >
                ✕
              </button>
            </div>
            <div className="space-y-4 text-xs">
              <div className="grid grid-cols-2 gap-3 bg-white/[0.02] p-3 rounded-xl border border-white/5">
                <div><span className="text-white/40">Hall Ticket:</span> <span className="font-mono text-white font-bold">{selectedCandidate.hallTicket}</span></div>
                <div><span className="text-white/40">Branch:</span> <span className="text-white font-bold">{selectedCandidate.branch}</span></div>
                <div><span className="text-white/40">CGPA:</span> <span className="text-emerald-300 font-bold">{selectedCandidate.cgpa}</span></div>
                <div><span className="text-white/40">Graduation Year:</span> <span className="text-white">{selectedCandidate.gradYear}</span></div>
                <div><span className="text-white/40">Email:</span> <span className="text-white">{selectedCandidate.studentEmail}</span></div>
                <div><span className="text-white/40">Phone:</span> <span className="text-white">{selectedCandidate.studentPhone}</span></div>
              </div>
              <div>
                <p className="font-bold text-white mb-1">Match Analysis & Skills:</p>
                <div className="flex flex-wrap gap-1.5 mb-2">
                  {selectedCandidate.skills.map(s => (
                    <span key={s} className="rounded bg-accentBlue/20 px-2 py-0.5 text-[10px] text-accentCyan font-semibold">
                      {s}
                    </span>
                  ))}
                </div>
              </div>
              {selectedCandidate.coverNote && (
                <div>
                  <p className="font-bold text-white mb-1">Candidate Statement / Cover Note:</p>
                  <p className="text-white/70 italic bg-black/40 p-3 rounded-xl border border-white/5">{selectedCandidate.coverNote}</p>
                </div>
              )}
              {Object.entries(selectedCandidate.answers || {}).length > 0 && (
                <div>
                  <p className="font-bold text-white mb-1">Screening Answers:</p>
                  <div className="space-y-2">
                    {Object.entries(selectedCandidate.answers).map(([qKey, ans]) => (
                      <div key={qKey} className="bg-black/40 p-3 rounded-xl border border-white/5">
                        <p className="text-white/90 font-medium">{ans}</p>
                      </div>
                    ))}
                  </div>
                </div>
              )}
              <div className="flex items-center justify-between pt-4 border-t border-white/10">
                <a
                  href={selectedCandidate.resumeUrl}
                  target="_blank"
                  rel="noreferrer"
                  className="rounded-xl bg-accentBlue/20 px-4 py-2 text-xs font-bold text-accentCyan border border-accentBlue/40 hover:bg-accentBlue/30"
                >
                  📄 Open Attached Resume ↗
                </a>
                <div className="flex items-center gap-2">
                  <button
                    onClick={() => handleUpdateStatus(selectedCandidate.id, "SHORTLISTED")}
                    className="rounded-xl bg-emerald-500/20 px-3 py-2 text-xs font-bold text-emerald-300 border border-emerald-500/30 hover:bg-emerald-500/30"
                  >
                    Shortlist ✓
                  </button>
                  <button
                    onClick={() => handleUpdateStatus(selectedCandidate.id, "INTERVIEW")}
                    className="rounded-xl bg-purple-500/20 px-3 py-2 text-xs font-bold text-purple-300 border border-purple-500/30 hover:bg-purple-500/30"
                  >
                    Schedule Interview 🎙️
                  </button>
                  <button
                    onClick={() => handleUpdateStatus(selectedCandidate.id, "SELECTED")}
                    className="rounded-xl bg-cyan-500/20 px-3 py-2 text-xs font-bold text-cyan-300 border border-cyan-500/30 hover:bg-cyan-500/30"
                  >
                    Offer Role 🎉
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}