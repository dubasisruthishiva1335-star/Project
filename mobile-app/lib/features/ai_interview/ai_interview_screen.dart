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
  final _service = AiInterviewService();
  final _answerController = TextEditingController();

  InterviewMode _mode = InterviewMode.technical;
  InterviewQuestion? _question;
  InterviewFeedback? _feedback;

  bool _loadingQuestion = false;
  bool _loadingFeedback = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQuestion();
  }

  Future<void> _loadQuestion() async {
    setState(() {
      _loadingQuestion = true;
      _feedback = null;
      _error = null;
      _answerController.clear();
    });
    try {
      final q = await _service.fetchQuestion(mode: _mode);
      setState(() => _question = q);
    } catch (e) {
      setState(() => _error = 'Could not load a question. Check your backend connection.');
    } finally {
      setState(() => _loadingQuestion = false);
    }
  }

  Future<void> _submitAnswer() async {
    if (_question == null || _answerController.text.trim().isEmpty) return;
    setState(() {
      _loadingFeedback = true;
      _error = null;
    });
    try {
      final fb = await _service.submitAnswer(
        question: _question!.question,
        answer: _answerController.text.trim(),
        mode: _mode,
      );
      setState(() => _feedback = fb);
    } catch (e) {
      setState(() => _error = 'Could not score your answer. Try again.');
    } finally {
      setState(() => _loadingFeedback = false);
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 8) return const Color(0xFF00C48C);
    if (score >= 6) return MyVaultColors.accentCyan;
    if (score >= 4) return const Color(0xFFFFB800);
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) context.go('/aptitude');
      },
      child: Scaffold(
        backgroundColor: MyVaultColors.obsidian,
        appBar: AppBar(
          backgroundColor: MyVaultColors.obsidian,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
            onPressed: () => context.go('/aptitude'),
          ),
          title: ShaderMask(
            shaderCallback: (b) => MyVaultColors.accentGradient.createShader(b),
            child: const Text(
              'AI Interview & Aptitude Coach',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildModeSelector(),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_loadingQuestion)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(color: MyVaultColors.accentCyan),
                            ),
                          )
                        else if (_question != null)
                          _buildQuestionCard(_question!),
                        const SizedBox(height: 16),
                        if (_question != null) ...[
                          TextField(
                            controller: _answerController,
                            maxLines: 5,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              labelText: 'Type your answer here...',
                              labelStyle: const TextStyle(color: Colors.white54),
                              alignLabelWithHint: true,
                              filled: true,
                              fillColor: MyVaultColors.glassFill,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: MyVaultColors.glassBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: MyVaultColors.accentCyan),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: ElevatedButton.icon(
                                  onPressed: _loadingFeedback ? null : _submitAnswer,
                                  icon: _loadingFeedback
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Icon(Icons.auto_awesome_rounded, size: 18),
                                  label: Text(_loadingFeedback ? 'Scoring...' : 'Get AI Feedback'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: MyVaultColors.accentBlue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: OutlinedButton.icon(
                                  onPressed: _loadingQuestion ? null : _loadQuestion,
                                  icon: const Icon(Icons.navigate_next_rounded, size: 20),
                                  label: const Text('Next Q'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: MyVaultColors.accentCyan,
                                    side: BorderSide(color: MyVaultColors.accentCyan.withValues(alpha: 0.5)),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(_error!, style: const TextStyle(color: Colors.orangeAccent, fontSize: 13)),
                        ],
                        if (_feedback != null) ...[
                          const SizedBox(height: 20),
                          _buildFeedbackCard(_feedback!),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: MyVaultColors.glassFill,
        border: Border.all(color: MyVaultColors.glassBorder),
      ),
      child: Row(
        children: [
          _buildModeTab('Technical', InterviewMode.technical, Icons.code_rounded),
          _buildModeTab('HR', InterviewMode.hr, Icons.groups_rounded),
          _buildModeTab('Aptitude', InterviewMode.aptitude, Icons.psychology_rounded),
        ],
      ),
    );
  }

  Widget _buildModeTab(String label, InterviewMode mode, IconData icon) {
    final selected = _mode == mode;
    return Expanded(
      child: InkWell(
        onTap: () {
          if (_mode != mode) {
            setState(() => _mode = mode);
            _loadQuestion();
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: selected ? MyVaultColors.accentBlue : Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: selected ? Colors.white : Colors.white60),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white60,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(InterviewQuestion q) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: MyVaultColors.glassFill,
        border: Border.all(color: MyVaultColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: MyVaultColors.accentBlue.withValues(alpha: 0.2),
                ),
                child: Text(
                  q.type.toUpperCase(),
                  style: const TextStyle(color: MyVaultColors.accentCyan, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            q.question,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, height: 1.4),
          ),
          if (q.hint.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white.withValues(alpha: 0.03),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline_rounded, color: Colors.amberAccent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hint: ${q.hint}',
                      style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(InterviewFeedback f) {
    final scoreColor = _getScoreColor(f.score);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: MyVaultColors.glassFill,
        border: Border.all(color: scoreColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stars_rounded, color: MyVaultColors.accentCyan, size: 24),
              const SizedBox(width: 8),
              const Text('AI Evaluation Score:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: scoreColor.withValues(alpha: 0.2),
                  border: Border.all(color: scoreColor),
                ),
                child: Text(
                  '${f.score} / 10',
                  style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Key Strengths', style: TextStyle(color: Color(0xFF00C48C), fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          ...f.strengths.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('✔ ', style: TextStyle(color: Color(0xFF00C48C))),
                    Expanded(child: Text(s, style: const TextStyle(color: Colors.white70, fontSize: 13))),
                  ],
                ),
              )),
          const SizedBox(height: 14),
          const Text('Areas for Improvement', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          ...f.improvements.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡 ', style: TextStyle(color: Colors.orangeAccent)),
                    Expanded(child: Text(s, style: const TextStyle(color: Colors.white70, fontSize: 13))),
                  ],
                ),
              )),
          if (f.modelAnswerSummary.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text('Model Answer Summary', style: TextStyle(color: MyVaultColors.accentCyan, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: MyVaultColors.accentBlue.withValues(alpha: 0.15),
              ),
              child: Text(
                f.modelAnswerSummary,
                style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.4),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }
}
