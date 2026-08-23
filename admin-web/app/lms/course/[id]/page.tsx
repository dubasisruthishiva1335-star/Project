"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";

export default function StudentLmsCoursePage() {
  const params = useParams();
  const courseId = params?.id as string;

  const [course, setCourse] = useState<any>(null);
  const [selectedLesson, setSelectedLesson] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [enrolled, setEnrolled] = useState(false);
  const [completedLessons, setCompletedLessons] = useState<Record<string, boolean>>({});
  const [certificateUrl, setCertificateUrl] = useState<string | null>(null);

  useEffect(() => {
    if (!courseId) return;
    async function fetchCourse() {
      try {
        const res = await fetch(`https://romantic-serenity-production-3e5b.up.railway.app/internships/${courseId}`);
        const json = await res.json();
        setCourse(json);
        if (json.modules?.[0]?.lessons?.[0]) {
          setSelectedLesson(json.modules[0].lessons[0]);
        }
      } catch (_) {}
      setLoading(false);
    }
    fetchCourse();
  }, [courseId]);

  const handleEnroll = () => {
    setEnrolled(true);
  };

  const handleCompleteLesson = (lessonId: string) => {
    setCompletedLessons((prev) => ({ ...prev, [lessonId]: true }));
  };

  if (loading) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-obsidian text-white">
        <p className="text-sm text-white/50 animate-pulse">Loading LMS Learning Portal...</p>
      </div>
    );
  }

  if (!course) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-obsidian text-white">
        <p className="text-sm text-red-400">Course not found or unavailable.</p>
      </div>
    );
  }

  const totalLessons = course.modules?.reduce((acc: number, m: any) => acc + (m.lessons?.length || 0), 0) || 0;
  const completedCount = Object.keys(completedLessons).length;
  const progressPercent = totalLessons > 0 ? Math.round((completedCount / totalLessons) * 100) : 0;

  return (
    <div className="min-h-screen bg-obsidian text-white antialiased">
      {/* Header Bar */}
      <header className="border-b border-white/10 bg-white/[0.02] px-6 py-4 backdrop-blur-md">
        <div className="mx-auto flex max-w-7xl items-center justify-between">
          <div className="flex items-center space-x-3">
            <span className="rounded-lg bg-accentBlue/20 px-3 py-1 text-xs font-bold text-accentCyan border border-accentCyan/30">
              🎓 LMS LEARNING HUB
            </span>
            <h1 className="text-lg font-bold text-white">{course.title}</h1>
          </div>
          <div className="flex items-center space-x-4">
            <span className="text-xs text-white/60">Organization: <strong className="text-accentCyan">{course.company}</strong></span>
            {!enrolled ? (
              <button
                onClick={handleEnroll}
                className="rounded-lg bg-gradient-to-r from-accentBlue to-accentCyan px-4 py-2 text-xs font-bold text-white shadow-lg transition-all hover:opacity-90"
              >
                Enroll in Course
              </button>
            ) : (
              <span className="rounded-lg bg-emerald-500/20 px-3 py-1.5 text-xs font-bold text-emerald-400 border border-emerald-500/30">
                ✓ Enrolled Student
              </span>
            )}
          </div>
        </div>
      </header>

      {/* Main Content Layout */}
      <div className="mx-auto max-w-7xl p-6">
        {/* Progress Bar */}
        <div className="mb-6 rounded-xl border border-white/10 bg-white/[0.02] p-4 backdrop-blur-md">
          <div className="flex items-center justify-between text-xs font-semibold">
            <span className="text-white/70">Overall Learning Completion</span>
            <span className="text-accentCyan">{progressPercent}% ({completedCount} / {totalLessons} Lessons)</span>
          </div>
          <div className="mt-2 h-2.5 w-full overflow-hidden rounded-full bg-white/10">
            <div
              className="h-full bg-gradient-to-r from-accentBlue to-accentCyan transition-all duration-500"
              style={{ width: `${progressPercent}%` }}
            />
          </div>
        </div>

        <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
          {/* Left / Main Screen: Lesson Content Player */}
          <div className="space-y-6 lg:col-span-2">
            <div className="overflow-hidden rounded-2xl border border-white/10 bg-black/60 shadow-2xl">
              {selectedLesson?.contentType === "VIDEO" || selectedLesson?.videoUrl ? (
                <div className="aspect-video w-full bg-black flex flex-col items-center justify-center p-6">
                  <div className="mb-4 text-5xl">▶️</div>
                  <h3 className="mb-2 text-base font-bold text-white">{selectedLesson?.title}</h3>
                  <a
                    href={selectedLesson?.videoUrl || "#"}
                    target="_blank"
                    rel="noreferrer"
                    className="rounded-lg bg-accentBlue px-4 py-2 text-xs font-bold text-white hover:bg-accentBlue/80"
                  >
                    Stream Video Lesson ↗
                  </a>
                </div>
              ) : selectedLesson?.contentType === "PDF" || selectedLesson?.pdfUrl ? (
                <div className="p-8 text-center">
                  <div className="mb-3 text-4xl">📄</div>
                  <h3 className="mb-2 text-base font-bold text-white">{selectedLesson?.title}</h3>
                  <a
                    href={selectedLesson?.pdfUrl || "#"}
                    target="_blank"
                    rel="noreferrer"
                    className="inline-block rounded-lg bg-red-500/20 border border-red-500/30 px-4 py-2 text-xs font-bold text-red-300 hover:bg-red-500/30"
                  >
                    View PDF Handout Notes ↗
                  </a>
                </div>
              ) : (
                <div className="p-8">
                  <h3 className="text-lg font-bold text-white">{selectedLesson?.title || "Welcome to the Course"}</h3>
                  <p className="mt-2 text-xs text-white/70 leading-relaxed">
                    {selectedLesson?.description || "Select a lesson from the module syllabus on the right to start learning."}
                  </p>
                </div>
              )}
            </div>

            {/* Lesson Details & Actions */}
            {selectedLesson && (
              <div className="rounded-2xl border border-white/10 bg-white/[0.02] p-6 backdrop-blur-md">
                <div className="flex items-center justify-between">
                  <div>
                    <h2 className="text-base font-bold text-white">{selectedLesson.title}</h2>
                    <p className="mt-1 text-xs text-white/50">{selectedLesson.contentType} • Duration: {selectedLesson.duration || "15 mins"}</p>
                  </div>
                  <button
                    onClick={() => handleCompleteLesson(selectedLesson.id)}
                    disabled={completedLessons[selectedLesson.id]}
                    className={`rounded-lg px-4 py-2 text-xs font-bold transition-all ${
                      completedLessons[selectedLesson.id]
                        ? "bg-emerald-500/20 text-emerald-400 border border-emerald-500/30 cursor-default"
                        : "bg-accentCyan text-black hover:opacity-90"
                    }`}
                  >
                    {completedLessons[selectedLesson.id] ? "Completed ✓" : "Mark Complete"}
                  </button>
                </div>
                {selectedLesson.description && (
                  <div className="mt-4 border-t border-white/10 pt-4 text-xs text-white/70">
                    {selectedLesson.description}
                  </div>
                )}
              </div>
            )}
          </div>

          {/* Right Sidebar: Module & Lesson Syllabus Accordion */}
          <div className="space-y-4">
            <h3 className="text-sm font-bold text-white">Course Modules & Lessons</h3>
            {course.modules?.map((m: any, mi: number) => (
              <div key={m.id || mi} className="rounded-xl border border-white/10 bg-white/[0.02] overflow-hidden">
                <div className="border-b border-white/10 bg-white/5 px-4 py-3 font-semibold text-xs text-accentCyan">
                  {m.title}
                </div>
                <div className="divide-y divide-white/5">
                  {m.lessons?.map((l: any, li: number) => {
                    const isSelected = selectedLesson?.id === l.id;
                    const isDone = completedLessons[l.id];
                    return (
                      <button
                        key={l.id || li}
                        onClick={() => setSelectedLesson(l)}
                        className={`w-full text-left px-4 py-3 text-xs flex items-center justify-between transition-colors ${
                          isSelected ? "bg-accentBlue/20 text-white font-bold border-l-2 border-accentCyan" : "text-white/70 hover:bg-white/5"
                        }`}
                      >
                        <div className="flex items-center space-x-2">
                          <span>{isDone ? "✅" : "▶️"}</span>
                          <span>{l.title}</span>
                        </div>
                        <span className="text-[10px] text-white/40">{l.duration || "15m"}</span>
                      </button>
                    );
                  })}
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
