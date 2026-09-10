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
    if (score >= 8) return const Color(0xFF059669);
    if (score >= 6) return const Color(0xFF2563EB);
    if (score >= 4) return const Color(0xFFD97706);
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) context.go('/home');
      },
      child: Scaffold(
        backgroundColor: MyVaultColors.backgroundWhite,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: MyVaultColors.metalBlack, size: 20),
            onPressed: () => context.go('/home'),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: MyVaultColors.metalGradient,
                ),
                child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'AI Interview Coach',
                style: TextStyle(fontWeight: FontWeight.bold, color: MyVaultColors.metalBlack, fontSize: 17),
              ),
            ],
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: Color(0xFFE2E8F0)),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: MyVaultColors.whiteShadingGradient,
          ),
          child: SafeArea(
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
                                child: CircularProgressIndicator(color: MyVaultColors.metalBlack),
                              ),
                            )
                          else if (_question != null)
                            _buildQuestionCard(_question!),
                          const SizedBox(height: 16),
                          if (_question != null) ...[
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x06000000),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _answerController,
                                maxLines: 5,
                                style: const TextStyle(color: MyVaultColors.textDark, fontSize: 14),
                                decoration: InputDecoration(
                                  labelText: 'Type your answer here...',
                                  labelStyle: const TextStyle(color: MyVaultColors.textMuted),
                                  alignLabelWithHint: true,
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.all(16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      gradient: MyVaultColors.metalGradient,
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x18000000),
                                          blurRadius: 8,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton.icon(
                                      onPressed: _loadingFeedback ? null : _submitAnswer,
                                      icon: _loadingFeedback
                                          ? const SizedBox(
                                              height: 18,
                                              width: 18,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                            )
                                          : const Icon(Icons.auto_awesome_rounded, size: 18, color: Colors.white),
                                      label: Text(
                                        _loadingFeedback ? 'Scoring...' : 'Get AI Feedback',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        foregroundColor: Colors.white,
                                        shadowColor: Colors.transparent,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: OutlinedButton.icon(
                                    onPressed: _loadingQuestion ? null : _loadQuestion,
                                    icon: const Icon(Icons.navigate_next_rounded, size: 20, color: MyVaultColors.metalBlack),
                                    label: const Text(
                                      'Next Q',
                                      style: TextStyle(color: MyVaultColors.metalBlack, fontWeight: FontWeight.bold),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                                      backgroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
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
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFE2E8F0),
        border: Border.all(color: const Color(0xFFCBD5E1)),
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
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: selected ? MyVaultColors.metalGradient : null,
            color: selected ? null : Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: selected ? Colors.white : MyVaultColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : MyVaultColors.textSecondary,
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
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
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
                  gradient: MyVaultColors.metalGradient,
                ),
                child: Text(
                  q.type.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            q.question,
            style: const TextStyle(color: MyVaultColors.textDark, fontWeight: FontWeight.bold, fontSize: 16, height: 1.4),
          ),
          if (q.hint.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFFFFFBEB),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFD97706), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hint: ${q.hint}',
                      style: const TextStyle(color: Color(0xFF92400E), fontSize: 12, fontStyle: FontStyle.italic),
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
        color: Colors.white,
        border: Border.all(color: scoreColor.withValues(alpha: 0.4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stars_rounded, color: Color(0xFF2563EB), size: 24),
              const SizedBox(width: 8),
              const Text('AI Evaluation Score:', style: TextStyle(color: MyVaultColors.textDark, fontWeight: FontWeight.bold, fontSize: 15)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: scoreColor.withValues(alpha: 0.1),
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
          const Text('Key Strengths', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          ...f.strengths.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('✔ ', style: TextStyle(color: Color(0xFF059669))),
                    Expanded(child: Text(s, style: const TextStyle(color: MyVaultColors.textSecondary, fontSize: 13))),
                  ],
                ),
              )),
          const SizedBox(height: 14),
          const Text('Areas for Improvement', style: TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          ...f.improvements.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡 ', style: TextStyle(color: Color(0xFFD97706))),
                    Expanded(child: Text(s, style: const TextStyle(color: MyVaultColors.textSecondary, fontSize: 13))),
                  ],
                ),
              )),
          if (f.modelAnswerSummary.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text('Model Answer Summary', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color(0xFFEFF6FF),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Text(
                f.modelAnswerSummary,
                style: const TextStyle(color: MyVaultColors.textDark, fontSize: 12, height: 1.4),
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
