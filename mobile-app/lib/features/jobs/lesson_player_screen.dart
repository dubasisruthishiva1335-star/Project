import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/colors.dart';
import '../../core/api_client.dart';

class LessonPlayerScreen extends StatefulWidget {
  final String internshipId;
  final String lessonId;
  final Map<String, dynamic>? lessonData;

  const LessonPlayerScreen({
    super.key,
    required this.internshipId,
    required this.lessonId,
    this.lessonData,
  });

  @override
  State<LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends State<LessonPlayerScreen> {
  bool _completing = false;
  bool _isCompleted = false;
  String? _certificateUrl;
  final TextEditingController _submissionController = TextEditingController();
  int _selectedQuizAnswer = -1;

  @override
  void initState() {
    super.initState();
    _isCompleted = widget.lessonData?['isCompleted'] == true;
  }

  @override
  void dispose() {
    _submissionController.dispose();
    super.dispose();
  }

  Future<void> _completeLesson() async {
    setState(() => _completing = true);
    try {
      final res = await ApiClient.instance.dio.post(
        '/internships/lessons/${widget.lessonId}/complete',
        data: {
          'internshipId': widget.internshipId,
          'submissionText': _submissionController.text.trim(),
        },
      );
      if (mounted) {
        setState(() {
          _isCompleted = true;
          _completing = false;
          if (res.data['certificateIssued'] == true) {
            _certificateUrl = res.data['certUrl'];
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _certificateUrl != null
                  ? '🎉 Course Completed! Certificate Issued.'
                  : '✅ Lesson marked as completed!',
            ),
            backgroundColor: Colors.emerald,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _completing = false);
      }
    }
  }

  Future<void> _openUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.lessonData?['title'] ?? 'Lesson Viewer';
    final type = widget.lessonData?['contentType'] ?? 'VIDEO';
    final videoUrl = widget.lessonData?['videoUrl'];
    final pdfUrl = widget.lessonData?['pdfUrl'];
    final description = widget.lessonData?['description'] ?? '';

    return Scaffold(
      backgroundColor: MyVaultColors.obsidian,
      appBar: AppBar(
        backgroundColor: MyVaultColors.obsidian,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
          onPressed: () => context.pop(),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Media Player / Content Area
            if (type == 'VIDEO' && videoUrl != null)
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.black,
                  border: Border.all(color: MyVaultColors.accentCyan.withOpacity(0.3)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_circle_fill_rounded, color: MyVaultColors.accentCyan, size: 64),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _openUrl(videoUrl),
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: const Text('Stream Video Lesson ↗'),
                      style: ElevatedButton.styleFrom(backgroundColor: MyVaultColors.accentBlue),
                    ),
                  ],
                ),
              )
            else if (type == 'PDF' && pdfUrl != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: MyVaultColors.glassFill,
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 40),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          const Text('PDF Lesson Handout', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _openUrl(pdfUrl),
                      style: ElevatedButton.styleFrom(backgroundColor: MyVaultColors.accentBlue),
                      child: const Text('Open PDF ↗', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              )
            else if (type == 'QUIZ')
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: MyVaultColors.glassFill,
                  border: Border.all(color: MyVaultColors.accentCyan.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Module Assessment Quiz', style: TextStyle(color: MyVaultColors.accentCyan, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    const Text('Q1. Which state management solution is native to Flutter?', style: TextStyle(color: Colors.white, fontSize: 14)),
                    const SizedBox(height: 10),
                    ...['Provider / Riverpod', 'setState / InheritedWidget', 'Redux', 'MobX'].asMap().entries.map((entry) {
                      return RadioListTile<int>(
                        value: entry.key,
                        groupValue: _selectedQuizAnswer,
                        onChanged: (val) => setState(() => _selectedQuizAnswer = val!),
                        title: Text(entry.value, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        activeColor: MyVaultColors.accentCyan,
                      );
                    }),
                  ],
                ),
              )
            else if (type == 'ASSIGNMENT' || type == 'PROJECT')
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: MyVaultColors.glassFill,
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$type Submission', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    const Text('Paste your GitHub repository or S3 submission URL below:', style: TextStyle(color: Colors.white60, fontSize: 12)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _submissionController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'https://github.com/username/project-repo',
                        hintStyle: const TextStyle(color: Colors.white30),
                        filled: true,
                        fillColor: Colors.black46,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ),
              ),

            if (description.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('Lesson Overview', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(description, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
            ],

            const SizedBox(height: 32),

            // Certificate Banner
            if (_certificateUrl != null)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.amber.withOpacity(0.15),
                  border: Border.all(color: Colors.amber.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Course Completed! 🏆', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 15)),
                          Text('Verified Certificate is issued.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _openUrl(_certificateUrl),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                      child: const Text('View PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ),

            // Completion Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isCompleted || _completing ? null : _completeLesson,
                icon: Icon(_isCompleted ? Icons.check_circle_rounded : Icons.task_alt_rounded, color: Colors.white),
                label: Text(
                  _isCompleted
                      ? 'Completed ✓'
                      : _completing
                          ? 'Saving...'
                          : 'Mark Lesson as Completed',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isCompleted ? const Color(0xFF00E676) : MyVaultColors.accentCyan,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
