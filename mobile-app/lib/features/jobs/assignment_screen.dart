import 'package:flutter/material.dart';
import '../../core/colors.dart';

class AssignmentScreen extends StatefulWidget {
  const AssignmentScreen({super.key});

  @override
  State<AssignmentScreen> createState() => _AssignmentScreenState();
}

class _AssignmentScreenState extends State<AssignmentScreen> {
  final _repoCtrl = TextEditingController();
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyVaultColors.obsidian,
      appBar: AppBar(
        backgroundColor: MyVaultColors.obsidian,
        elevation: 0,
        title: const Text('Practical Assignment', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Assignment 01: Flutter Dashboard App', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Instructions:\n• Create a responsive Flutter UI with GoRouter & REST API integration\n• Push code to GitHub repository\n• Attach S3 screenshots or repo link below', style: TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.5)),
            const SizedBox(height: 20),

            if (_submitted) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C48C).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00C48C).withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Color(0xFF00C48C)),
                    SizedBox(width: 10),
                    Expanded(child: Text('Assignment Submitted & Verified (PASSED)', style: TextStyle(color: Color(0xFF00C48C), fontWeight: FontWeight.bold, fontSize: 13))),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            TextField(
              controller: _repoCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'GitHub Repository URL / S3 File Link',
                labelStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: MyVaultColors.glassFill,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_repoCtrl.text.trim().isEmpty) return;
                  setState(() => _submitted = true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Assignment submitted successfully!')),
                  );
                },
                icon: const Icon(Icons.cloud_upload_rounded, color: Colors.white),
                label: const Text('SUBMIT ASSIGNMENT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyVaultColors.accentBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
