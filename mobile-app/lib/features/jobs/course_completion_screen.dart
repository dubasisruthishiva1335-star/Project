import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../competitive_exams/exam_certificate_screen.dart';

class CourseCompletionScreen extends StatelessWidget {
  final String courseTitle;

  const CourseCompletionScreen({super.key, required this.courseTitle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyVaultColors.obsidian,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C48C).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFF00C48C), size: 72),
              ),
              const SizedBox(height: 20),

              const Text('🎉 COURSE COMPLETED!', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.black, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Text(courseTitle, style: const TextStyle(color: MyVaultColors.accentCyan, fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: MyVaultColors.glassFill,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: MyVaultColors.glassBorder),
                ),
                child: const Column(
                  children: [
                    _checkRow('All Video Lessons Completed', true),
                    _checkRow('Lesson Quizzes Passed', true),
                    _checkRow('Practical Assignment Verified', true),
                    _checkRow('Final Exam Passed (85% Score)', true),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExamCertificateScreen(
                          examName: courseTitle,
                          studentName: 'Rahul Kumar',
                          certificateNumber: 'IH-CERT-884920',
                          pdfUrl: 'https://myvault-files-app.s3.eu-north-1.amazonaws.com/app-arm64-v8a-release.apk',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.verified_rounded, color: Colors.white),
                  label: const Text('VIEW VERIFIED CERTIFICATE ➔', style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MyVaultColors.accentBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _checkRow extends StatelessWidget {
  final String label;
  final bool done;

  const _checkRow(this.label, this.done);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(done ? Icons.check_circle_rounded : Icons.radio_button_off, color: const Color(0xFF00C48C), size: 18),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
