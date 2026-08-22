import 'package:flutter/material.dart';
import '../../core/colors.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _questionIndex = 0;
  int? _selectedOption;
  int _score = 0;
  bool _quizFinished = false;

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'Which widget is commonly used for a vertically scrolling list in Flutter?',
      'options': ['Column', 'Row', 'ListView', 'Stack'],
      'answer': 2,
    },
    {
      'question': 'Which package is recommended for advanced REST API network requests in Flutter?',
      'options': ['http', 'Dio', 'Fetch', 'Axios'],
      'answer': 1,
    },
    {
      'question': 'What is the primary method used to update State in a StatefulWidget?',
      'options': ['updateState()', 'refresh()', 'setState()', 'render()'],
      'answer': 2,
    },
  ];

  void _nextQuestion() {
    if (_selectedOption == null) return;
    if (_selectedOption == _questions[_questionIndex]['answer']) {
      _score++;
    }

    if (_questionIndex < _questions.length - 1) {
      setState(() {
        _questionIndex++;
        _selectedOption = null;
      });
    } else {
      setState(() => _quizFinished = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_quizFinished) {
      return Scaffold(
        backgroundColor: MyVaultColors.obsidian,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF00C48C), size: 72),
                const SizedBox(height: 16),
                const Text('Quiz Completed!', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Your Score: $_score / ${_questions.length}', style: const TextStyle(color: MyVaultColors.accentCyan, fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: MyVaultColors.accentBlue, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                  child: const Text('Back to Course ➔', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final q = _questions[_questionIndex];

    return Scaffold(
      backgroundColor: MyVaultColors.obsidian,
      appBar: AppBar(
        backgroundColor: MyVaultColors.obsidian,
        elevation: 0,
        title: Text('Lesson Quiz (${_questionIndex + 1}/${_questions.length})', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                onPressed: _selectedOption != null ? _nextQuestion : null,
                style: ElevatedButton.styleFrom(backgroundColor: MyVaultColors.accentBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: Text(_questionIndex == _questions.length - 1 ? 'Submit Quiz' : 'Next Question ➔', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
