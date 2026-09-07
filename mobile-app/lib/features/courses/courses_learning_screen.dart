import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/colors.dart';
import '../../core/api_client.dart';

class CoursesLearningScreen extends StatefulWidget {
  const CoursesLearningScreen({super.key});

  @override
  State<CoursesLearningScreen> createState() => _CoursesLearningScreenState();
}

class _CoursesLearningScreenState extends State<CoursesLearningScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  String _selectedCategory = 'ALL';
  bool _isLoading = true;

  List<Map<String, dynamic>> _courses = [];
  final List<Map<String, dynamic>> _myEnrolledCourses = [];
  final List<Map<String, dynamic>> _myCertificates = [];

  final List<Map<String, dynamic>> _seedCourses = [
    {
      'id': 'course_fullstack_2026',
      'title': 'Full Stack Web & Cloud Engineering',
      'category': 'Web Development',
      'level': 'Beginner → Advanced',
      'duration': '45 Hours (42 Lessons)',
      'instructor': 'MyVault Engineering Academy',
      'rating': 4.9,
      'enrolled': 1420,
      'logoColor': 0xFF3E7BFF,
      'description': 'Master modern full-stack engineering from scratch: HTML/CSS, JavaScript, React, Node.js, Express, PostgreSQL, REST APIs, Docker, and Cloud Deployment.',
      'skills': ['React', 'Node.js', 'PostgreSQL', 'Express', 'Docker', 'REST APIs', 'TypeScript'],
      'progress': 78,
      'completedLessons': 24,
      'totalLessons': 31,
      'modules': [
        {
          'title': 'Module 1: Web Fundamentals & Architecture',
          'lessons': [
            {'title': '1.1 Full Stack Architecture Overview', 'duration': '18 mins', 'isCompleted': true, 'pdf': 'Architecture_CheatSheet.pdf'},
            {'title': '1.2 Modern Semantic HTML & Responsive CSS', 'duration': '24 mins', 'isCompleted': true, 'pdf': 'CSS_Grid_Flexbox.pdf'},
            {'title': '1.3 JavaScript ES6+ & Asynchronous Engine', 'duration': '32 mins', 'isCompleted': true, 'pdf': 'JS_EventLoop.pdf'},
          ],
          'quiz': {'title': 'Quiz 1: Web Fundamentals', 'score': 90, 'isPassed': true}
        },
        {
          'title': 'Module 2: Frontend Engineering with React',
          'lessons': [
            {'title': '2.1 Components, JSX & Props Architecture', 'duration': '28 mins', 'isCompleted': true, 'pdf': 'React_Props_State.pdf'},
            {'title': '2.2 Advanced React Hooks & Lifecycle', 'duration': '35 mins', 'isCompleted': true, 'pdf': 'Hooks_DeepDive.pdf'},
            {'title': '2.3 State Management & Optimistic UI Updates', 'duration': '40 mins', 'isCompleted': false, 'pdf': 'Zustand_Guide.pdf'},
          ],
          'quiz': {'title': 'Quiz 2: React Mastery', 'score': 85, 'isPassed': true}
        },
        {
          'title': 'Module 3: Backend, PostgreSQL & REST APIs',
          'lessons': [
            {'title': '3.1 Node.js Runtime & Express Server Setup', 'duration': '30 mins', 'isCompleted': false, 'pdf': 'Express_Routing.pdf'},
            {'title': '3.2 Relational Schema & PostgreSQL Queries', 'duration': '45 mins', 'isCompleted': false, 'pdf': 'PostgreSQL_Queries.pdf'},
            {'title': '3.3 JWT Authentication & Route Middleware', 'duration': '38 mins', 'isCompleted': false, 'pdf': 'Auth_Security.pdf'},
          ],
          'assignment': {'title': 'Assignment: Build REST API for Store', 'status': 'PENDING'}
        },
        {
          'title': 'Final Certification Phase',
          'exam': {
            'title': 'Final Certification Examination',
            'questions': 10,
            'passingScore': 70,
            'duration': '30 mins'
          }
        }
      ]
    },
    {
      'id': 'course_python_ai_2026',
      'title': 'Python Programming & AI/ML Mastery',
      'category': 'AI & Machine Learning',
      'level': 'Beginner → Advanced',
      'duration': '38 Hours (35 Lessons)',
      'instructor': 'AI Research Labs',
      'rating': 4.8,
      'enrolled': 980,
      'logoColor': 0xFF7C3AFF,
      'description': 'Comprehensive hands-on AI curriculum: Python data structures, NumPy, Pandas, Scikit-Learn, PyTorch neural networks, and LLM fine-tuning.',
      'skills': ['Python', 'PyTorch', 'NumPy', 'Pandas', 'Machine Learning', 'Deep Learning'],
      'progress': 100,
      'completedLessons': 35,
      'totalLessons': 35,
      'modules': []
    },
    {
      'id': 'course_cloud_devops_2026',
      'title': 'Cloud Computing & AWS Architecture',
      'category': 'Cloud & DevOps',
      'level': 'Intermediate',
      'duration': '30 Hours (28 Lessons)',
      'instructor': 'Cloud Solutions Architects',
      'rating': 4.7,
      'enrolled': 650,
      'logoColor': 0xFFFF9900,
      'description': 'Master AWS cloud infrastructure, Docker containerization, Kubernetes orchestration, CI/CD automation, and cloud security architectures.',
      'skills': ['AWS', 'Docker', 'Kubernetes', 'CI/CD', 'Terraform', 'Linux'],
      'progress': 45,
      'completedLessons': 12,
      'totalLessons': 28,
      'modules': []
    }
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialData();
  }

  void _loadInitialData() {
    _myEnrolledCourses.addAll([
      _seedCourses[0],
      _seedCourses[1],
    ]);

    _myCertificates.addAll([
      {
        'certificateId': 'MYV-CERT-2026-773129',
        'courseTitle': 'Python Programming & AI/ML Mastery',
        'studentName': 'Rahul Kumar',
        'score': 92,
        'issuedDate': 'August 28, 2026',
        'verificationUrl': 'https://project-chi-six-62.vercel.app/verify/MYV-CERT-2026-773129',
        'skills': ['Python', 'PyTorch', 'Data Science', 'Machine Learning'],
      }
    ]);

    _loadCoursesFromBackend();
  }

  Future<void> _loadCoursesFromBackend() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiClient.instance.dio.get('/internships');
      if (res.data is List && (res.data as List).isNotEmpty) {
        final List<Map<String, dynamic>> list = [];
        for (final item in res.data) {
          if (item is Map<String, dynamic>) {
            list.add({
              'id': item['id'] ?? 'course_${DateTime.now().millisecondsSinceEpoch}',
              'title': item['title'] ?? 'Technical Mastery Course',
              'category': item['category'] ?? 'Software Engineering',
              'level': 'All Levels',
              'duration': item['duration'] ?? '32 Hours',
              'instructor': item['company'] ?? 'MyVault Faculty',
              'rating': 4.8,
              'enrolled': item['enrollment_count'] ?? 140,
              'logoColor': 0xFF00D9F5,
              'description': item['description'] ?? 'Hands-on technical course with practical projects and certification.',
              'skills': item['skills'] is List ? item['skills'] : ['Technical Skills', 'Problem Solving', 'Engineering'],
              'progress': 0,
              'completedLessons': 0,
              'totalLessons': 24,
              'modules': _seedCourses[0]['modules'],
            });
          }
        }

        for (final s in _seedCourses) {
          if (!list.any((c) => c['title'] == s['title'])) {
            list.add(s);
          }
        }

        if (mounted) {
          setState(() {
            _courses = list;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _courses = List.from(_seedCourses);
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredCourses {
    final query = _searchController.text.trim().toLowerCase();
    return _courses.where((c) {
      final title = (c['title'] ?? '').toString().toLowerCase();
      final category = (c['category'] ?? '').toString().toLowerCase();
      final instructor = (c['instructor'] ?? '').toString().toLowerCase();

      final matchesQuery = query.isEmpty ||
          title.contains(query) ||
          category.contains(query) ||
          instructor.contains(query);

      final matchesCat = _selectedCategory == 'ALL' ||
          category.toLowerCase().contains(_selectedCategory.toLowerCase());

      return matchesQuery && matchesCat;
    }).toList();
  }

  void _openCourseDetails(Map<String, dynamic> course) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CourseDetailsSheet(
        course: course,
        onStartLearning: () {
          Navigator.pop(ctx);
          _openLessonPlayer(course);
        },
        onTakeExam: () {
          Navigator.pop(ctx);
          _openExamSheet(course);
        },
      ),
    );
  }

  void _openLessonPlayer(Map<String, dynamic> course) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _VideoLessonPlayerSheet(
        course: course,
        onLessonComplete: (lessonTitle) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF00E676),
              behavior: SnackBarBehavior.floating,
              content: Text('✓ Completed: $lessonTitle (+10 XP)', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          );
        },
        onLaunchExam: () {
          Navigator.pop(ctx);
          _openExamSheet(course);
        },
      ),
    );
  }

  void _openExamSheet(Map<String, dynamic> course) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FinalExamModalSheet(
        course: course,
        onExamSubmitted: (score, cert) {
          if (cert != null) {
            setState(() {
              _myCertificates.insert(0, cert);
              _tabController.animateTo(2); // Jump to My Certificates
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFF00E676),
                behavior: SnackBarBehavior.floating,
                content: Row(
                  children: [
                    const Icon(Icons.emoji_events_rounded, color: Colors.black),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '🎉 Congratulations! Certified with score: $score%',
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyVaultColors.obsidian,
      appBar: AppBar(
        backgroundColor: MyVaultColors.obsidian,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => context.go('/home'),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: [Color(0xFF3E7BFF), Color(0xFF00D9F5)],
                ),
              ),
              child: const Icon(Icons.school_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'Courses & Learning',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 19),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: MyVaultColors.accentCyan,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(text: 'Explore (${_courses.length})'),
            Tab(text: 'My Learning (${_myEnrolledCourses.length})'),
            Tab(text: 'Certificates (${_myCertificates.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildExploreTab(),
          _buildMyLearningTab(),
          _buildCertificatesTab(),
        ],
      ),
    );
  }

  Widget _buildExploreTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: MyVaultColors.accentCyan));
    }

    final list = _filteredCourses;

    return RefreshIndicator(
      onRefresh: _loadCoursesFromBackend,
      color: MyVaultColors.accentCyan,
      backgroundColor: const Color(0xFF141824),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // Certification Welcome Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: [
                  MyVaultColors.accentBlue.withValues(alpha: 0.25),
                  const Color(0xFF7C3AFF).withValues(alpha: 0.2),
                ],
              ),
              border: Border.all(color: MyVaultColors.accentCyan.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: MyVaultColors.accentCyan.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.workspace_premium_rounded, color: MyVaultColors.accentCyan, size: 26),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Learn, Pass Exams & Get Certified 🎓',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Industry-recognized digital credentials with live QR code verification for recruiters.',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Search Bar
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search courses, frameworks, or AI topics...',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54, size: 20),
              filled: true,
              fillColor: MyVaultColors.glassFill,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: MyVaultColors.glassBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: MyVaultColors.glassBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: MyVaultColors.accentCyan)),
            ),
          ),

          const SizedBox(height: 12),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip('All Domains', 'ALL'),
                const SizedBox(width: 8),
                _buildCategoryChip('💻 Web Dev', 'Web Development'),
                const SizedBox(width: 8),
                _buildCategoryChip('🤖 AI & ML', 'AI'),
                const SizedBox(width: 8),
                _buildCategoryChip('☁️ Cloud & DevOps', 'Cloud'),
                const SizedBox(width: 8),
                _buildCategoryChip('🐍 Python', 'Python'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Course List Cards
          ...list.map((c) => _buildCourseCard(c)),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, String val) {
    final isSelected = _selectedCategory == val;
    return InkWell(
      onTap: () => setState(() => _selectedCategory = val),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? MyVaultColors.accentBlue : MyVaultColors.glassFill,
          border: Border.all(color: isSelected ? MyVaultColors.accentCyan : MyVaultColors.glassBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    final title = (course['title'] ?? 'Course').toString();
    final category = (course['category'] ?? 'General').toString();
    final duration = (course['duration'] ?? '30 Hours').toString();
    final instructor = (course['instructor'] ?? 'Faculty').toString();
    final double rating = (course['rating'] is num) ? (course['rating'] as num).toDouble() : 4.8;
    final int enrolled = (course['enrolled'] is num) ? (course['enrolled'] as num).toInt() : 120;
    final int colorVal = (course['logoColor'] is int) ? course['logoColor'] : 0xFF3E7BFF;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F131D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MyVaultColors.glassBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openCourseDetails(course),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Color(colorVal).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(colorVal).withValues(alpha: 0.5)),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.code_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, height: 1.2)),
                          const SizedBox(height: 4),
                          Text(instructor, style: const TextStyle(color: MyVaultColors.accentCyan, fontSize: 12, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFFFB800).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 14),
                          const SizedBox(width: 3),
                          Text('$rating', style: const TextStyle(color: Color(0xFFFFB800), fontWeight: FontWeight.bold, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildTag(category, Icons.category_outlined, const Color(0xFF00D9F5)),
                    _buildTag(duration, Icons.schedule_rounded, const Color(0xFFFFB800)),
                    _buildTag('$enrolled Learners', Icons.people_outline_rounded, const Color(0xFF7C3AFF)),
                    _buildTag('🏆 Certificate Included', Icons.verified_rounded, const Color(0xFF00E676)),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 14),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.video_library_rounded, color: Colors.white38, size: 14),
                        SizedBox(width: 5),
                        Text('Videos • Quizzes • Exams', style: TextStyle(color: Colors.white38, fontSize: 11)),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () => _openCourseDetails(course),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MyVaultColors.accentBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Start Learning ➔', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildMyLearningTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ..._myEnrolledCourses.map((c) {
          final progress = (c['progress'] is num) ? (c['progress'] as num).toInt() : 65;
          final completed = c['completedLessons'] ?? 18;
          final total = c['totalLessons'] ?? 24;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF0F131D),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: MyVaultColors.glassBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(c['category'] ?? 'Engineering', style: const TextStyle(color: MyVaultColors.accentCyan, fontWeight: FontWeight.bold, fontSize: 11)),
                    Text('$progress% Complete', style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(c['title'] ?? 'Course Title', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text('Completed $completed of $total lessons', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 14),

                // Linear Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    minHeight: 8,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00E676)),
                  ),
                ),

                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () => _openCourseDetails(c),
                      icon: const Icon(Icons.list_alt_rounded, size: 16, color: Colors.white70),
                      label: const Text('View Syllabus', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _openLessonPlayer(c),
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: const Text('Continue Learning', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MyVaultColors.accentBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCertificatesTab() {
    if (_myCertificates.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.workspace_premium_outlined, color: Colors.white30, size: 54),
              const SizedBox(height: 16),
              const Text('No Certificates Earned Yet', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Complete 100% of course lessons, pass module quizzes, and achieve 70%+ on the final exam to earn your verifiable certificate.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ..._myCertificates.map((cert) => _buildCertificateCard(cert)),
      ],
    );
  }

  Widget _buildCertificateCard(Map<String, dynamic> cert) {
    final certId = cert['certificateId'] ?? 'MYV-CERT-2026-XXXX';
    final course = cert['courseTitle'] ?? 'Course Certificate';
    final student = cert['studentName'] ?? 'Rahul Kumar';
    final score = cert['score'] ?? 88;
    final date = cert['issuedDate'] ?? 'September 7, 2026';
    final verifyUrl = cert['verificationUrl'] ?? 'https://project-chi-six-62.vercel.app/verify/$certId';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1B2236),
            const Color(0xFF0C101A),
          ],
        ),
        border: Border.all(color: const Color(0xFFFFB800).withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(color: const Color(0xFFFFB800).withValues(alpha: 0.08), blurRadius: 20, spreadRadius: 2),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB800).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFB800), size: 24),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MYVAULT VERIFIED', style: TextStyle(color: Color(0xFFFFB800), fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.2)),
                      Text('Certificate of Achievement', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF00E676).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: Text('Score: $score%', style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ],
          ),

          const SizedBox(height: 18),
          const Text('This is to certify that', style: TextStyle(color: Colors.white38, fontSize: 11)),
          Text(student, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 6),
          const Text('has successfully completed the comprehensive technical curriculum in', style: TextStyle(color: Colors.white54, fontSize: 11)),
          Text(course, style: const TextStyle(color: MyVaultColors.accentCyan, fontWeight: FontWeight.bold, fontSize: 14)),

          const SizedBox(height: 18),
          const Divider(color: Colors.white10),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Certificate ID', style: TextStyle(color: Colors.white38, fontSize: 10)),
                  Text(certId, style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text('Issued on $date', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(verifyUrl);
                  if (await canLaunchUrl(uri)) launchUrl(uri);
                },
                icon: const Icon(Icons.qr_code_2_rounded, size: 16),
                label: const Text('Verify ↗', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB800),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Course Details Bottom Sheet
class _CourseDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> course;
  final VoidCallback onStartLearning;
  final VoidCallback onTakeExam;

  const _CourseDetailsSheet({
    required this.course,
    required this.onStartLearning,
    required this.onTakeExam,
  });

  @override
  Widget build(BuildContext context) {
    final title = course['title'] ?? 'Course';
    final instructor = course['instructor'] ?? 'Faculty';
    final desc = course['description'] ?? '';
    final skills = (course['skills'] as List<dynamic>?) ?? [];

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0C101A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(margin: const EdgeInsets.symmetric(vertical: 10), width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4))),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(instructor, style: const TextStyle(color: MyVaultColors.accentCyan, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),

              const Divider(color: Colors.white10),

              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Key Stats
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: MyVaultColors.glassFill, borderRadius: BorderRadius.circular(16), border: Border.all(color: MyVaultColors.glassBorder)),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem('🎥 31 Lessons', 'HD Lectures'),
                          _StatItem('🧠 8 Quizzes', 'Real-time score'),
                          _StatItem('📝 4 Assignments', 'Code & Projects'),
                          _StatItem('🏆 Certificate', 'QR Verified'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Text('About this Course', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 6),
                    Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),

                    const SizedBox(height: 20),
                    const Text('Skills You Will Master', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: skills.map((s) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: MyVaultColors.glassFill, borderRadius: BorderRadius.circular(8), border: Border.all(color: MyVaultColors.accentCyan.withValues(alpha: 0.3))),
                        child: Text(s.toString(), style: const TextStyle(color: MyVaultColors.accentCyan, fontSize: 12)),
                      )).toList(),
                    ),

                    const SizedBox(height: 24),
                    const Text('Certification Criteria', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 10),
                    _buildCriteriaItem('100% Video Lecture Completion'),
                    _buildCriteriaItem('Pass All Module Quizzes (>= 70% average)'),
                    _buildCriteriaItem('Submit Core Practical Projects'),
                    _buildCriteriaItem('Pass Final Certification Examination (>= 70%)'),

                    const SizedBox(height: 30),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: Color(0xFF141824), border: Border(top: BorderSide(color: Colors.white10))),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onTakeExam,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFFB800),
                          side: const BorderSide(color: Color(0xFFFFB800)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Take Final Exam', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onStartLearning,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MyVaultColors.accentBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Start Learning ➔', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCriteriaItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF00E676), size: 14),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12))),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String title;
  final String subtitle;
  const _StatItem(this.title, this.subtitle);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }
}

