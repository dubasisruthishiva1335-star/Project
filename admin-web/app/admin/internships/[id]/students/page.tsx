"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";

export default function InternshipStudentsPage() {
  const params = useParams();
  const courseId = params?.id as string;

  const [students, setStudents] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!courseId) return;
    async function loadStudents() {
      try {
        const res = await fetch(`https://romantic-serenity-production-3e5b.up.railway.app/admin/internships/${courseId}/students`);
        const json = await res.json();
        setStudents(json || []);
      } catch (_) {}
      setLoading(false);
    }
    loadStudents();
  }, [courseId]);

  return (
    <div className="p-8">
      <h1 className="text-xl font-bold text-white">Enrolled Students & Progress Tracker</h1>
      <p className="mt-1 text-sm text-white/50">View real-time course progress, lesson completion counts, and student enrollments.</p>

      <div className="mt-6">
        {loading ? (
          <p className="text-xs text-white/40">Loading student roster...</p>
        ) : students.length === 0 ? (
          <p className="text-xs text-white/40">No students enrolled in this course yet.</p>
        ) : (
          <table className="w-full text-left text-xs text-white/80">
            <thead>
              <tr className="border-b border-white/10 text-white/50">
                <th className="py-2">Student ID</th>
                <th className="py-2">Enrolled Date</th>
                <th className="py-2">Completed Lessons</th>
                <th className="py-2">Progress</th>
              </tr>
            </thead>
            <tbody>
              {students.map((s) => (
                <tr key={s.enrollment_id} className="border-b border-white/5 hover:bg-white/[0.02]">
                  <td className="py-3 font-semibold text-white">{s.student_id}</td>
                  <td className="py-3 text-white/60">{new Date(s.enrolled_at).toLocaleDateString()}</td>
                  <td className="py-3 text-accentCyan">{s.completed_lessons} / {s.total_lessons}</td>
                  <td className="py-3">
                    <div className="flex items-center space-x-2">
                      <div className="h-2 w-24 rounded-full bg-white/10 overflow-hidden">
                        <div
                          className="h-full bg-accentCyan rounded-full"
                          style={{ width: `${s.progressPercentage}%` }}
                        />
                      </div>
                      <span className="font-semibold text-white">{s.progressPercentage}%</span>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
