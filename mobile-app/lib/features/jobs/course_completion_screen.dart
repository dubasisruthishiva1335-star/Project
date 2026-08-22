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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
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

            const Text('🎉 COURSE COMPLETED!', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            Text(courseTitle, style: const TextStyle(color: MyVaultColors.accentCyan, fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 20),

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
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
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
                label: const Text('VIEW VERIFIED CERTIFICATE ➔', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyVaultColors.accentBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            const SizedBox(height: 30),
            const Divider(color: Colors.white12),
            const SizedBox(height: 16),

            // Connected Recommended Internships
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Recommended Opportunities',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 4),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Based on your completed course & verified certificate:',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
            const SizedBox(height: 14),

            _recommendedCard(
              title: courseTitle.contains('Flutter') ? 'Flutter Mobile App Intern' : 'AI Software Engineer Intern',
              company: 'Google / TechCorp Partner',
              stipend: '₹25,000 / month',
              location: 'Hyderabad / Remote',
            ),
            const SizedBox(height: 10),
            _recommendedCard(
              title: courseTitle.contains('Flutter') ? 'iOS & Android Developer Drive' : 'Machine Learning Trainee',
              company: 'TCS Innovation Labs',
              stipend: '₹20,000 / month',
              location: 'Bangalore / Hybrid',
            ),
          ],
        ),
      ),
    );
  }

  Widget _recommendedCard({required String title, required String company, required String stipend, required String location}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MyVaultColors.glassFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MyVaultColors.accentCyan.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('$company • $location', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                const SizedBox(height: 4),
                Text(stipend, style: const TextStyle(color: Color(0xFF00C48C), fontSize: 11.5, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: MyVaultColors.accentBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            child: const Text('Apply ➔', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold)),
          ),
        ],
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
