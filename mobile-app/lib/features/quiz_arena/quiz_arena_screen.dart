import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/colors.dart';
import 'quiz_service.dart';

class QuizArenaScreen extends StatefulWidget {
  const QuizArenaScreen({super.key});

  @override
  State<QuizArenaScreen> createState() => _QuizArenaScreenState();
}

class _QuizArenaScreenState extends State<QuizArenaScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = QuizService.instance;

  int _currentQuestionIndex = 0;
  int? _selectedOptionIndex;
  bool _isAnswerSubmitted = false;
  int _score = 0;
  int _streak = 0;
  int _secondsLeft = 30;
  Timer? _countdownTimer;
  bool _quizCompleted = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _startTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    _secondsLeft = 30;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft > 0) {
        if (mounted) setState(() => _secondsLeft--);
      } else {
        _handleTimeUp();
      }
    });
  }

  void _handleTimeUp() {
    _countdownTimer?.cancel();
    if (!_isAnswerSubmitted) {
      setState(() {
        _isAnswerSubmitted = true;
        _streak = 0;
      });
    }
  }

  void _selectOption(int index) {
    if (_isAnswerSubmitted) return;
    setState(() => _selectedOptionIndex = index);
  }

  void _submitAnswer() {
    if (_selectedOptionIndex == null || _isAnswerSubmitted) return;
    _countdownTimer?.cancel();

    final q = _service.questions[_currentQuestionIndex];
    final isCorrect = _selectedOptionIndex == q.correctIndex;

    setState(() {
      _isAnswerSubmitted = true;
      if (isCorrect) {
        _score += 100 + (_secondsLeft * 5) + (_streak * 20);
        _streak++;
      } else {
        _streak = 0;
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _service.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedOptionIndex = null;
        _isAnswerSubmitted = false;
      });
      _startTimer();
    } else {
      setState(() => _quizCompleted = true);
    }
  }

  void _restartQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _selectedOptionIndex = null;
      _isAnswerSubmitted = false;
      _score = 0;
      _streak = 0;
      _quizCompleted = false;
    });
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) context.go('/home');
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => context.go('/home'),
          ),
          title: const Text('🏆 Quiz Arena & Live Ranks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF06B6D4),
            labelColor: const Color(0xFF06B6D4),
            unselectedLabelColor: const Color(0xFF94A3B8),
            tabs: const [
              Tab(icon: Icon(Icons.timer_rounded, size: 18), text: 'Live Timed Quiz'),
              Tab(icon: Icon(Icons.leaderboard_rounded, size: 18), text: 'Top Leaderboard'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildQuizTab(),
            _buildLeaderboardTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizTab() {
    if (_quizCompleted) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 18),
              const Text('Quiz Completed!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
              const SizedBox(height: 8),
              Text('Your Final Score: $_score pts', style: const TextStyle(fontSize: 18, color: Color(0xFF06B6D4), fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _restartQuiz,
                icon: const Icon(Icons.replay_rounded, color: Colors.white),
                label: const Text('Play Again', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyVaultColors.metalBlack,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final q = _service.questions[_currentQuestionIndex];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Score & Timer Bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 20),
                const SizedBox(width: 4),
                Text('Streak: $_streak', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _secondsLeft <= 5 ? Colors.redAccent.withValues(alpha: 0.15) : const Color(0xFF06B6D4).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer_outlined, color: _secondsLeft <= 5 ? Colors.redAccent : const Color(0xFF06B6D4), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${_secondsLeft}s',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: _secondsLeft <= 5 ? Colors.redAccent : const Color(0xFF06B6D4),
                    ),
                  ),
                ],
              ),
            ),
            Text('Score: $_score pts', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF10B981))),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _service.questions.length,
            color: const Color(0xFF06B6D4),
            backgroundColor: const Color(0xFFE2E8F0),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 16),

        // Question Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF06B6D4).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(q.topic, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF06B6D4))),
                  ),
                  Text('Question ${_currentQuestionIndex + 1} of ${_service.questions.length}', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                q.question,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, height: 1.3),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Options List
        ...List.generate(q.options.length, (index) {
          final opt = q.options[index];
          final isSelected = _selectedOptionIndex == index;
          final isCorrect = q.correctIndex == index;

          Color border = const Color(0xFFE2E8F0);
          Color bg = Theme.of(context).cardColor;

          if (_isAnswerSubmitted) {
            if (isCorrect) {
              border = const Color(0xFF10B981);
              bg = const Color(0xFF10B981).withValues(alpha: 0.1);
            } else if (isSelected) {
              border = Colors.redAccent;
              bg = Colors.redAccent.withValues(alpha: 0.1);
            }
          } else if (isSelected) {
            border = const Color(0xFF06B6D4);
            bg = const Color(0xFF06B6D4).withValues(alpha: 0.08);
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border, width: isSelected || (_isAnswerSubmitted && isCorrect) ? 2 : 1),
            ),
            child: ListTile(
              onTap: () => _selectOption(index),
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: border.withValues(alpha: 0.2),
                child: Text(
                  String.fromCharCode(65 + index),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: border == const Color(0xFFE2E8F0) ? const Color(0xFF64748B) : border),
                ),
              ),
              title: Text(opt, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          );
        }),

        const SizedBox(height: 12),

        // Explanation if submitted
        if (_isAnswerSubmitted)
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF06B6D4).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF06B6D4), size: 16),
                    SizedBox(width: 6),
                    Text('Explanation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF06B6D4))),
                  ],
                ),
                const SizedBox(height: 4),
                Text(q.explanation, style: const TextStyle(fontSize: 12, height: 1.3)),
              ],
            ),
          ),

        // Action Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: !_isAnswerSubmitted
                ? (_selectedOptionIndex != null ? _submitAnswer : null)
                : _nextQuestion,
            style: ElevatedButton.styleFrom(
              backgroundColor: MyVaultColors.metalBlack,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              !_isAnswerSubmitted ? 'Submit Answer' : (_currentQuestionIndex < _service.questions.length - 1 ? 'Next Question →' : 'View Results 🏆'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _service.leaderboard.length,
      itemBuilder: (ctx, i) {
        final rank = _service.leaderboard[i];
        final isTop3 = rank.rank <= 3;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: rank.rank == 3 ? const Color(0xFF06B6D4).withValues(alpha: 0.08) : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: rank.rank == 3 ? const Color(0xFF06B6D4) : const Color(0xFFE2E8F0)),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isTop3
                  ? (rank.rank == 1 ? Colors.amber : (rank.rank == 2 ? const Color(0xFF94A3B8) : const Color(0xFFCD7F32)))
                  : const Color(0xFFF1F5F9),
              foregroundColor: isTop3 ? Colors.white : const Color(0xFF0F172A),
              child: Text('#${rank.rank}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            title: Text(rank.studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text(rank.college, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${rank.score} pts', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981), fontSize: 13)),
                Text('🔥 ${rank.streakDays}d streak', style: const TextStyle(fontSize: 10, color: Colors.orange)),
              ],
            ),
          ),
        );
      },
    );
  }
}
