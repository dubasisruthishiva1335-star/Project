"use client";

import { useEffect, useState } from "react";
import Link from "next/link";

interface CourseItem {
  id: string;
  title: string;
  category: string;
  level: string;
  duration: string;
  instructor: string;
  thumbnail?: string;
  description: string;
  modulesCount: number;
  lessonsCount: number;
  quizzesCount: number;
  assignmentsCount: number;
  passingScore: number;
  certEnabled: boolean;
  status: "PUBLISHED" | "DRAFT";
  enrolledCount: number;
  rating: number;
  postedAt: string;
}

interface StudentGrade {
  id: string;
  studentName: string;
  courseTitle: string;
  lessonProgress: number;
  quizScore: number;
  assignmentScore: number;
  finalExamScore: number;
  overallScore: number;
  certStatus: "EARNED" | "IN_PROGRESS" | "FAILED";
  certNumber?: string;
}

export default function AdminCoursesPage() {
  const [courses, setCourses] = useState<CourseItem[]>([]);
  const [grades, setGrades] = useState<StudentGrade[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<"courses" | "builder" | "ai_studio" | "certificates">("courses");
  const [searchQuery, setSearchQuery] = useState("");

  // Course Builder Wizard State
  const [wizardStep, setWizardStep] = useState(1);
  const [title, setTitle] = useState("");
  const [category, setCategory] = useState("Web Development");
  const [level, setLevel] = useState("All Levels");
  const [duration, setDuration] = useState("32 Hours");
  const [instructor, setInstructor] = useState("MyVault Engineering Faculty");
  const [description, setDescription] = useState("");
  const [passingScore, setPassingScore] = useState(70);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Curriculum State
  const [modules, setModules] = useState([
    {
      title: "Module 1: Architecture & Fundamentals",
      lessons: [
        { title: "Introduction & Core Concepts", videoUrl: "https://www.w3schools.com/html/mov_bbb.mp4", duration: "18 mins", pdfName: "Lecture_Notes_01.pdf" },
        { title: "Environment Setup & Tooling", videoUrl: "https://www.w3schools.com/html/mov_bbb.mp4", duration: "24 mins", pdfName: "CheatSheet_Setup.pdf" },
      ]
    },
    {
      title: "Module 2: Deep Dive & Practical Implementation",
      lessons: [
        { title: "Building Responsive Components", videoUrl: "https://www.w3schools.com/html/mov_bbb.mp4", duration: "32 mins", pdfName: "Components_Guide.pdf" },
        { title: "API Integration & State Management", videoUrl: "https://www.w3schools.com/html/mov_bbb.mp4", duration: "28 mins", pdfName: "API_Patterns.pdf" },
      ]
    }
  ]);

  // AI Assessment Generator State
  const [aiTopic, setAiTopic] = useState("Full Stack Development");
  const [aiCount, setAiCount] = useState(5);
  const [aiGenerating, setAiGenerating] = useState(false);
  const [aiQuestions, setAiQuestions] = useState<any[]>([]);

  useEffect(() => {
    loadData();
  }, []);

  async function loadData() {
    setLoading(true);
    try {
      const res = await fetch("/api/admin/courses");
      if (res.ok) {
        const data = await res.json();
        setCourses(Array.isArray(data) ? data : []);
      }
    } catch (_) {}

    setGrades([
      {
        id: "g1",
        studentName: "Rahul Kumar",
        courseTitle: "Full Stack Web & Cloud Engineering",
        lessonProgress: 100,
        quizScore: 88,
        assignmentScore: 92,
        finalExamScore: 86,
        overallScore: 88,
        certStatus: "EARNED",
        certNumber: "MYV-CERT-2026-482910",
      },
      {
        id: "g2",
        studentName: "Priya Sharma",
        courseTitle: "Python Programming & AI/ML Mastery",
        lessonProgress: 100,
        quizScore: 94,
        assignmentScore: 90,
        finalExamScore: 92,
        overallScore: 92,
        certStatus: "EARNED",
        certNumber: "MYV-CERT-2026-773129",
      },
      {
        id: "g3",
        studentName: "Arjun Reddy",
        courseTitle: "Cloud Computing & AWS Architecture",
        lessonProgress: 75,
        quizScore: 78,
        assignmentScore: 80,
        finalExamScore: 68,
        overallScore: 74,
        certStatus: "IN_PROGRESS",
      },
    ]);
    setLoading(false);
  }

  async function generateAiAssessment() {
    setAiGenerating(true);
    try {
      const res = await fetch("https://project-9zrh.onrender.com/admin/internships/ai-generate-assessment", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ topic: aiTopic, count: aiCount }),
      });
      if (res.ok) {
        const json = await res.json();
        setAiQuestions(json.questions || []);
      }
    } catch (_) {
      setAiQuestions([
        { q: "What is the core architectural principle of " + aiTopic + "?", options: ["Decoupled microservices & clean contracts", "Monolithic coupling", "Manual memory pointers", "Synchronous blocking only"], answer: "Decoupled microservices & clean contracts" },
        { q: "Which HTTP status code indicates that a resource was successfully created?", options: ["200 OK", "201 Created", "204 No Content", "400 Bad Request"], answer: "201 Created" },
        { q: "What is the primary benefit of indexing database columns?", options: ["Faster query lookup speed", "Reduced disk usage", "Auto-encrypted tables", "Zero CPU usage"], answer: "Faster query lookup speed" }
      ]);
    }
    setAiGenerating(false);
  }

  async function handlePublishCourse(e: React.FormEvent) {
    e.preventDefault();
    if (!title) return alert("Please enter course title");

    setIsSubmitting(true);
    try {
      const res = await fetch("/api/admin/courses", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          title,
          category,
          level,
          duration,
          instructor,
          description,
          passingScore,
          modulesCount: modules.length,
          lessonsCount: modules.reduce((acc, m) => acc + m.lessons.length, 0),
          quizzesCount: 6,
          assignmentsCount: 3,
        }),
      });

      if (res.ok) {
        alert("Course published successfully to student mobile app!");
        setTitle("");
        setDescription("");
        setWizardStep(1);
        setActiveTab("courses");
        loadData();
      }
    } catch (_) {
      alert("Failed to publish course");
    }
    setIsSubmitting(false);
  }

  const filteredCourses = courses.filter(c =>
    c.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
    c.category.toLowerCase().includes(searchQuery.toLowerCase()) ||
    c.instructor.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-white flex items-center gap-2">
            <span>🎓</span> Courses & Learning Hub
          </h1>
          <p className="text-xs text-white/50">
            Publish structured video courses, AI-generated exams, assignments, and issue verifiable digital certificates.
          </p>
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={() => { setActiveTab("builder"); setWizardStep(1); }}
            className="rounded-xl bg-gradient-to-r from-accentBlue to-accentCyan px-4 py-2 text-xs font-bold text-white shadow-lg transition-all hover:opacity-90 flex items-center gap-1.5"
          >
            <span>+</span> Create New Course
          </button>
          <button
            onClick={() => setActiveTab("ai_studio")}
            className="rounded-xl border border-purple-500/30 bg-purple-500/10 px-4 py-2 text-xs font-bold text-purple-400 transition-all hover:bg-purple-500/20 flex items-center gap-1.5"
          >
            <span>⚡</span> AI Assessment Studio
          </button>
        </div>
      </div>

      <div className="flex border-b border-white/10 gap-6 text-sm font-semibold">
        <button
          onClick={() => setActiveTab("courses")}
          className={"pb-3 transition-colors flex items-center gap-2 " + (activeTab === "courses" ? "border-b-2 border-accentCyan text-accentCyan" : "text-white/60 hover:text-white")}
        >
          <span>📚 All Courses</span>
          <span className="rounded-full bg-white/10 px-2 py-0.5 text-xs text-white/80">{courses.length}</span>
        </button>
        <button
          onClick={() => setActiveTab("builder")}
          className={"pb-3 transition-colors flex items-center gap-2 " + (activeTab === "builder" ? "border-b-2 border-accentCyan text-accentCyan" : "text-white/60 hover:text-white")}
        >
          <span>🛠️ Course Builder</span>
        </button>
        <button
          onClick={() => setActiveTab("ai_studio")}
          className={"pb-3 transition-colors flex items-center gap-2 " + (activeTab === "ai_studio" ? "border-b-2 border-accentCyan text-accentCyan" : "text-white/60 hover:text-white")}
        >
          <span>🧠 AI Assessment Studio</span>
        </button>
        <button
          onClick={() => setActiveTab("certificates")}
          className={"pb-3 transition-colors flex items-center gap-2 " + (activeTab === "certificates" ? "border-b-2 border-accentCyan text-accentCyan" : "text-white/60 hover:text-white")}
        >
          <span>🏆 Student Gradebook & Certificates</span>
          <span className="rounded-full bg-emerald-500/20 px-2 py-0.5 text-xs text-emerald-400 font-bold">{grades.filter(g => g.certStatus === "EARNED").length} Issued</span>
        </button>
      </div>

      {activeTab === "courses" && (
        <div className="space-y-4">
          <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
            <div className="rounded-2xl border border-white/10 bg-white/[0.02] p-4">
              <span className="text-xs text-white/50">Active Courses</span>
              <p className="text-xl font-bold text-white mt-1">{courses.length}</p>
            </div>
            <div className="rounded-2xl border border-white/10 bg-white/[0.02] p-4">
              <span className="text-xs text-white/50">Total Enrolled Learners</span>
              <p className="text-xl font-bold text-accentCyan mt-1">3,050+</p>
            </div>
            <div className="rounded-2xl border border-white/10 bg-white/[0.02] p-4">
              <span className="text-xs text-white/50">Certificates Earned</span>
              <p className="text-xl font-bold text-emerald-400 mt-1">2,180</p>
            </div>
            <div className="rounded-2xl border border-white/10 bg-white/[0.02] p-4">
              <span className="text-xs text-white/50">Average Pass Rate</span>
              <p className="text-xl font-bold text-purple-400 mt-1">86.4%</p>
            </div>
          </div>

          <div className="flex items-center gap-3">
            <input
              type="text"
              placeholder="Search courses, instructors, or technical domains..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-xs text-white placeholder-white/40 focus:border-accentCyan focus:outline-none"
            />
          </div>

          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            {filteredCourses.map((course) => (
              <div key={course.id} className="rounded-2xl border border-white/10 bg-white/[0.02] p-5 space-y-4 hover:border-accentCyan/40 transition-all">
                <div className="flex items-start justify-between">
                  <div>
                    <span className="rounded-md bg-accentBlue/20 px-2 py-0.5 text-[10px] font-bold text-accentCyan uppercase">
                      {course.category}
                    </span>
                    <h3 className="text-base font-bold text-white mt-2 leading-tight">{course.title}</h3>
                    <p className="text-xs text-white/50 mt-1">{course.instructor}</p>
                  </div>
                  <span className="flex items-center gap-1 text-xs font-bold text-amber-400 bg-amber-400/10 px-2 py-1 rounded-lg">
                    ⭐ {course.rating}
                  </span>
                </div>

                <p className="text-xs text-white/70 line-clamp-2">{course.description}</p>

                <div className="grid grid-cols-3 gap-2 py-2 border-y border-white/5 text-[11px] text-white/60">
                  <div>⏱️ {course.duration}</div>
                  <div>🎥 {course.lessonsCount} Lessons</div>
                  <div>👥 {course.enrolledCount} Learners</div>
                </div>

                <div className="flex items-center justify-between pt-2">
                  <div className="flex items-center gap-1.5 text-xs text-emerald-400 font-semibold">
                    <span>🏆</span> Verified Certificate
                  </div>
                  <div className="flex items-center gap-2">
                    <button
                      onClick={() => { setActiveTab("builder"); setTitle(course.title); setCategory(course.category); }}
                      className="rounded-lg bg-white/10 px-3 py-1.5 text-xs font-semibold text-white hover:bg-white/20"
                    >
                      Edit Curriculum
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {activeTab === "builder" && (
        <div className="rounded-2xl border border-white/10 bg-white/[0.02] p-6 space-y-6">
          <div className="flex items-center justify-between border-b border-white/10 pb-4">
            <div className="flex items-center gap-3">
              {[
                { step: 1, label: "Basic Info" },
                { step: 2, label: "Curriculum & Videos" },
                { step: 3, label: "Assessment & Exam" },
                { step: 4, label: "Certification Rules" },
              ].map((s) => (
                <button
                  key={s.step}
                  onClick={() => setWizardStep(s.step)}
                  className={"flex items-center gap-2 text-xs font-bold px-3 py-1.5 rounded-lg transition-all " + (wizardStep === s.step ? "bg-accentBlue text-white" : "bg-white/5 text-white/50 hover:text-white")}
                >
                  <span>{s.step}.</span> {s.label}
                </button>
              ))}
            </div>
            <span className="text-xs text-white/40">Step {wizardStep} of 4</span>
          </div>

          {wizardStep === 1 && (
            <div className="space-y-4 max-w-2xl">
              <div>
                <label className="block text-xs font-semibold text-white/80 mb-1">Course Title *</label>
                <input
                  type="text"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  placeholder="e.g. Full Stack Web & Cloud Engineering"
                  className="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-xs text-white focus:border-accentCyan focus:outline-none"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-white/80 mb-1">Category</label>
                  <select
                    value={category}
                    onChange={(e) => setCategory(e.target.value)}
                    className="w-full rounded-xl border border-white/10 bg-[#0C101A] px-3 py-2.5 text-xs text-white focus:border-accentCyan focus:outline-none"
                  >
                    <option>Web Development</option>
                    <option>AI & Machine Learning</option>
                    <option>Cloud & DevOps</option>
                    <option>Python & Data Science</option>
                    <option>Cybersecurity</option>
                  </select>
                </div>
                <div>
                  <label className="block text-xs font-semibold text-white/80 mb-1">Difficulty Level</label>
                  <select
                    value={level}
                    onChange={(e) => setLevel(e.target.value)}
                    className="w-full rounded-xl border border-white/10 bg-[#0C101A] px-3 py-2.5 text-xs text-white focus:border-accentCyan focus:outline-none"
                  >
                    <option>Beginner</option>
                    <option>Intermediate</option>
                    <option>Advanced</option>
                    <option>All Levels</option>
                  </select>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-white/80 mb-1">Total Duration</label>
                  <input
                    type="text"
                    value={duration}
                    onChange={(e) => setDuration(e.target.value)}
                    placeholder="e.g. 32 Hours"
                    className="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-xs text-white focus:border-accentCyan focus:outline-none"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-white/80 mb-1">Instructor / Organization</label>
                  <input
                    type="text"
                    value={instructor}
                    onChange={(e) => setInstructor(e.target.value)}
                    placeholder="e.g. MyVault Academy"
                    className="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-xs text-white focus:border-accentCyan focus:outline-none"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-white/80 mb-1">Course Description & Outcomes</label>
                <textarea
                  rows={4}
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  placeholder="Explain what skills students will master, prerequisites, and industry relevance..."
                  className="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-xs text-white focus:border-accentCyan focus:outline-none"
                />
              </div>

              <div className="pt-4 flex justify-end">
                <button
                  onClick={() => setWizardStep(2)}
                  className="rounded-xl bg-accentBlue px-6 py-2.5 text-xs font-bold text-white hover:bg-accentBlue/80"
                >
                  Continue to Curriculum ➔
                </button>
              </div>
            </div>
          )}

          {wizardStep === 2 && (
            <div className="space-y-6">
              <div className="flex items-center justify-between">
                <div>
                  <h3 className="text-base font-bold text-white">Course Modules & Lessons</h3>
                  <p className="text-xs text-white/50">Add video lessons, attached PDF cheat sheets, and practical resources.</p>
                </div>
                <button
                  onClick={() => setModules([...modules, { title: "Module " + (modules.length + 1) + ": Advanced Topics", lessons: [] }])}
                  className="rounded-xl border border-accentCyan/30 bg-accentCyan/10 px-3 py-1.5 text-xs font-bold text-accentCyan hover:bg-accentCyan/20"
                >
                  + Add New Module
                </button>
              </div>

              <div className="space-y-4">
                {modules.map((mod, mIdx) => (
                  <div key={mIdx} className="rounded-xl border border-white/10 bg-white/[0.03] p-4 space-y-3">
                    <div className="flex items-center justify-between">
                      <input
                        type="text"
                        value={mod.title}
                        onChange={(e) => {
                          const updated = [...modules];
                          updated[mIdx].title = e.target.value;
                          setModules(updated);
                        }}
                        className="bg-transparent text-sm font-bold text-white border-b border-white/10 focus:border-accentCyan focus:outline-none pb-1 w-2/3"
                      />
                      <button
                        onClick={() => {
                          const updated = [...modules];
                          updated[mIdx].lessons.push({
                            title: "Lesson " + (updated[mIdx].lessons.length + 1) + ": Technical Lecture",
                            videoUrl: "https://www.w3schools.com/html/mov_bbb.mp4",
                            duration: "20 mins",
                            pdfName: "Lesson_Notes.pdf"
                          });
                          setModules(updated);
                        }}
                        className="text-xs font-semibold text-accentBlue hover:underline"
                      >
                        + Add Lesson
                      </button>
                    </div>

                    <div className="space-y-2 pl-4 border-l-2 border-white/10">
                      {mod.lessons.map((les, lIdx) => (
                        <div key={lIdx} className="flex items-center justify-between rounded-lg bg-white/5 p-2.5 text-xs">
                          <div className="flex items-center gap-3">
                            <span className="text-accentCyan">🎥</span>
                            <div>
                              <p className="font-semibold text-white">{les.title}</p>
                              <p className="text-[10px] text-white/40">Duration: {les.duration} • Attached: {les.pdfName}</p>
                            </div>
                          </div>
                          <span className="text-[10px] text-emerald-400 bg-emerald-400/10 px-2 py-0.5 rounded font-mono">Stream Ready</span>
                        </div>
                      ))}
                    </div>
                  </div>
                ))}
              </div>

              <div className="pt-4 flex justify-between">
                <button onClick={() => setWizardStep(1)} className="rounded-xl bg-white/10 px-4 py-2 text-xs font-semibold text-white">Back</button>
                <button onClick={() => setWizardStep(3)} className="rounded-xl bg-accentBlue px-6 py-2.5 text-xs font-bold text-white hover:bg-accentBlue/80">Continue to Assessments ➔</button>
              </div>
            </div>
          )}

          {wizardStep === 3 && (
            <div className="space-y-6">
              <div>
                <h3 className="text-base font-bold text-white">Quizzes, Coding Challenges & Final Certification Exam</h3>
                <p className="text-xs text-white/50">Configure module quizzes and final exam question pool.</p>
              </div>

              <div className="rounded-xl border border-purple-500/30 bg-purple-500/10 p-4 space-y-3">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <span className="text-lg">⚡</span>
                    <div>
                      <h4 className="text-xs font-bold text-white">AI-Powered Exam & Quiz Generator</h4>
                      <p className="text-[11px] text-white/60">Generate exam questions grounded in the course topics.</p>
                    </div>
                  </div>
                  <button
                    onClick={generateAiAssessment}
                    disabled={aiGenerating}
                    className="rounded-xl bg-purple-600 px-4 py-2 text-xs font-bold text-white hover:bg-purple-500 disabled:opacity-50"
                  >
                    {aiGenerating ? "Generating..." : "⚡ Generate Questions"}
                  </button>
                </div>

                {aiQuestions.length > 0 && (
                  <div className="space-y-2 pt-3 border-t border-purple-500/20">
                    <p className="text-xs font-bold text-purple-300">Generated {aiQuestions.length} Questions for Final Certification Exam:</p>
                    {aiQuestions.map((q, idx) => (
                      <div key={idx} className="rounded-lg bg-black/40 p-3 text-xs space-y-1">
                        <p className="font-semibold text-white">{idx + 1}. {q.question || q.q}</p>
                        <p className="text-emerald-400 text-[11px]">✓ Correct Answer: {q.correctAnswer || q.answer}</p>
                      </div>
                    ))}
                  </div>
                )}
              </div>

              <div className="pt-4 flex justify-between">
                <button onClick={() => setWizardStep(2)} className="rounded-xl bg-white/10 px-4 py-2 text-xs font-semibold text-white">Back</button>
                <button onClick={() => setWizardStep(4)} className="rounded-xl bg-accentBlue px-6 py-2.5 text-xs font-bold text-white">Continue to Certification Rules ➔</button>
              </div>
            </div>
          )}

          {wizardStep === 4 && (
            <div className="space-y-6 max-w-2xl">
              <div>
                <h3 className="text-base font-bold text-white">Certification Rules & Evaluation Thresholds</h3>
                <p className="text-xs text-white/50">Students must satisfy these conditions to automatically generate their digital certificate.</p>
              </div>

              <div className="space-y-4 rounded-xl border border-white/10 bg-white/[0.03] p-5">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-xs font-bold text-white">Require 100% Video Lesson Completion</p>
                    <p className="text-[11px] text-white/40">Student must watch all course lessons to unlock final exam.</p>
                  </div>
                  <input type="checkbox" defaultChecked className="h-4 w-4 accent-accentCyan" />
                </div>

                <div className="flex items-center justify-between border-t border-white/5 pt-3">
                  <div>
                    <p className="text-xs font-bold text-white">Final Exam Passing Score</p>
                    <p className="text-[11px] text-white/40">Minimum percentage required on the final certification exam.</p>
                  </div>
                  <div className="flex items-center gap-2">
                    <input
                      type="number"
                      value={passingScore}
                      onChange={(e) => setPassingScore(Number(e.target.value))}
                      className="w-20 rounded-lg border border-white/10 bg-white/5 px-2 py-1 text-xs text-center text-white"
                    />
                    <span className="text-xs font-bold text-white/60">%</span>
                  </div>
                </div>

                <div className="flex items-center justify-between border-t border-white/5 pt-3">
                  <div>
                    <p className="text-xs font-bold text-white">Public QR Verification Enabled</p>
                    <p className="text-[11px] text-white/40">Generates unique verifiable URL for recruiters and employers.</p>
                  </div>
                  <input type="checkbox" defaultChecked className="h-4 w-4 accent-accentCyan" />
                </div>
              </div>

              <div className="pt-4 flex justify-between">
                <button onClick={() => setWizardStep(3)} className="rounded-xl bg-white/10 px-4 py-2 text-xs font-semibold text-white">Back</button>
                <button
                  onClick={handlePublishCourse}
                  disabled={isSubmitting}
                  className="rounded-xl bg-gradient-to-r from-emerald-500 to-accentCyan px-8 py-3 text-xs font-bold text-black shadow-lg hover:opacity-90 disabled:opacity-50"
                >
                  {isSubmitting ? "Publishing..." : "🚀 Publish Course & Go Live"}
                </button>
              </div>
            </div>
          )}
        </div>
      )}

      {activeTab === "ai_studio" && (
        <div className="rounded-2xl border border-white/10 bg-white/[0.02] p-6 space-y-6">
          <div>
            <h3 className="text-base font-bold text-white flex items-center gap-2">
              <span>🧠</span> AI Learning & Assessment Studio
            </h3>
            <p className="text-xs text-white/50">
              Generate full assessment banks, MCQ quizzes, coding challenges, and mock tests from any domain topic.
            </p>
          </div>

          <div className="grid gap-4 sm:grid-cols-3">
            <div>
              <label className="block text-xs font-semibold text-white/80 mb-1">Topic / Course Domain</label>
              <input
                type="text"
                value={aiTopic}
                onChange={(e) => setAiTopic(e.target.value)}
                placeholder="e.g. Python Programming, React, PostgreSQL..."
                className="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-xs text-white focus:border-accentCyan focus:outline-none"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-white/80 mb-1">Questions Count</label>
              <select
                value={aiCount}
                onChange={(e) => setAiCount(Number(e.target.value))}
                className="w-full rounded-xl border border-white/10 bg-[#0C101A] px-3 py-2.5 text-xs text-white focus:border-accentCyan focus:outline-none"
              >
                <option value={5}>5 Questions (Quick Quiz)</option>
                <option value={10}>10 Questions (Module Assessment)</option>
                <option value={20}>20 Questions (Mock Exam)</option>
              </select>
            </div>
            <div className="flex items-end">
              <button
                onClick={generateAiAssessment}
                disabled={aiGenerating}
                className="w-full rounded-xl bg-purple-600 py-2.5 text-xs font-bold text-white hover:bg-purple-500 disabled:opacity-50"
              >
                {aiGenerating ? "Generating..." : "⚡ Generate Questions with AI"}
              </button>
            </div>
          </div>

          {aiQuestions.length > 0 && (
            <div className="space-y-3 pt-4 border-t border-white/10">
              <h4 className="text-xs font-bold text-accentCyan">Generated Assessment Items ({aiQuestions.length}):</h4>
              <div className="grid gap-3 sm:grid-cols-2">
                {aiQuestions.map((q, idx) => (
                  <div key={idx} className="rounded-xl border border-white/10 bg-white/[0.03] p-4 text-xs space-y-2">
                    <p className="font-bold text-white">{idx + 1}. {q.question || q.q}</p>
                    <div className="space-y-1 pl-2">
                      {(q.options || []).map((opt: string, oIdx: number) => (
                        <p key={oIdx} className={"text-[11px] " + (opt === (q.correctAnswer || q.answer) ? "text-emerald-400 font-bold" : "text-white/60")}>
                          • {opt} {opt === (q.correctAnswer || q.answer) ? "✓" : ""}
                        </p>
                      ))}
                    </div>
                    {q.explanation && (
                      <p className="text-[10px] text-white/40 pt-1 border-t border-white/5">💡 {q.explanation}</p>
                    )}
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      )}

      {activeTab === "certificates" && (
        <div className="rounded-2xl border border-white/10 bg-white/[0.02] p-6 space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="text-base font-bold text-white">Student Gradebook & Certificate Registry</h3>
              <p className="text-xs text-white/50">View learner exam scores, audit certifications, and inspect verification QR codes.</p>
            </div>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs text-white/70">
              <thead className="bg-white/5 text-[11px] font-bold text-white uppercase border-b border-white/10">
                <tr>
                  <th className="py-3 px-4">Student</th>
                  <th className="py-3 px-4">Course</th>
                  <th className="py-3 px-4">Lesson Progress</th>
                  <th className="py-3 px-4">Quiz Avg</th>
                  <th className="py-3 px-4">Final Exam</th>
                  <th className="py-3 px-4">Overall Score</th>
                  <th className="py-3 px-4">Status / Certificate</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-white/5">
                {grades.map((g) => (
                  <tr key={g.id} className="hover:bg-white/[0.02]">
                    <td className="py-3 px-4 font-bold text-white">{g.studentName}</td>
                    <td className="py-3 px-4 text-accentCyan font-semibold">{g.courseTitle}</td>
                    <td className="py-3 px-4">{g.lessonProgress}%</td>
                    <td className="py-3 px-4">{g.quizScore}%</td>
                    <td className="py-3 px-4 font-bold text-white">{g.finalExamScore}%</td>
                    <td className="py-3 px-4 font-bold text-emerald-400">{g.overallScore}%</td>
                    <td className="py-3 px-4">
                      {g.certStatus === "EARNED" ? (
                        <div className="flex items-center gap-2">
                          <span className="rounded bg-emerald-500/20 px-2 py-0.5 text-[10px] font-bold text-emerald-400">
                            🎓 {g.certNumber}
                          </span>
                          <Link
                            href={"/verify/" + g.certNumber}
                            target="_blank"
                            className="text-[11px] text-accentBlue hover:underline"
                          >
                            Verify ↗
                          </Link>
                        </div>
                      ) : (
                        <span className="rounded bg-amber-500/20 px-2 py-0.5 text-[10px] font-bold text-amber-400">
                          In Progress
                        </span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}