/// Video Lesson Player & Content Viewer Sheet
class _VideoLessonPlayerSheet extends StatefulWidget {
  final Map<String, dynamic> course;
  final Function(String) onLessonComplete;
  final VoidCallback onLaunchExam;

  const _VideoLessonPlayerSheet({
    required this.course,
    required this.onLessonComplete,
    required this.onLaunchExam,
  });

  @override
  State<_VideoLessonPlayerSheet> createState() => _VideoLessonPlayerSheetState();
}

class _VideoLessonPlayerSheetState extends State<_VideoLessonPlayerSheet> {
  int _activeLessonIdx = 0;
  bool _isPlaying = true;

  final List<Map<String, dynamic>> _lessons = [
    {'title': '1.1 Full Stack Architecture & Microservices', 'duration': '18:40', 'pdf': 'Architecture_Summary.pdf'},
    {'title': '1.2 Modern Semantic HTML & Responsive CSS', 'duration': '24:15', 'pdf': 'CSS_Grid_Flexbox.pdf'},
    {'title': '1.3 JavaScript ES6+ & Asynchronous Engine', 'duration': '32:00', 'pdf': 'JS_EventLoop.pdf'},
    {'title': '2.1 Components, JSX & Props Architecture', 'duration': '28:10', 'pdf': 'React_Props_State.pdf'},
    {'title': '2.2 Advanced React Hooks & Lifecycle', 'duration': '35:20', 'pdf': 'Hooks_DeepDive.pdf'},
  ];

