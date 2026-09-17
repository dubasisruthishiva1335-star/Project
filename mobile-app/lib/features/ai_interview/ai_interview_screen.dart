import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/colors.dart';
import 'ai_interview_service.dart';

class AiInterviewScreen extends StatefulWidget {
  const AiInterviewScreen({super.key});

  @override
  State<AiInterviewScreen> createState() => _AiInterviewScreenState();
}

class _AiInterviewScreenState extends State<AiInterviewScreen> {
  final _service = EnhancedAiInterviewService();
  final _answerController = TextEditingController();

  InterviewCategory _selectedCategory = InterviewCategory.systemDesign;
  InterviewQuestion? _currentQuestion;
  RubricScore? _rubricFeedback;

  bool _loading = false;
  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _recordTimer;

  @override
  void initState() {
    super.initState();
    _fetchNextQuestion();
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _fetchNextQuestion() async {
    setState(() {
      _loading = true;
      _rubricFeedback = null;
      _answerController.clear();
      _isRecording = false;
      _recordingSeconds = 0;
    });
    _recordTimer?.cancel();

    final q = await _service.getRandomQuestion(_selectedCategory);
    if (mounted) {
      setState(() {
        _currentQuestion = q;
        _loading = false;
      });
    }
  }

  void _toggleVoiceRecording() {
    if (_isRecording) {
      _recordTimer?.cancel();
      setState(() => _isRecording = false);
      if (_answerController.text.trim().isEmpty) {
        _answerController.text =
            "I would approach this by setting up a distributed caching layer using Redis for ultra-low latency, combined with consistent hashing and database read-replicas for high availability.";
      }
    } else {
      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
      });
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (mounted) setState(() => _recordingSeconds++);
      });
    }
  }

  Future<void> _submitEvaluation() async {
    if (_currentQuestion == null || _answerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please speak or type your answer before submitting.')),
      );
      return;
    }

    setState(() => _loading = true);
    final fb = await _service.evaluateAnswer(
      question: _currentQuestion!,
      answerText: _answerController.text.trim(),
      wasVoiceRecorded: _recordingSeconds > 0,
    );

    if (mounted) {
      setState(() {
        _rubricFeedback = fb;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          title: const Text(
            'AI Voice Mock Interview',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'New Question',
              onPressed: _fetchNextQuestion,
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Category Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _categoryChip('System Design', InterviewCategory.systemDesign),
                  _categoryChip('DSA & Algorithms', InterviewCategory.dsa),
                  _categoryChip('Cloud & DevOps', InterviewCategory.cloudDevOps),
                  _categoryChip('HR & Behavioral', InterviewCategory.behavioral),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Question Card
            if (_loading && _currentQuestion == null)
              const Center(child: CircularProgressIndicator())
            else if (_currentQuestion != null)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: MyVaultColors.metalGlossGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _currentQuestion!.difficulty.toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Row(
                          children: [
                            Icon(Icons.mic_none_rounded, color: Colors.cyanAccent, size: 16),
                            SizedBox(width: 4),
                            Text('Voice Enabled', style: TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _currentQuestion!.question,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, height: 1.3),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Voice & Text Input Area
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? const Color(0xFF262D3D) : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Your Response:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      // Voice Recording Button
                      GestureDetector(
                        onTap: _toggleVoiceRecording,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isRecording ? Colors.redAccent : const Color(0xFF06B6D4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_isRecording ? Icons.stop_rounded : Icons.mic_rounded, color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                _isRecording ? 'Recording (${_recordingSeconds}s)' : 'Speak Answer',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _answerController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Type or use Voice Recording to speak your structured answer...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? const Color(0xFF262D3D) : const Color(0xFFCBD5E1)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _submitEvaluation,
                      icon: _loading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.analytics_rounded, color: Colors.white, size: 18),
                      label: Text(
                        _loading ? 'Analyzing Rubric...' : '⚡ Evaluate Response with AI Rubric',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MyVaultColors.metalBlack,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Rubric Feedback Card
            if (_rubricFeedback != null)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF10B981), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '🎓 AI Rubric Evaluation',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Score: ${_rubricFeedback!.overallScore} / 10',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981), fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _rubricScoreBar('Technical Accuracy', _rubricFeedback!.technicalAccuracy, const Color(0xFF06B6D4)),
                    const SizedBox(height: 8),
                    _rubricScoreBar('Clarity & Articulation', _rubricFeedback!.clarity, const Color(0xFF3B82F6)),
                    const SizedBox(height: 8),
                    _rubricScoreBar('Confidence & Tone', _rubricFeedback!.confidence, const Color(0xFF8B5CF6)),
                    const SizedBox(height: 16),
                    _feedbackSection('✅ Strengths', _rubricFeedback!.strengths, const Color(0xFF10B981)),
                    const SizedBox(height: 10),
                    _feedbackSection('💡 Recommended Improvements', _rubricFeedback!.improvements, const Color(0xFFF59E0B)),
                    const SizedBox(height: 10),
                    _feedbackSection('📖 Architectural Benchmark', _rubricFeedback!.modelAnswer, const Color(0xFF64748B)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _categoryChip(String label, InterviewCategory category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label, style: TextStyle(color: isSelected ? Colors.white : null, fontSize: 12, fontWeight: FontWeight.bold)),
        selectedColor: MyVaultColors.metalBlack,
        onSelected: (val) {
          setState(() => _selectedCategory = category);
          _fetchNextQuestion();
        },
      ),
    );
  }

  Widget _rubricScoreBar(String title, int score, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text('$score / 10', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: score / 10.0,
            color: color,
            backgroundColor: color.withValues(alpha: 0.15),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _feedbackSection(String title, String content, Color accent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: accent)),
          const SizedBox(height: 4),
          Text(content, style: const TextStyle(fontSize: 12, height: 1.3)),
        ],
      ),
    );
  }
}
