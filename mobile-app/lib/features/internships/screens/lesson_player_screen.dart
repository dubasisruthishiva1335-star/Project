import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/colors.dart';
import '../models/internship_lms_model.dart';
import '../services/internship_lms_service.dart';

class LessonPlayerScreen extends StatefulWidget {
  const LessonPlayerScreen({super.key, required this.lesson, required this.internshipId});
  final LessonLms lesson;
  final String internshipId;

  @override
  State<LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends State<LessonPlayerScreen> {
  final _service = InternshipLmsService();
  late int _currentSeconds;
  late int _totalSeconds;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _currentSeconds = widget.lesson.userProgress.watchedSeconds;
    _totalSeconds = widget.lesson.durationSeconds > 0 ? widget.lesson.durationSeconds : 1200;

    // Simulate watching video progress every 5 seconds
    if (widget.lesson.type == 'video') {
      _progressTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (_currentSeconds < _totalSeconds) {
          setState(() => _currentSeconds += 5);
          _service.saveVideoProgress(
            lessonId: widget.lesson.id,
            watchedSeconds: _currentSeconds,
            totalSeconds: _totalSeconds,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pct = MathMinPercentage(_currentSeconds, _totalSeconds);

    return Scaffold(
      backgroundColor: MyVaultColors.obsidian,
      appBar: AppBar(
        backgroundColor: MyVaultColors.obsidian,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.lesson.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Media Display Box
          Container(
            height: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.black,
              border: Border.all(color: MyVaultColors.glassBorder),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.lesson.type == 'video' ? Icons.play_circle_fill_rounded : Icons.article_rounded,
                      size: 64,
                      color: MyVaultColors.accentCyan,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.lesson.type == 'video' ? 'Simulated Video Player' : 'Reading Document',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
                Positioned(
                  bottom: 12,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      Text('${(_currentSeconds / 60).floor()}:${(_currentSeconds % 60).toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: pct / 100,
                          backgroundColor: Colors.white24,
                          color: MyVaultColors.accentCyan,
                          minHeight: 4,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${(_totalSeconds / 60).floor()}:00', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(widget.lesson.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 8),
          Text(
            widget.lesson.description ?? 'No description provided.',
            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 24),
          if (widget.lesson.pdfUrl != null) ...[
            ElevatedButton.icon(
              onPressed: () => launchUrl(Uri.parse(widget.lesson.pdfUrl!)),
              icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
              label: const Text('Download Lesson PDF Notes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: MyVaultColors.accentBlue,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
          ],
          ElevatedButton(
            onPressed: () {
              _service.saveVideoProgress(
                lessonId: widget.lesson.id,
                watchedSeconds: _totalSeconds,
                totalSeconds: _totalSeconds,
              );
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C48C),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Mark Lesson Complete ✓', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  double MathMinPercentage(int watched, int total) {
    if (total <= 0) return 100.0;
    final res = (watched / total) * 100;
    return res > 100.0 ? 100.0 : res;
  }
}
