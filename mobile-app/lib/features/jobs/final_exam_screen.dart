import 'package:flutter/material.dart';
import '../../core/colors.dart';
import 'course_completion_screen.dart';

class FinalExamScreen extends StatefulWidget {
  const FinalExamScreen({super.key});

  @override
  State<FinalExamScreen> createState() => _FinalExamScreenState();
}

class _FinalExamScreenState extends State<FinalExamScreen> {
  int _questionIndex = 0;
  int? _selectedOption;
  int _score = 0;

  final List<Map<String, dynamic>> _examQuestions = [
    {
      'question': 'Which widget is used for state management and scoped provider injection?',
      'options': ['ProviderScope', 'Scaffold', 'Container', 'SizedBox'],
      'answer': 0,
    },
    {
      'question': 'How do you handle pre-signed direct uploads to AWS S3 in Flutter?',
      'options': ['Using PutObjectCommand or HTTP PUT with pre-signed URL', 'Using FTP', 'Using MySQL client', 'Using WebSockets'],
      'answer': 0,
    },
    {
      'question': 'What is the minimum passing score for the Industrial Internship Certificate?',
      'options': ['50%', '60%', '70%', '80%'],
      'answer': 2,
    },
  ];

  void _nextExamQuestion() {
    if (_selectedOption == null) return;
    if (_selectedOption == _examQuestions[_questionIndex]['answer']) {
      _score++;
    }

    if (_questionIndex < _examQuestions.length - 1) {
      setState(() {
        _questionIndex++;
        _selectedOption = null;
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const CourseCompletionScreen(
            courseTitle: 'Flutter Mobile App Development',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _examQuestions[_questionIndex];

    return Scaffold(
      backgroundColor: MyVaultColors.obsidian,
      appBar: AppBar(
        backgroundColor: MyVaultColors.obsidian,
        elevation: 0,
        title: Text('Final Certification Exam (${_questionIndex + 1}/${_examQuestions.length})', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_rounded, color: Colors.amber, size: 14),
                  SizedBox(width: 6),
                  Text('Time Remaining: 28:45', style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Text(q['question'] as String, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, height: 1.4)),
            const SizedBox(height: 20),

            ...(q['options'] as List<String>).asMap().entries.map((entry) {
              final idx = entry.key;
              final text = entry.value;
              final isSelected = _selectedOption == idx;

              return InkWell(
                onTap: () => setState(() => _selectedOption = idx),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected ? MyVaultColors.accentBlue.withValues(alpha: 0.2) : MyVaultColors.glassFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? MyVaultColors.accentCyan : MyVaultColors.glassBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: isSelected ? MyVaultColors.accentCyan : Colors.white38),
                      const SizedBox(width: 12),
                      Expanded(child: Text(text, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 13.5, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))),
                    ],
                  ),
                ),
              );
            }),

            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: _selectedOption != null ? _nextExamQuestion : null,
                style: ElevatedButton.styleFrom(backgroundColor: MyVaultColors.accentBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: Text(_questionIndex == _examQuestions.length - 1 ? 'SUBMIT FINAL EXAM ➔' : 'Next Question ➔', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
