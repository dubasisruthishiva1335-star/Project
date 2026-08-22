import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../core/colors.dart';
import 'course_details_screen.dart';
import 'my_learning_screen.dart';
import 'job_listings_screen.dart';
import '../competitive_exams/exam_certificate_screen.dart';

class InternshipHubScreen extends StatefulWidget {
  const InternshipHubScreen({super.key});

  @override
  State<InternshipHubScreen> createState() => _InternshipHubScreenState();
}

class _InternshipHubScreenState extends State<InternshipHubScreen> with SingleTickerProviderStateMixin {
  late TabController _mainTabController;
  List<dynamic> _courses = [];
  bool _loading = true;
  String _selectedCategory = 'All';
  String _searchQuery = '';

  final List<String> _categories = ['All', 'Mobile', 'Web', 'AI', 'Data', 'Cloud'];

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    _loadCourses();
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    setState(() => _loading = true);
    try {
      final res = await Dio().get('https://myvault-project.vercel.app/api/courses');
      if (res.data != null && res.data['data'] is List) {
        setState(() {
          _courses = res.data['data'];
          _loading = false;
        });
        return;
      }
    } catch (_) {}

    setState(() {
      _courses = _fallbackCourses;
      _loading = false;
    });
  }

  List<dynamic> get _fallbackCourses => [
        {
          'id': 'course_flutter_dev',
          'title': 'Flutter Mobile App Development',
          'category': 'Mobile',
          'level': 'Beginner to Advanced',
          'duration': '8 Hours',
          'lessonsCount': 6,
          'isFree': true,
          'description': 'Build real-world Android and iOS apps from scratch using Flutter, GoRouter, REST APIs & AWS S3.',
          'learnings': [
            'Flutter fundamentals & Dart syntax',
            'Building responsive Material 3 UIs',
            'GoRouter navigation & Riverpod state',
            'Connecting Node.js & S3 REST APIs',
          ],
        },
        {
          'id': 'course_python_ai',
          'title': 'Python AI & Machine Learning Foundations',
          'category': 'AI',
          'level': 'Beginner',
          'duration': '10 Hours',
          'lessonsCount': 8,
          'isFree': true,
          'description': 'Learn Python, NumPy, Pandas, and build intelligent machine learning models for real-world projects.',
          'learnings': [
            'Python data structures & OOP',
            'Data analysis with Pandas & NumPy',
            'Supervised machine learning models',
          ],
        },
        {
          'id': 'course_fullstack_web',
          'title': 'Full Stack Web (React & Node.js)',
          'category': 'Web',
          'level': 'Intermediate',
          'duration': '12 Hours',
          'lessonsCount': 10,
          'isFree': true,
          'description': 'Master modern web development with Next.js, Tailwind CSS, Express, and PostgreSQL RDS.',
          'learnings': [
            'React Hooks & Next.js App Router',
            'Express REST API development',
            'PostgreSQL database management',
          ],
        },
      ];

  List<dynamic> get _filteredCourses {
    return _courses.where((c) {
      final cat = c['category'] as String? ?? 'General';
      final title = (c['title'] as String? ?? '').toLowerCase();
      final matchesCat = _selectedCategory == 'All' || cat.toLowerCase() == _selectedCategory.toLowerCase();
      final matchesSearch = title.contains(_searchQuery.toLowerCase());
      return matchesCat && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) context.go('/home');
      },
      child: Scaffold(
        backgroundColor: MyVaultColors.obsidian,
        appBar: AppBar(
          backgroundColor: MyVaultColors.obsidian,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
            onPressed: () => context.go('/home'),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: MyVaultColors.accentGradient,
                ),
                child: const Icon(Icons.school_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              ShaderMask(
                shaderCallback: (b) => MyVaultColors.accentGradient.createShader(b),
                child: const Text(
                  'Internship Hub',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.bookmark_outline_rounded, color: MyVaultColors.accentCyan),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MyLearningScreen()));
              },
            ),
          ],
          bottom: TabBar(
            controller: _mainTabController,
            indicatorColor: MyVaultColors.accentCyan,
            labelColor: MyVaultColors.accentCyan,
            unselectedLabelColor: Colors.white54,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: '🎓 LEARN & CERTIFY'),
              Tab(text: '💼 FIND OPPORTUNITIES'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _mainTabController,
          children: [
            _buildLearnAndCertifyTab(),
            const JobListingsScreen(type: 'INTERNSHIP', title: 'Internship Opportunities', icon: Icons.work_outline_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildLearnAndCertifyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Banner
          const Text('Learn. Build. Get Certified.', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          const Text('Free industrial internship courses with verified certificates', style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 14),

          // Search Bar
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: MyVaultColors.glassFill,
              border: Border.all(color: MyVaultColors.glassBorder),
            ),
            child: TextField(
              style: const TextStyle(color: Colors.white, fontSize: 13),
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: const InputDecoration(
                hintText: 'Search Flutter, Python AI, Full Stack...',
                hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
                prefixIcon: Icon(Icons.search_rounded, color: MyVaultColors.accentCyan, size: 18),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Continue Learning Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: [MyVaultColors.accentBlue.withValues(alpha: 0.25), MyVaultColors.accentCyan.withValues(alpha: 0.1)],
              ),
              border: Border.all(color: MyVaultColors.accentCyan.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Continue Learning', style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold)),
                    Text('72%', style: TextStyle(color: MyVaultColors.accentCyan, fontSize: 14, fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: const LinearProgressIndicator(
                    value: 0.72,
                    minHeight: 6,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(MyVaultColors.accentCyan),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Flutter Mobile App Development', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CourseDetailsScreen(course: _fallbackCourses[0]),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MyVaultColors.accentBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      ),
                      child: const Text('Continue ➔', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Course Category Chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Explore Free Courses', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const MyLearningScreen()));
                },
                child: const Text('My Learning ➔', style: TextStyle(color: MyVaultColors.accentCyan, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 6),

          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (ctx, i) {
                final cat = _categories[i];
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    selected: isSelected,
                    showCheckmark: false,
                    selectedColor: MyVaultColors.accentBlue,
                    backgroundColor: MyVaultColors.glassFill,
                    side: BorderSide(color: isSelected ? MyVaultColors.accentCyan : MyVaultColors.glassBorder),
                    label: Text(
                      cat,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 11.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    onSelected: (s) {
                      if (s) setState(() => _selectedCategory = cat);
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // Course Cards List
          _loading
              ? const Center(child: CircularProgressIndicator(color: MyVaultColors.accentCyan))
              : _filteredCourses.isEmpty
                  ? const Center(child: Text('No courses found matching search', style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredCourses.length,
                      itemBuilder: (ctx, i) => _buildCourseCard(_filteredCourses[i]),
                    ),

          const SizedBox(height: 20),

          // My Certificates Quick Launcher
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MyVaultColors.glassFill,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: MyVaultColors.glassBorder),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🏆 Verified Certificates', style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold)),
                      SizedBox(height: 2),
                      Text('S3 Certified PDF credentials stored in Vault', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ExamCertificateScreen(
                          examName: 'Flutter Mobile App Development',
                          studentName: 'Rahul Kumar',
                          certificateNumber: 'IH-CERT-884920',
                          pdfUrl: 'https://myvault-files-app.s3.eu-north-1.amazonaws.com/app-arm64-v8a-release.apk',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.withValues(alpha: 0.8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                  child: const Text('View ➔', style: TextStyle(color: Colors.black, fontSize: 11.5, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    final title = course['title'] ?? 'Course';
    final cat = course['category'] ?? 'Mobile';
    final level = course['level'] ?? 'Beginner';
    final duration = course['duration'] ?? '8 Hours';
    final lessons = course['lessonsCount'] ?? 6;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: MyVaultColors.glassFill,
        border: Border.all(color: MyVaultColors.glassBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: MyVaultColors.accentCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(cat.toUpperCase(), style: const TextStyle(color: MyVaultColors.accentCyan, fontSize: 10.5, fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C48C).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('FREE', style: TextStyle(color: Color(0xFF00C48C), fontSize: 10.5, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(course['description'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),

            Row(
              children: [
                _miniIcon(Icons.bar_chart_rounded, level),
                const SizedBox(width: 12),
                _miniIcon(Icons.schedule_rounded, duration),
                const SizedBox(width: 12),
                _miniIcon(Icons.menu_book_rounded, '$lessons lessons'),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CourseDetailsScreen(course: course),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MyVaultColors.accentBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  child: const Text('Start Course ➔', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniIcon(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 13, color: Colors.white54),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }
}
