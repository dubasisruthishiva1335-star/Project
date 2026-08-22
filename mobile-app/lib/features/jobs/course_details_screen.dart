import 'package:flutter/material.dart';
import '../../core/colors.dart';
import 'course_learning_screen.dart';

class CourseDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> course;

  const CourseDetailsScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    final title = course['title'] ?? 'Course Details';
    final cat = course['category'] ?? 'Mobile';
    final level = course['level'] ?? 'Beginner';
    final duration = course['duration'] ?? '8 Hours';
    final lessons = course['lessonsCount'] ?? 6;
    final description = course['description'] ?? '';
    final List learnings = (course['learnings'] as List?) ?? [];

    return Scaffold(
      backgroundColor: MyVaultColors.obsidian,
      appBar: AppBar(
        backgroundColor: MyVaultColors.obsidian,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Badge Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: MyVaultColors.accentCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(cat.toUpperCase(), style: const TextStyle(color: MyVaultColors.accentCyan, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C48C).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('FREE CERTIFICATION', style: TextStyle(color: Color(0xFF00C48C), fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Text(description, style: const TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.5)),
            const SizedBox(height: 18),

            // Metadata Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _metaBox(Icons.star_rounded, level, 'Skill Level'),
                _metaBox(Icons.schedule_rounded, duration, 'Total Time'),
                _metaBox(Icons.menu_book_rounded, '$lessons Modules', 'Curriculum'),
                _metaBox(Icons.workspace_premium_rounded, 'Verified', 'S3 Certificate'),
              ],
            ),
            const SizedBox(height: 24),

            // What You'll Learn Section
            const Text("What you'll learn", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: MyVaultColors.glassFill,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: MyVaultColors.glassBorder),
              ),
              child: Column(
                children: learnings.map((l) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF00C48C), size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(l.toString(), style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Curriculum Modules Breakdown
            const Text('Course Curriculum', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            _moduleTile('01. Fundamentals & Core Concepts', '2 lessons • 55 min'),
            _moduleTile('02. UI Layouts & Navigation', '2 lessons • 1 hour'),
            _moduleTile('03. Node.js REST APIs & S3 Storage', '2 lessons • 1.5 hours'),
            _moduleTile('04. Hands-on Project & Assignment', '1 project submission'),
            _moduleTile('05. Final Certification Exam', '1 exam • 30 mins'),

            const SizedBox(height: 30),

            // Start Course Sticky CTA Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CourseLearningScreen(course: course),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                label: const Text('START COURSE NOW ➔', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyVaultColors.accentBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaBox(IconData icon, String title, String subtitle) {
    return Column(
      children: [
        Icon(icon, color: MyVaultColors.accentCyan, size: 22),
        const SizedBox(height: 6),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }

  Widget _moduleTile(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MyVaultColors.glassFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MyVaultColors.glassBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.lock_open_rounded, color: Colors.white38, size: 16),
        ],
      ),
    );
  }
}
