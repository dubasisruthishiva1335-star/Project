import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/colors.dart';
import 'quiz_screen.dart';
import 'assignment_screen.dart';
import 'final_exam_screen.dart';

class CourseLearningScreen extends StatefulWidget {
  final Map<String, dynamic> course;

  const CourseLearningScreen({super.key, required this.course});

  @override
  State<CourseLearningScreen> createState() => _CourseLearningScreenState();
}

class _CourseLearningScreenState extends State<CourseLearningScreen> {
  int _currentLessonIndex = 0;

  final List<Map<String, String>> _lessons = [
    {
      'title': '01. Flutter Architecture & Dart Intro',
      'duration': '25:00',
      'videoUrl': 'https://myvault-files-app.s3.eu-north-1.amazonaws.com/app-arm64-v8a-release.apk',
      'pdfUrl': 'https://myvault-files-app.s3.eu-north-1.amazonaws.com/app-arm64-v8a-release.apk',
      'notes': 'Learn the core Dart language features, object-oriented concepts, and Flutter widget tree mechanics.',
    },
    {
      'title': '02. Widgets, Layouts & Material 3 UI',
      'duration': '32:15',
      'videoUrl': 'https://myvault-files-app.s3.eu-north-1.amazonaws.com/app-arm64-v8a-release.apk',
      'pdfUrl': 'https://myvault-files-app.s3.eu-north-1.amazonaws.com/app-arm64-v8a-release.apk',
      'notes': 'Build clean responsive layouts with Row, Column, Container, ListView, and custom Glassmorphic designs.',
    },
    {
      'title': '03. Dio REST APIs & State Management',
      'duration': '40:10',
      'videoUrl': 'https://myvault-files-app.s3.eu-north-1.amazonaws.com/app-arm64-v8a-release.apk',
      'pdfUrl': 'https://myvault-files-app.s3.eu-north-1.amazonaws.com/app-arm64-v8a-release.apk',
      'notes': 'Connect Flutter to Node.js backend endpoints, parse JSON payloads, and manage app state cleanly.',
    },
    {
      'title': '04. AWS S3 Direct Upload Integration',
      'duration': '35:00',
      'videoUrl': 'https://myvault-files-app.s3.eu-north-1.amazonaws.com/app-arm64-v8a-release.apk',
      'pdfUrl': 'https://myvault-files-app.s3.eu-north-1.amazonaws.com/app-arm64-v8a-release.apk',
      'notes': 'Generate pre-signed S3 URLs and perform direct multipart S3 uploads directly from the mobile app.',
    },
  ];

  void _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lesson = _lessons[_currentLessonIndex];
    final progress = (_currentLessonIndex + 1) / _lessons.length;

    return Scaffold(
      backgroundColor: MyVaultColors.obsidian,
      appBar: AppBar(
        backgroundColor: MyVaultColors.obsidian,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.course['title'] ?? 'Course Learning',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
            ),
            Text(
              'Lesson ${_currentLessonIndex + 1} of ${_lessons.length}',
              style: const TextStyle(color: MyVaultColors.accentCyan, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Lesson Progress Indicator Bar
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white12,
            valueColor: const AlwaysStoppedAnimation<Color>(MyVaultColors.accentCyan),
            minHeight: 4,
          ),

          // Video Stream Player Shell
          Container(
            width: double.infinity,
            height: 210,
            color: Colors.black,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [MyVaultColors.accentBlue.withValues(alpha: 0.4), Colors.black],
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      iconSize: 54,
                      icon: const Icon(Icons.play_circle_fill_rounded, color: MyVaultColors.accentCyan),
                      onPressed: () => _openUrl(lesson['videoUrl']!),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Stream Lesson Video (S3 MP4)',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lesson['title']!, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Duration: ${lesson['duration']}', style: const TextStyle(color: MyVaultColors.accentCyan, fontSize: 11.5, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),

                  Text(lesson['notes']!, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
                  const SizedBox(height: 16),

                  // Resource Action Buttons (Download Notes & Quiz)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _openUrl(lesson['pdfUrl']!),
                          icon: const Icon(Icons.download_rounded, color: MyVaultColors.accentCyan, size: 16),
                          label: const Text('Download Notes', style: TextStyle(color: MyVaultColors.accentCyan, fontSize: 12, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: MyVaultColors.accentCyan),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const QuizScreen()));
                          },
                          icon: const Icon(Icons.quiz_rounded, color: Colors.white, size: 16),
                          label: const Text('Take Quiz', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MyVaultColors.accentBlue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Course Next Steps Cards
                  const Text('Course Next Milestones', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  _milestoneTile(
                    icon: Icons.assignment_turned_in_rounded,
                    title: 'Practical Project Assignment',
                    subtitle: 'Submit code repo & screenshots',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AssignmentScreen()));
                    },
                  ),
                  _milestoneTile(
                    icon: Icons.workspace_premium_rounded,
                    title: 'Final Certification Exam',
                    subtitle: 'Pass 70%+ score to earn certificate',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const FinalExamScreen()));
                    },
                  ),
                ],
              ),
            ),
          ),

          // Bottom Lesson Navigation Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: MyVaultColors.obsidian,
              border: Border(top: BorderSide(color: MyVaultColors.glassBorder)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _currentLessonIndex > 0
                      ? () => setState(() => _currentLessonIndex--)
                      : null,
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                ),
                Text('Lesson ${_currentLessonIndex + 1} / ${_lessons.length}', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: _currentLessonIndex < _lessons.length - 1
                      ? () => setState(() => _currentLessonIndex++)
                      : () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const FinalExamScreen()));
                        },
                  icon: const Icon(Icons.arrow_forward_rounded, color: MyVaultColors.accentCyan),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _milestoneTile({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: MyVaultColors.glassFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MyVaultColors.glassBorder),
      ),
      child: ListTile(
        leading: Icon(icon, color: MyVaultColors.accentCyan),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
        onTap: onTap,
      ),
    );
  }
}
