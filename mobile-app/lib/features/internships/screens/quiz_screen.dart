import 'package:flutter/material.dart';
import '../../../core/colors.dart';
import '../models/internship_lms_model.dart';
import '../services/internship_lms_service.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.lesson});
  final LessonLms lesson;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final _service = InternshipLmsService();
  int _currentIndex = 0;
  final Map<int, int> _selectedAnswers = {};
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    final questions = widget.lesson.quizQuestions;

    if (questions.isEmpty) {
      return Scaffold(
        backgroundColor: MyVaultColors.obsidian,
        appBar: AppBar(backgroundColor: MyVaultColors.obsidian, title: const Text('Quiz')),
        body: const Center(child: Text('No quiz questions configured.', style: TextStyle(color: Colors.white54))),
      );
    }

    if (_submitted) {
      int score = 0;
      for (int i = 0; i < questions.length; i++) {
        if (_selectedAnswers[i] == questions[i].correctIndex) score++;
      }
      final percent = MathRoundScore(score, questions.length);

      return Scaffold(
        backgroundColor: MyVaultColors.obsidian,
        body: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: MyVaultColors.glassFill,
              border: Border.all(color: MyVaultColors.glassBorder),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(percent >= 70 ? Icons.check_circle_rounded : Icons.highlight_off_rounded, size: 64, color: percent >= 70 ? const Color(0xFF00C48C) : Colors.redAccent),
                const SizedBox(height: 16),
                Text(percent >= 70 ? 'Quiz Passed!' : 'Needs Review', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
                const SizedBox(height: 8),
                Text('Score: $score / ${questions.length} ($percent%)', style: const TextStyle(color: MyVaultColors.accentCyan, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    _service.saveVideoProgress(lessonId: widget.lesson.id, watchedSeconds: 300, totalSeconds: 300);
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: MyVaultColors.accentBlue, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                  child: const Text('Continue Learning', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final q = questions[_currentIndex];

    return Scaffold(
      backgroundColor: MyVaultColors.obsidian,
      appBar: AppBar(
        backgroundColor: MyVaultColors.obsidian,
        elevation: 0,
        title: Text('Question ${_currentIndex + 1} of ${questions.length}', style: const TextStyle(color: Colors.white, fontSize: 15)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(value: (_currentIndex + 1) / questions.length, backgroundColor: Colors.white10, color: MyVaultColors.accentCyan),
            const SizedBox(height: 24),
            Text(q.question, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, height: 1.4)),
            const SizedBox(height: 24),
            ...q.options.asMap().entries.map((entry) {
              final idx = entry.key;
              final optText = entry.value;
              final isSelected = _selectedAnswers[_currentIndex] == idx;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: isSelected ? MyVaultColors.accentBlue.withValues(alpha: 0.3) : MyVaultColors.glassFill,
                  border: Border.all(color: isSelected ? MyVaultColors.accentCyan : MyVaultColors.glassBorder),
                ),
                child: ListTile(
                  onTap: () => setState(() => _selectedAnswers[_currentIndex] = idx),
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: isSelected ? MyVaultColors.accentCyan : Colors.white10,
                    child: Text(String.fromCharCode(65 + idx), style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  title: Text(optText, style: const TextStyle(color: Colors.white, fontSize: 14)),
                ),
              );
            }),
            const Spacer(),
            Row(
              children: [
                if (_currentIndex > 0)
                  OutlinedButton(
                    onPressed: () => setState(() => _currentIndex--),
                    child: const Text('Previous', style: TextStyle(color: Colors.white)),
                  ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    if (_currentIndex < questions.length - 1) {
                      setState(() => _currentIndex++);
                    } else {
                      setState(() => _submitted = true);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: MyVaultColors.accentBlue),
                  child: Text(_currentIndex < questions.length - 1 ? 'Next →' : 'Submit Quiz', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int MathRoundScore(int s, int total) {
    if (total == 0) return 100;
    return ((s / total) * 100).round();
  }
}
