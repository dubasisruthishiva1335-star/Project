import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/colors.dart';

class CertificateScreen extends StatelessWidget {
  final String certificateUrl;
  final String courseTitle;

  const CertificateScreen({
    super.key,
    required this.certificateUrl,
    required this.courseTitle,
  });

  Future<void> _openCertificate() async {
    final uri = Uri.tryParse(certificateUrl);
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
          onPressed: () => context.pop(),
        ),
        title: const Text('Verified Certificate', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: MyVaultColors.glassFill,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: MyVaultColors.accentCyan.withValues(alpha: 0.35)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.workspace_premium_rounded, color: MyVaultColors.accentCyan, size: 80),
                  const SizedBox(height: 20),
                  const Text('Congratulations! 🎉', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text('You have successfully completed', style: TextStyle(color: Colors.white60, fontSize: 14)),
                  const SizedBox(height: 6),
                  Text(courseTitle, textAlign: TextAlign.center, style: const TextStyle(color: MyVaultColors.accentCyan, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  const Text('Your official industrial certificate with QR verification code is ready for view and download.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.4)),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openCertificate,
                icon: const Icon(Icons.file_download_rounded, color: Colors.white),
                label: const Text('View / Download Certificate PDF ↗', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyVaultColors.accentBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
