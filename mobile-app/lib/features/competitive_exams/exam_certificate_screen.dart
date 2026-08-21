import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/colors.dart';

class ExamCertificateScreen extends StatelessWidget {
  final String studentName;
  final String examName;
  final String certificateNumber;
  final String pdfUrl;

  const ExamCertificateScreen({
    super.key,
    required this.studentName,
    required this.examName,
    required this.certificateNumber,
    required this.pdfUrl,
  });

  Future<void> _downloadPdf() async {
    final uri = Uri.tryParse(pdfUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyVaultColors.obsidian,
      appBar: AppBar(
        backgroundColor: MyVaultColors.obsidian,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Verified Certificate',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 17),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.emoji_events_rounded, size: 80, color: Colors.amber),
            const SizedBox(height: 16),
            ShaderMask(
              shaderCallback: (b) => MyVaultColors.accentGradient.createShader(b),
              child: const Text(
                'CONGRATULATIONS!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Official Certification for $examName',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 24),

            // Certificate Preview Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: MyVaultColors.glassFill,
                border: Border.all(color: MyVaultColors.accentCyan.withValues(alpha: 0.4), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: MyVaultColors.accentBlue.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.school_rounded, color: MyVaultColors.accentCyan, size: 28),
                      Text(
                        'MYVAULT CERTIFIED',
                        style: TextStyle(
                          color: MyVaultColors.accentCyan.withValues(alpha: 0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white12, height: 28),
                  const Text(
                    'CERTIFICATE OF COMPLETION',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  const SizedBox(height: 16),
                  const Text('This certificate is proudly presented to', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 8),
                  Text(
                    studentName.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: MyVaultColors.accentCyan,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('For successfully completing the exam syllabus for', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 6),
                  Text(
                    examName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Text('Certificate ID: $certificateNumber', style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace')),
                        const SizedBox(height: 2),
                        const Text('Verification Token: S3-VERIFIED-2026', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _downloadPdf,
                icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
                label: const Text('Download Official PDF from AWS S3', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