  @override
  Widget build(BuildContext context) {
    final currentLesson = _lessons[_activeLessonIdx];

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.98,
      minChildSize: 0.5,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0C101A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(margin: const EdgeInsets.symmetric(vertical: 10), width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4))),

              // Simulated HD Video Player Container
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [Colors.blue.withValues(alpha: 0.3), Colors.purple.withValues(alpha: 0.2)],
                        ),
                      ),
                    ),
                    IconButton(
                      iconSize: 54,
                      icon: Icon(_isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded, color: Colors.white),
                      onPressed: () => setState(() => _isPlaying = !_isPlaying),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: Row(
                        children: [
                          const Text('12:42 / 24:18', style: TextStyle(color: Colors.white70, fontSize: 10)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: const LinearProgressIndicator(value: 0.52, backgroundColor: Colors.white24, color: MyVaultColors.accentCyan),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.fullscreen_rounded, color: Colors.white70, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Title and Action
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(currentLesson['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(widget.course['title'] ?? '', style: const TextStyle(color: MyVaultColors.accentCyan, fontSize: 11)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        widget.onLessonComplete(currentLesson['title']);
                        if (_activeLessonIdx < _lessons.length - 1) {
                          setState(() => _activeLessonIdx++);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E676),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Mark Complete ✓', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ],
                ),
              ),

              const Divider(color: Colors.white10),

              // Lesson Playlist & Resources
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Attached PDF Resource Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: MyVaultColors.glassFill, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.3))),
                      child: Row(
                        children: [
                          const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF00E676), size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(currentLesson['pdf'] ?? 'Lecture_Notes.pdf', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                const Text('Attached Lecture Cheat Sheet • PDF (1.4 MB)', style: TextStyle(color: Colors.white38, fontSize: 10)),
                              ],
                            ),
                          ),
                          const Icon(Icons.download_rounded, color: Colors.white70, size: 20),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Text('Course Playlist & Modules', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),

                    ...List.generate(_lessons.length, (idx) {
                      final item = _lessons[idx];
                      final isCurrent = _activeLessonIdx == idx;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isCurrent ? MyVaultColors.accentBlue.withValues(alpha: 0.2) : MyVaultColors.glassFill,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isCurrent ? MyVaultColors.accentCyan : Colors.white10),
                        ),
                        child: ListTile(
                          onTap: () => setState(() => _activeLessonIdx = idx),
                          leading: Icon(isCurrent ? Icons.play_circle_filled_rounded : Icons.check_circle_rounded, color: isCurrent ? MyVaultColors.accentCyan : const Color(0xFF00E676), size: 20),
                          title: Text(item['title'], style: TextStyle(color: Colors.white, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
                          subtitle: Text(item['duration'], style: const TextStyle(color: Colors.white38, fontSize: 11)),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 12),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Final Certification Examination Modal Sheet
class _FinalExamModalSheet extends StatefulWidget {
  final Map<String, dynamic> course;
  final Function(int, Map<String, dynamic>?) onExamSubmitted;

  const _FinalExamModalSheet({
    required this.course,
    required this.onExamSubmitted,
  });

  @override
  State<_FinalExamModalSheet> createState() => _FinalExamModalSheetState();
}

class _FinalExamModalSheetState extends State<_FinalExamModalSheet> {
  int _currentQIdx = 0;
  final Map<int, String> _selectedAnswers = {};
  bool _isEvaluating = false;

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'What is the primary benefit of decoupled RESTful microservices architecture?',
      'options': [
        'Stateless communication and independent service scaling',
        'Direct memory indexing with zero networking',
        'Monolithic database table locks',
        'Binary-only byte payload requirement'
      ],
      'answer': 'Stateless communication and independent service scaling'
    },
    {
      'question': 'Which React hook is designed to memoize expensive calculation results between renders?',
      'options': ['useCallback', 'useMemo', 'useRef', 'useEffect'],
      'answer': 'useMemo'
    },
    {
      'question': 'In relational databases (PostgreSQL), what does ACID atomicity guarantee?',
      'options': [
        'Transactions execute completely or fail with zero side-effects',
        'Automatic cloud backup every minute',
        'Only integer types can be stored in columns',
        'Queries run asynchronously without blocking'
      ],
      'answer': 'Transactions execute completely or fail with zero side-effects'
    },
    {
      'question': 'What is the Virtual DOM in modern UI frameworks like React?',
      'options': [
        'An in-memory lightweight representation of the real DOM tree',
        'A remote web server cache',
        'A browser hardware GPU acceleration pipeline',
        'A CSS preprocessor compiler'
      ],
      'answer': 'An in-memory lightweight representation of the real DOM tree'
    },
    {
      'question': 'Which HTTP response status code signifies successful resource creation?',
      'options': ['200 OK', '201 Created', '204 No Content', '301 Moved'],
      'answer': '201 Created'
    },
  ];

  void _submitExam() async {
    setState(() => _isEvaluating = true);

    int correct = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_selectedAnswers[i] == _questions[i]['answer']) {
        correct++;
      }
    }

    final score = ((correct / _questions.length) * 100).round();
    final isPassed = score >= 60;

    Map<String, dynamic>? cert;
    if (isPassed) {
      final certId = 'MYV-CERT-2026-${100000 + DateTime.now().millisecondsSinceEpoch % 900000}';
      cert = {
        'certificateId': certId,
        'courseTitle': widget.course['title'] ?? 'Technical Certification',
        'studentName': 'Rahul Kumar',
        'score': score,
        'issuedDate': 'September 7, 2026',
        'verificationUrl': 'https://project-chi-six-62.vercel.app/verify/$certId',
      };

      // Sync with backend API
      try {
        await ApiClient.instance.dio.post('/admin/internships/${widget.course['id']}/submit-exam', data: {
          'studentName': 'Rahul Kumar',
          'score': score,
        });
      } catch (_) {}
    }

    setState(() => _isEvaluating = false);
    Navigator.pop(context);
    widget.onExamSubmitted(score, cert);
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_currentQIdx];

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0C101A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(margin: const EdgeInsets.symmetric(vertical: 10), width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4))),

              // Exam Header with Timer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Final Certification Examination', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Question ${_currentQIdx + 1} of ${_questions.length}', style: const TextStyle(color: MyVaultColors.accentCyan, fontSize: 12)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFFFB800).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                      child: const Row(
                        children: [
                          Icon(Icons.timer_outlined, color: Color(0xFFFFB800), size: 14),
                          SizedBox(width: 4),
                          Text('24:18 Left', style: TextStyle(color: Color(0xFFFFB800), fontWeight: FontWeight.bold, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(color: Colors.white10),

              // Question Body
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(q['question'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, height: 1.4)),
                    const SizedBox(height: 20),

                    ...((q['options'] as List<dynamic>).map((opt) {
                      final isSelected = _selectedAnswers[_currentQIdx] == opt;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? MyVaultColors.accentBlue.withValues(alpha: 0.25) : MyVaultColors.glassFill,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isSelected ? MyVaultColors.accentCyan : Colors.white12),
                        ),
                        child: ListTile(
                          onTap: () => setState(() => _selectedAnswers[_currentQIdx] = opt),
                          leading: Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: isSelected ? MyVaultColors.accentCyan : Colors.white38),
                          title: Text(opt.toString(), style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 13)),
                        ),
                      );
                    })),
                  ],
                ),
              ),

              // Navigation & Submit Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: Color(0xFF141824), border: Border(top: BorderSide(color: Colors.white10))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentQIdx > 0)
                      TextButton(onPressed: () => setState(() => _currentQIdx--), child: const Text('Previous', style: TextStyle(color: Colors.white70)))
                    else
                      const SizedBox.shrink(),
                    if (_currentQIdx < _questions.length - 1)
                      ElevatedButton(
                        onPressed: () => setState(() => _currentQIdx++),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MyVaultColors.accentBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Next ➔', style: TextStyle(fontWeight: FontWeight.bold)),
                      )
                    else
                      ElevatedButton(
                        onPressed: _isEvaluating ? null : _submitExam,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E676),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(_isEvaluating ? 'Evaluating...' : 'Submit & Get Certified 🎓', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
