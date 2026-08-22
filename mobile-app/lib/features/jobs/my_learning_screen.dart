import 'package:flutter/material.dart';
import '../../core/colors.dart';
import 'course_details_screen.dart';

class MyLearningScreen extends StatelessWidget {
  const MyLearningScreen({super.key});

  final List<Map<String, dynamic>> _enrolled = const [
    {
      'id': 'course_flutter_dev',
      'title': 'Flutter Mobile App Development',
      'category': 'Mobile',
      'progress': 0.72,
      'completed': 4,
      'total': 6,
      'level': 'Beginner to Advanced',
      'duration': '8 Hours',
      'lessonsCount': 6,
      'description': 'Build real-world Android and iOS apps from scratch using Flutter and Dart.',
    },
    {
      'id': 'course_python_ai',
      'title': 'Python AI & Machine Learning Foundations',
      'category': 'AI',
      'progress': 0.35,
      'completed': 3,
      'total': 8,
      'level': 'Beginner',
      'duration': '10 Hours',
      'lessonsCount': 8,
      'description': 'Learn Python, NumPy, Pandas, and build intelligent machine learning models.',
    },
  ];

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
        title: const Text('My Enrolled Courses', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _enrolled.length,
        itemBuilder: (ctx, i) {
          final item = _enrolled[i];
          final progressPercent = (item['progress'] as double) * 100;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MyVaultColors.glassFill,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: MyVaultColors.glassBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item['category'].toString().toUpperCase(), style: const TextStyle(color: MyVaultColors.accentCyan, fontSize: 11, fontWeight: FontWeight.bold)),
                    Text('${progressPercent.toInt()}% Completed', style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),

                Text(item['title'], style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: item['progress'],
                    minHeight: 6,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation<Color>(MyVaultColors.accentCyan),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${item['completed']} / ${item['total']} lessons completed', style: const TextStyle(color: Colors.white54, fontSize: 11.5)),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => CourseDetailsScreen(course: item)));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MyVaultColors.accentBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      child: const Text('Continue ➔', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
