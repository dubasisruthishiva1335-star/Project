"use client";

import { useEffect, useState } from "react";
import { apiRequest } from "../../lib/api-client";

interface Question {
  id: string;
  category: string;
  question: string;
  options: string[];
  correctOption: number;
}

const CATEGORIES = ["ALL", "quantitative", "logical", "verbal"];

export default function AptitudePage() {
  const [category, setCategory] = useState("ALL");
  const [questions, setQuestions] = useState<Question[]>([]);
  const [selectedAnswers, setSelectedAnswers] = useState<Record<string, number>>({});
  const [score, setScore] = useState<number | null>(null);
  const [loading, setLoading] = useState(true);

  const fetchQuestions = async () => {
    setLoading(true);
    try {
      const url = category === "ALL" ? "/aptitude" : `/aptitude?category=${category}`;
      const data = await apiRequest<Question[]>(url);
      setQuestions(data);
      setSelectedAnswers({});
      setScore(null);
    } catch {
      // Sample fallback questions if DB has none yet
      setQuestions([
        {
          id: "q1",
          category: "quantitative",
          question: "A train running at 60 km/hr passes a pole in 9 seconds. What is the length of the train?",
          options: ["120 metres", "180 metres", "150 metres", "324 metres"],
          correctOption: 2,
        },
        {
          id: "q2",
          category: "logical",
          question: "Look at this series: 2, 1, (1/2), (1/4), ... What number should come next?",
          options: ["(1/3)", "(1/8)", "(2/8)", "(1/16)"],
          correctOption: 1,
        },
        {
          id: "q3",
          category: "verbal",
          question: "Find the synonym of ANTAGONIST:",
          options: ["Friend", "Opponent", "Helper", "Partner"],
          correctOption: 1,
        },
      ]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchQuestions();
  }, [category]);

  const handleSelect = (qId: string, optionIdx: number) => {
    setSelectedAnswers((prev) => ({ ...prev, [qId]: optionIdx }));
  };

  const calculateScore = () => {
    let count = 0;
    questions.forEach((q) => {
      if (selectedAnswers[q.id] === q.correctOption) {
        count++;
      }
    });
    setScore(count);
  };

  return (
    <main className="mx-auto max-w-4xl px-6 py-10">
      <div className="mb-8 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-3xl font-bold">Aptitude & Placement Practice</h1>
          <p className="mt-1 text-sm text-white/50">
            Practice quantitative, logical, and verbal reasoning questions
          </p>
        </div>

        <div className="flex flex-wrap gap-1.5 rounded-2xl border border-white/10 bg-white/[0.03] p-1.5 backdrop-blur-xl">
          {CATEGORIES.map((cat) => (
            <button
              key={cat}
              onClick={() => setCategory(cat)}
              className={`rounded-xl px-3 py-1.5 text-xs font-semibold capitalize transition-all ${
                category === cat
                  ? "bg-gradient-to-r from-accentBlue to-accentCyan text-black shadow-md"
                  : "text-white/70 hover:bg-white/5 hover:text-white"
              }`}
            >
              {cat}
            </button>
          ))}
        </div>
      </div>

      {loading ? (
        <div className="flex h-64 items-center justify-center">
          <div className="h-8 w-8 animate-spin rounded-full border-2 border-accentCyan border-t-transparent"></div>
        </div>
      ) : (
        <div className="space-y-6">
          {questions.map((q, qIndex) => {
            const isSubmitted = score !== null;
            const selected = selectedAnswers[q.id];

            return (
              <div
                key={q.id}
                className="rounded-2xl border border-white/10 bg-white/[0.03] p-6 shadow-xl backdrop-blur-xl"
              >
                <div className="flex items-center justify-between">
                  <span className="rounded-md bg-accentBlue/20 px-2.5 py-1 text-[11px] font-bold uppercase tracking-wider text-accentBlue">
                    Question {qIndex + 1} • {q.category}
                  </span>
                </div>

                <h3 className="mt-3 text-base font-semibold text-white">
                  {q.question}
                </h3>

                <div className="mt-4 grid gap-2.5 sm:grid-cols-2">
                  {q.options.map((option, optIdx) => {
                    let btnStyle = "border-white/15 bg-white/5 hover:bg-white/10 text-white/80";

                    if (selected === optIdx) {
                      btnStyle = "border-accentCyan bg-accentCyan/20 text-accentCyan font-bold";
                    }

                    if (isSubmitted) {
                      if (optIdx === q.correctOption) {
                        btnStyle = "border-emerald-500 bg-emerald-500/20 text-emerald-300 font-bold";
                      } else if (selected === optIdx && selected !== q.correctOption) {
                        btnStyle = "border-red-500 bg-red-500/20 text-red-300";
                      }
                    }

                    return (
                      <button
                        key={optIdx}
                        disabled={isSubmitted}
                        onClick={() => handleSelect(q.id, optIdx)}
                        className={`flex items-center gap-3 rounded-xl border p-3 text-left text-xs transition-all ${btnStyle}`}
                      >
                        <span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full border border-current text-[11px]">
                          {String.fromCharCode(65 + optIdx)}
                        </span>
                        <span>{option}</span>
                      </button>
                    );
                  })}
                </div>
              </div>
            );
          })}

          <div className="mt-8 flex flex-col items-center justify-center gap-4 rounded-3xl border border-white/10 bg-white/[0.03] p-6 text-center backdrop-blur-xl">
            {score !== null ? (
              <div>
                <p className="text-xs uppercase tracking-wider text-white/50">Your Test Score</p>
                <p className="mt-1 text-3xl font-extrabold text-accentCyan">
                  {score} / {questions.length}
                </p>
                <button
                  onClick={() => setScore(null)}
                  className="mt-4 rounded-xl bg-white/10 px-6 py-2 text-xs font-semibold text-white hover:bg-white/20"
                >
                  Retry Practice
                </button>
              </div>
            ) : (
              <button
                onClick={calculateScore}
                disabled={Object.keys(selectedAnswers).length === 0}
                className="rounded-xl bg-gradient-to-r from-accentBlue to-accentCyan px-8 py-3 text-sm font-bold text-black shadow-lg shadow-accentBlue/20 hover:opacity-90 disabled:opacity-40"
              >
                Submit & Evaluate Answers
              </button>
            )}
          </div>
        </div>
      )}
    </main>
  );
}
