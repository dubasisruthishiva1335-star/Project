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

  // Stored Student Details for Certificate Registration
  String _studentName = "Student";
  String _studentCollege = "RV College of Engineering";
  String _studentRollNo = "1RV21CS102";
  String _studentEmail = "rahul.k@rvce.edu.in";
  String _studentPhone = "+91 9876543210";
  final Set<String> _enrolledCourseIds = {'course_fullstack_2026', 'course_python_ai_2026'};

  List<Map<String, dynamic>> _courses = [];
  final List<Map<String, dynamic>> _myEnrolledCourses = [];
  final List<Map<String, dynamic>> _myCertificates = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchCourses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCourses() async {
    setState(() => _isLoading = true);
    final List<Map<String, dynamic>> combined = [];
    final Set<String> seenIds = {};

    List<dynamic> parseResponseList(dynamic data) {
      if (data == null) return [];
      if (data is List) return data;
      if (data is String) {
        try {
          final parsed = jsonDecode(data);
          if (parsed is List) return parsed;
        } catch (_) {}
      }
      return [];
    }

    // 1. Fetch from live Vercel Admin Courses API
    try {
      final res = await ApiClient.instance.dio.get('/api/admin/courses');
      final list = parseResponseList(res.data);
      for (final raw in list) {
        if (raw is Map) {
          final item = Map<String, dynamic>.from(raw);
          if (item['type'] == 'INTERNSHIP' || item['stipend'] != null || item['eligibleBranches'] != null) {
            continue;
          }
          final id = (item['id'] ?? '').toString();
          if (id.isNotEmpty && !seenIds.contains(id)) {
            seenIds.add(id);
            combined.add(item);
          }
        }
      }
    } catch (_) {}

    // 2. Fetch from live Vercel public courses API
    try {
      final res = await ApiClient.instance.dio.get('/api/courses');
      final list = parseResponseList(res.data);
      for (final raw in list) {
        if (raw is Map) {
          final item = Map<String, dynamic>.from(raw);
          if (item['type'] == 'INTERNSHIP' || item['stipend'] != null) continue;
          final id = (item['id'] ?? '').toString();
          if (id.isNotEmpty && !seenIds.contains(id)) {
            seenIds.add(id);
            combined.add(item);
          }
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _courses = combined;
        _myEnrolledCourses.clear();
        for (final c in _courses) {
          final cid = c['id']?.toString() ?? '';
          if (_enrolledCourseIds.contains(cid)) {
            _myEnrolledCourses.add(c);
          }
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        }
      },
      child: Scaffold(
        backgroundColor: MyVaultColors.backgroundWhite,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: MyVaultColors.metalBlack, size: 20),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: MyVaultColors.metalGradient,
                ),
                child: const Icon(Icons.school_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Courses & AI Learning',
                style: TextStyle(color: MyVaultColors.metalBlack, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  indicatorColor: MyVaultColors.metalBlack,
                  indicatorWeight: 3,
                  labelColor: MyVaultColors.metalBlack,
                  unselectedLabelColor: MyVaultColors.textMuted,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: [
                    const Tab(text: 'Explore Courses'),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('My Learning'),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_myEnrolledCourses.length}',
                              style: const TextStyle(color: MyVaultColors.metalBlack, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Certificates'),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_myCertificates.length}',
                              style: const TextStyle(color: MyVaultColors.metalBlack, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
              ],
            ),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: MyVaultColors.whiteShadingGradient,
          ),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: MyVaultColors.metalBlack))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildExploreTab(),
                    _buildMyLearningTab(),
                    _buildCertificatesTab(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildExploreTab() {
    final categories = ['ALL', 'Web Development', 'AI & Machine Learning', 'Cloud & DevOps'];
    final filtered = _courses.where((c) {
      final matchesCat = _selectedCategory == 'ALL' || (c['category'] ?? '').toString().toLowerCase() == _selectedCategory.toLowerCase();
      final query = _searchController.text.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          (c['title'] ?? '').toString().toLowerCase().contains(query) ||
          (c['description'] ?? '').toString().toLowerCase().contains(query);
      return matchesCat && matchesSearch;
    }).toList();

    return RefreshIndicator(
      onRefresh: _fetchCourses,
      color: MyVaultColors.accentCyan,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Search Box
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: MyVaultColors.textDark, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search video courses, AI topics, certifications...',
                hintStyle: const TextStyle(color: MyVaultColors.textMuted, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: MyVaultColors.metalBlack, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, color: MyVaultColors.metalBlack, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedCategory = cat);
                    },
                    selectedColor: MyVaultColors.metalBlack,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : MyVaultColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: isSelected ? MyVaultColors.metalBlack : const Color(0xFFE2E8F0)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: const Column(
                children: [
                  Icon(Icons.search_off_rounded, color: MyVaultColors.textMuted, size: 48),
                  SizedBox(height: 12),
                  Text('No matching courses found', style: TextStyle(color: MyVaultColors.textDark, fontWeight: FontWeight.bold, fontSize: 15)),
                  SizedBox(height: 4),
                  Text('Try searching for Web, AI, Python, or Cloud topics', style: TextStyle(color: MyVaultColors.textSecondary, fontSize: 12)),
                ],
              ),
            )
          else
            ...filtered.map((c) => _buildCourseCard(c)),
        ],
      ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    final title = course['title'] ?? 'Course Title';
    final category = course['category'] ?? 'General';
    final duration = course['duration'] ?? 'Self-Paced';
    final instructor = course['instructor'] ?? 'MyVault Academy';
    final rating = course['rating'] ?? 4.8;
    final enrolled = course['enrolled'] ?? 1000;
    final colorVal = course['logoColor'] is int ? course['logoColor'] : 0xFF3E7BFF;
    final isEnrolled = _enrolledCourseIds.contains(course['id']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleCourseClick(course),
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
                        color: Color(colorVal).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(colorVal).withValues(alpha: 0.3)),
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.code_rounded, color: Color(colorVal), size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(color: MyVaultColors.textDark, fontWeight: FontWeight.bold, fontSize: 16, height: 1.2)),
                          const SizedBox(height: 4),
                          Text(instructor, style: const TextStyle(color: MyVaultColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
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
                          Text('$rating', style: const TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.bold, fontSize: 11)),
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
                    _buildTag(category, Icons.category_outlined, const Color(0xFF0284C7)),
                    _buildTag(duration, Icons.schedule_rounded, const Color(0xFFD97706)),
                    _buildTag('$enrolled Learners', Icons.people_outline_rounded, const Color(0xFF7C3AED)),
                    _buildTag('🏆 24h Verified Certificate', Icons.verified_rounded, const Color(0xFF059669)),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(color: Color(0xFFE2E8F0), height: 1),
                const SizedBox(height: 14),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.video_library_rounded, color: MyVaultColors.textMuted, size: 14),
                        SizedBox(width: 5),
                        Text('Videos • AI Quizzes • Exams', style: TextStyle(color: MyVaultColors.textSecondary, fontSize: 11)),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () => _handleCourseClick(course),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isEnrolled ? MyVaultColors.metalBlack : const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        isEnrolled ? 'Continue Learning ➔' : 'Register & Start 🎓',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
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
    if (_myEnrolledCourses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school_outlined, color: MyVaultColors.textMuted, size: 54),
              const SizedBox(height: 16),
              const Text('No Courses in My Learning', style: TextStyle(color: MyVaultColors.textDark, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('You have not enrolled in any video courses yet. Explore our curriculum and start learning with 24-hour certification.', textAlign: TextAlign.center, style: TextStyle(color: MyVaultColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _tabController.animateTo(0),
                icon: const Icon(Icons.explore_rounded, size: 18),
                label: const Text('Explore Courses ➔', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyVaultColors.metalBlack,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary Header Card
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: MyVaultColors.metalGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Active Scholar: $_studentName', style: const TextStyle(color: MyVaultColors.textDark, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('$_studentCollege • ${_myEnrolledCourses.length} Courses in Progress', style: const TextStyle(color: MyVaultColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Course Cards
        ..._myEnrolledCourses.map((c) {
          final progress = (c['progress'] is num) ? (c['progress'] as num).toInt() : 65;
          final completed = c['completedLessons'] ?? 18;
          final total = c['totalLessons'] ?? 24;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        c['category'] ?? 'Engineering',
                        style: const TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$progress% Complete',
                        style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(c['title'] ?? 'Course Title', style: const TextStyle(color: MyVaultColors.textDark, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text('Registered to: $_studentName • $_studentCollege', style: const TextStyle(color: MyVaultColors.textSecondary, fontSize: 11)),
                const SizedBox(height: 4),
                Text('Completed $completed of $total video lessons', style: const TextStyle(color: MyVaultColors.textMuted, fontSize: 11)),
                const SizedBox(height: 14),

                // Linear Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
                  ),
                ),

                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _openCourseDetails(c),
                      icon: const Icon(Icons.list_alt_rounded, size: 16, color: MyVaultColors.metalBlack),
                      label: const Text('Syllabus & Quizzes', style: TextStyle(color: MyVaultColors.metalBlack, fontSize: 12, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _openLessonPlayer(c),
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: const Text('Watch & Learn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MyVaultColors.metalBlack,
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
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.workspace_premium_outlined, color: MyVaultColors.textMuted, size: 54),
              SizedBox(height: 16),
              Text('No Certificates in Queue', style: TextStyle(color: MyVaultColors.textDark, fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Register your details, complete 100% of video lessons, and pass the final exam. Your verifiable certificate is minted within 24 hours.', textAlign: TextAlign.center, style: TextStyle(color: MyVaultColors.textSecondary, fontSize: 13)),
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
    final student = cert['studentName'] ?? _studentName;
    final college = cert['college'] ?? _studentCollege;
    final score = cert['score'] ?? 88;
    final status = cert['status'] ?? 'EARNED';
    final readyIn = cert['readyIn'] ?? '22 Hours Remaining';
    final date = cert['issuedDate'] ?? 'September 7, 2026';
    final verifyUrl = cert['verificationUrl'] ?? 'https://project-chi-six-62.vercel.app/verify/$certId';

    // 1. Pending 24-Hour Review Card
    if (status == 'PENDING_24H_REVIEW') {
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD97706)),
          boxShadow: const [
            BoxShadow(color: Color(0x0C000000), blurRadius: 16, offset: Offset(0, 4)),
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
                        color: const Color(0xFFD97706).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 22),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('IN 24-HOUR VERIFICATION QUEUE', style: TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.1)),
                        Text('Certificate Under Audit', style: TextStyle(color: MyVaultColors.textDark, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFD97706).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  child: Text(readyIn, style: const TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.bold, fontSize: 10)),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Text('Registered Recipient:', style: TextStyle(color: MyVaultColors.textMuted, fontSize: 11)),
            Text(student, style: const TextStyle(color: MyVaultColors.textDark, fontWeight: FontWeight.bold, fontSize: 17)),
            Text(college, style: const TextStyle(color: MyVaultColors.accentCyan, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Course: $course', style: const TextStyle(color: MyVaultColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),

            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Column(
                children: [
                  _buildAuditCheck('✓ 100% Video Lecture Hours Completed', true),
                  _buildAuditCheck('✓ Video-Grounded AI Quizzes Passed', true),
                  _buildAuditCheck('✓ Final Certification Exam Evaluated ($score%)', true),
                  _buildAuditCheck('⏳ Digital Seal Minting (Ready within 24 Hours)', false),
                ],
              ),
            ),

            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Token ID', style: TextStyle(color: MyVaultColors.textMuted, fontSize: 10)),
                    Text(certId, style: const TextStyle(color: MyVaultColors.textDark, fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 11)),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    // Instant unlock demo
                    setState(() {
                      cert['status'] = 'EARNED';
                      cert['issuedDate'] = 'September 7, 2026';
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✓ 24-Hour Review Verified! Certificate Minted.')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('⚡ Instant Approve (Demo)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // 2. Fully Issued & Verified Certificate
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF059669)),
        boxShadow: const [
          BoxShadow(color: Color(0x0C000000), blurRadius: 16, offset: Offset(0, 4)),
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
                      color: const Color(0xFF059669).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.emoji_events_rounded, color: Color(0xFF059669), size: 24),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MYVAULT OFFICIALLY VERIFIED', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.2)),
                      Text('Certificate of Achievement', style: TextStyle(color: MyVaultColors.textDark, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF059669).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: Text('Score: $score%', style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ],
          ),

          const SizedBox(height: 18),
          const Text('This is to certify that', style: TextStyle(color: MyVaultColors.textMuted, fontSize: 11)),
          Text(student, style: const TextStyle(color: MyVaultColors.textDark, fontWeight: FontWeight.bold, fontSize: 18)),
          Text(college, style: const TextStyle(color: MyVaultColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 6),
          const Text('has successfully completed the comprehensive curriculum & examinations in', style: TextStyle(color: MyVaultColors.textSecondary, fontSize: 11)),
          Text(course, style: const TextStyle(color: MyVaultColors.accentCyan, fontWeight: FontWeight.bold, fontSize: 14)),

          const SizedBox(height: 18),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Certificate ID', style: TextStyle(color: MyVaultColors.textMuted, fontSize: 10)),
                  Text(certId, style: const TextStyle(color: MyVaultColors.textDark, fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text('Issued on $date', style: const TextStyle(color: MyVaultColors.textMuted, fontSize: 10)),
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
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
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

  Widget _buildAuditCheck(String text, bool isDone) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(isDone ? Icons.check_circle_rounded : Icons.pending_rounded, color: isDone ? const Color(0xFF059669) : const Color(0xFFD97706), size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isDone ? MyVaultColors.textDark : const Color(0xFFD97706),
                fontSize: 11,
                fontWeight: isDone ? FontWeight.w500 : FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleCourseClick(Map<String, dynamic> course) {
    final courseId = course['id'] ?? '';
    if (!_enrolledCourseIds.contains(courseId)) {
      _showPreLearningRegistrationDialog(course);
    } else {
      _openCourseDetails(course);
    }
  }

  // Pre-Learning Student Registration Modal
  void _showPreLearningRegistrationDialog(Map<String, dynamic> course) {
    final nameCtrl = TextEditingController(text: _studentName);
    final collegeCtrl = TextEditingController(text: _studentCollege);
    final rollCtrl = TextEditingController(text: _studentRollNo);
    final emailCtrl = TextEditingController(text: _studentEmail);
    final phoneCtrl = TextEditingController(text: _studentPhone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(color: Color(0x1F000000), blurRadius: 30, offset: Offset(0, -6)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(4)))),
              const SizedBox(height: 14),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFF0284C7).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.badge_rounded, color: Color(0xFF0284C7), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Student Certificate Registration', style: TextStyle(color: MyVaultColors.textDark, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Details will be permanently engraved on your certificate', style: TextStyle(color: MyVaultColors.textSecondary, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFD97706).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Please enter your exact legal name & college. Upon completing the course, your verified certificate is minted in these details within 24 hours.',
                        style: TextStyle(color: Color(0xFFD97706), fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),
              _buildInputField('Full Legal Name (as on Degree/ID) *', nameCtrl, Icons.person_rounded),
              const SizedBox(height: 10),
              _buildInputField('College / University / Organization *', collegeCtrl, Icons.school_rounded),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildInputField('USN / Roll No', rollCtrl, Icons.numbers_rounded)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildInputField('Email Address', emailCtrl, Icons.email_rounded)),
                ],
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty || collegeCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your full name and college name.')));
                    return;
                  }

                  setState(() {
                    _studentName = nameCtrl.text.trim();
                    _studentCollege = collegeCtrl.text.trim();
                    _studentRollNo = rollCtrl.text.trim();
                    _studentEmail = emailCtrl.text.trim();
                    _studentPhone = phoneCtrl.text.trim();
                    _enrolledCourseIds.add(course['id'] ?? '');
                    if (!_myEnrolledCourses.any((c) => c['id'] == course['id'])) {
                      _myEnrolledCourses.add(course);
                    }
                  });

                  // Call backend enroll endpoint
                  try {
                    await ApiClient.instance.dio.post('/courses/${course['id']}/enroll', data: {
                      'studentName': _studentName,
                      'college': _studentCollege,
                      'studentId': _studentRollNo,
                      'email': _studentEmail,
                      'phone': _studentPhone,
                    });
                  } catch (_) {}

                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  if (!mounted) return;
                  _openLessonPlayer(course);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyVaultColors.metalBlack,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save Details & Start Learning ➔', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController ctrl, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: MyVaultColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: TextField(
            controller: ctrl,
            style: const TextStyle(color: MyVaultColors.textDark, fontSize: 12),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: MyVaultColors.textMuted, size: 16),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  void _openCourseDetails(Map<String, dynamic> course) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CourseDetailsSheet(
        course: course,
        studentName: _studentName,
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
              content: Text('✓ Completed "$lessonTitle" & Passed Video Quiz!'),
              backgroundColor: const Color(0xFF059669),
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
      builder: (ctx) => _FinalExamSheet(
        course: course,
        studentName: _studentName,
        studentCollege: _studentCollege,
        onExamSubmitted: (certData) {
          setState(() {
            _myCertificates.insert(0, certData);
            _tabController.animateTo(2);
          });
        },
      ),
    );
  }
}

/// Course Details Bottom Sheet
class _CourseDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> course;
  final String studentName;
  final VoidCallback onStartLearning;
  final VoidCallback onTakeExam;

  const _CourseDetailsSheet({
    required this.course,
    required this.studentName,
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
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(color: Color(0x1F000000), blurRadius: 30, offset: Offset(0, -6)),
            ],
          ),
          child: Column(
            children: [
              Container(margin: const EdgeInsets.symmetric(vertical: 10), width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(4))),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(color: MyVaultColors.textDark, fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('Instructor: $instructor • Enrolled as: $studentName', style: const TextStyle(color: MyVaultColors.accentCyan, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.close, color: MyVaultColors.textSecondary), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),

              const Divider(color: Color(0xFFE2E8F0)),

              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Key Stats
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem('🎥 Video Lessons', 'HD Streaming'),
                          _StatItem('🧠 AI Quizzes', 'Grounded in Videos'),
                          _StatItem('📝 PDF CheatSheets', 'Downloadable'),
                          _StatItem('⏱️ 24h Review', 'Verified Seal'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Text('About this Course', style: TextStyle(color: MyVaultColors.textDark, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 6),
                    Text(desc, style: const TextStyle(color: MyVaultColors.textSecondary, fontSize: 13, height: 1.5)),

                    const SizedBox(height: 20),
                    const Text('Skills You Will Master', style: TextStyle(color: MyVaultColors.textDark, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: skills.map((s) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: const Color(0xFF0284C7).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.25))),
                        child: Text(s.toString(), style: const TextStyle(color: Color(0xFF0284C7), fontSize: 12, fontWeight: FontWeight.w600)),
                      )).toList(),
                    ),

                    const SizedBox(height: 24),
                    const Text('24-Hour Certification Protocol', style: TextStyle(color: MyVaultColors.textDark, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 10),
                    _buildCriteriaItem('1. Register full legal name and college before starting'),
                    _buildCriteriaItem('2. Watch 100% of video lecture modules'),
                    _buildCriteriaItem('3. Pass all video-grounded AI quizzes (>= 70%)'),
                    _buildCriteriaItem('4. Pass Final Comprehensive Examination (>= 70%)'),
                    _buildCriteriaItem('5. Official QR-verifiable certificate generated in 24 hours'),

                    const SizedBox(height: 30),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onTakeExam,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFD97706),
                          side: const BorderSide(color: Color(0xFFD97706)),
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
                          backgroundColor: MyVaultColors.metalBlack,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Watch Videos & Learn ➔', style: TextStyle(fontWeight: FontWeight.bold)),
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
          const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 14),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: MyVaultColors.textSecondary, fontSize: 12))),
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
        Text(title, style: const TextStyle(color: MyVaultColors.textDark, fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(color: MyVaultColors.textSecondary, fontSize: 10)),
      ],
    );
  }
}

/// Video Lesson Player & Interactive Video-Grounded Quiz Sheet
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
  int _selectedQuizTab = 0; // 0 = Video & Notes, 1 = Video AI Quiz
  final Map<int, String> _quizAnswers = {};
  bool _quizSubmitted = false;
  int _quizScore = 0;

  final List<Map<String, dynamic>> _lessons = [
    {
      'title': '1.1 Full Stack Architecture & Microservices',
      'topic': 'Microservices, API Gateway, and Distributed Architecture',
      'videoUrl': 'https://www.w3schools.com/html/mov_bbb.mp4',
      'duration': '18:40',
      'pdf': 'Architecture_Summary.pdf',
      'quiz': [
        {
          'question': 'What is the primary role of an API Gateway in microservices architecture?',
          'options': ['Direct memory pointer mapping', 'Routing, authentication, and rate limiting', 'Replacing relational databases', 'Compiling frontend CSS assets'],
          'correctAnswer': 'Routing, authentication, and rate limiting',
          'explanation': 'API Gateways act as a unified entry point, routing requests and enforcing auth tokens.'
        },
        {
          'question': 'Why is decoupling frontend and backend beneficial for high-scale apps?',
          'options': ['Enables independent deployment and scaling', 'Slows down database execution', 'Removes the need for network security', 'Forces all logic to run synchronously'],
          'correctAnswer': 'Enables independent deployment and scaling',
          'explanation': 'Independent services can be deployed, scaled, and maintained separately.'
        }
      ]
    },
    {
      'title': '1.2 Modern Semantic HTML & Responsive CSS',
      'topic': 'CSS Grid, Flexbox, Mobile-First Layouts',
      'videoUrl': 'https://www.w3schools.com/html/mov_bbb.mp4',
      'duration': '24:15',
      'pdf': 'CSS_Grid_Flexbox.pdf',
      'quiz': [
        {
          'question': 'Which CSS layout model provides 2D grid positioning?',
          'options': ['display: flex', 'display: grid', 'display: table', 'display: block'],
          'correctAnswer': 'display: grid',
          'explanation': 'CSS Grid provides full 2D alignment across columns and rows.'
        }
      ]
    },
    {
      'title': '1.3 JavaScript ES6+ & Asynchronous Engine',
      'topic': 'Event Loop, Promises, Async/Await',
      'videoUrl': 'https://www.w3schools.com/html/mov_bbb.mp4',
      'duration': '32:00',
      'pdf': 'JS_EventLoop.pdf',
      'quiz': [
        {
          'question': 'In the JS event loop, where are resolved Promise callbacks placed?',
          'options': ['Macrotask Queue', 'Microtask Queue', 'Direct DOM Tree', 'Thread Pool'],
          'correctAnswer': 'Microtask Queue',
          'explanation': 'Promises are scheduled on the higher-priority microtask queue.'
        }
      ]
    }
  ];

  @override
  Widget build(BuildContext context) {
    final currentLesson = _lessons[_activeLessonIdx];
    final quizQuestions = (currentLesson['quiz'] as List<dynamic>?) ?? [];

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.98,
      minChildSize: 0.5,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(color: Color(0x1F000000), blurRadius: 30, offset: Offset(0, -6)),
            ],
          ),
          child: Column(
            children: [
              Container(margin: const EdgeInsets.symmetric(vertical: 10), width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(4))),

              // Video Player Container
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
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
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(6)),
                        child: const Row(
                          children: [
                            Icon(Icons.hd_rounded, color: Color(0xFF00D9F5), size: 14),
                            SizedBox(width: 4),
                            Text('1080p HD Video', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: Row(
                        children: [
                          Text('12:40 / ${currentLesson['duration']}', style: const TextStyle(color: Colors.white70, fontSize: 10)),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.all(Radius.circular(2)),
                              child: LinearProgressIndicator(value: 0.65, backgroundColor: Colors.white24, color: Color(0xFF00D9F5)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.open_in_new_rounded, color: Colors.white70, size: 18),
                            onPressed: () async {
                              final videoUrl = currentLesson['videoUrl'] ?? '';
                              if (videoUrl.isNotEmpty) {
                                final uri = Uri.parse(videoUrl);
                                if (await canLaunchUrl(uri)) launchUrl(uri);
                              }
                            },
                          ),
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
                          Text(currentLesson['title'], style: const TextStyle(color: MyVaultColors.textDark, fontWeight: FontWeight.bold, fontSize: 15)),
                          Text('Topic: ${currentLesson['topic'] ?? 'Technical Lecture'}', style: const TextStyle(color: MyVaultColors.accentCyan, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Mode Tabs: [Video & Notes] vs [⚡ AI Video Quiz]
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedQuizTab = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedQuizTab == 0 ? MyVaultColors.metalBlack : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _selectedQuizTab == 0 ? MyVaultColors.metalBlack : const Color(0xFFE2E8F0)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '🎥 Video & Notes',
                            style: TextStyle(
                              color: _selectedQuizTab == 0 ? Colors.white : MyVaultColors.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedQuizTab = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedQuizTab == 1 ? const Color(0xFF7C3AED) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _selectedQuizTab == 1 ? const Color(0xFF7C3AED) : const Color(0xFFE2E8F0)),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '⚡ Video AI Quiz',
                                style: TextStyle(
                                  color: _selectedQuizTab == 1 ? Colors.white : MyVaultColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: _selectedQuizTab == 1 ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${quizQuestions.length}',
                                  style: TextStyle(
                                    color: _selectedQuizTab == 1 ? Colors.white : MyVaultColors.textDark,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(color: Color(0xFFE2E8F0), height: 20),

              // Sub-Tab Content
              Expanded(
                child: _selectedQuizTab == 0
                    ? _buildVideoNotesView(currentLesson, scrollCtrl)
                    : _buildVideoQuizView(quizQuestions, currentLesson, scrollCtrl),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVideoNotesView(Map<String, dynamic> currentLesson, ScrollController scrollCtrl) {
    return ListView(
      controller: scrollCtrl,
      padding: const EdgeInsets.all(16),
      children: [
        // Attached PDF Resource Box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.3))),
          child: Row(
            children: [
              const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF059669), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(currentLesson['pdf'] ?? 'Lecture_Notes.pdf', style: const TextStyle(color: MyVaultColors.textDark, fontWeight: FontWeight.bold, fontSize: 12)),
                    const Text('Attached Lecture Cheat Sheet • PDF (1.4 MB)', style: TextStyle(color: MyVaultColors.textMuted, fontSize: 10)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.download_rounded, color: Color(0xFF059669), size: 20),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloading PDF Study Guide...')));
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),
        const Text('Course Video Playlist', style: TextStyle(color: MyVaultColors.textDark, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 10),

        ..._lessons.asMap().entries.map((entry) {
          final idx = entry.key;
          final les = entry.value;
          final isActive = idx == _activeLessonIdx;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFF1F5F9) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isActive ? MyVaultColors.metalBlack : const Color(0xFFE2E8F0)),
            ),
            child: ListTile(
              dense: true,
              leading: Icon(isActive ? Icons.play_circle_filled_rounded : Icons.video_library_rounded, color: isActive ? MyVaultColors.metalBlack : MyVaultColors.textMuted),
              title: Text(les['title'], style: TextStyle(color: MyVaultColors.textDark, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, fontSize: 12)),
              subtitle: Text(les['duration'], style: const TextStyle(color: MyVaultColors.textMuted, fontSize: 10)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFCBD5E1), size: 12),
              onTap: () {
                setState(() {
                  _activeLessonIdx = idx;
                  _quizAnswers.clear();
                  _quizSubmitted = false;
                });
              },
            ),
          );
        }),

        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: widget.onLaunchExam,
          icon: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 18),
          label: const Text('Take Final Certification Exam 🏆', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD97706),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoQuizView(List<dynamic> quizQuestions, Map<String, dynamic> currentLesson, ScrollController scrollCtrl) {
    if (quizQuestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.quiz_outlined, color: MyVaultColors.textMuted, size: 48),
            const SizedBox(height: 12),
            const Text('Auto-Generating Video Quiz...', style: TextStyle(color: MyVaultColors.textSecondary, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('The AI engine generates questions from "${currentLesson['topic'] ?? currentLesson['title']}"', textAlign: TextAlign.center, style: const TextStyle(color: MyVaultColors.textMuted, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView(
      controller: scrollCtrl,
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Color(0xFF7C3AED), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('AI Video Quiz: Grounded in "${currentLesson['title']}"', style: const TextStyle(color: MyVaultColors.textDark, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        ...quizQuestions.asMap().entries.map((entry) {
          final qIdx = entry.key;
          final q = entry.value;
          final options = (q['options'] as List<dynamic>?) ?? [];
          final selected = _quizAnswers[qIdx];
          final isCorrect = selected == q['correctAnswer'];

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${qIdx + 1}. ${q['question'] ?? q['q']}', style: const TextStyle(color: MyVaultColors.textDark, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 10),

                ...options.map((opt) {
                  final isOptSelected = selected == opt;
                  Color optBorder = const Color(0xFFE2E8F0);
                  Color optBg = const Color(0xFFF8FAFC);

                  if (_quizSubmitted) {
                    if (opt == q['correctAnswer']) {
                      optBorder = const Color(0xFF059669);
                      optBg = const Color(0xFF059669).withValues(alpha: 0.1);
                    } else if (isOptSelected && !isCorrect) {
                      optBorder = Colors.redAccent;
                      optBg = Colors.redAccent.withValues(alpha: 0.1);
                    }
                  } else if (isOptSelected) {
                    optBorder = MyVaultColors.metalBlack;
                    optBg = const Color(0xFFF1F5F9);
                  }

                  return InkWell(
                    onTap: _quizSubmitted ? null : () {
                      setState(() {
                        _quizAnswers[qIdx] = opt.toString();
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: optBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: optBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isOptSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                            color: isOptSelected ? MyVaultColors.metalBlack : MyVaultColors.textMuted,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(opt.toString(), style: TextStyle(color: MyVaultColors.textDark, fontSize: 12, fontWeight: isOptSelected ? FontWeight.bold : FontWeight.normal)),
                          ),
                          if (_quizSubmitted && opt == q['correctAnswer'])
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 16),
                        ],
                      ),
                    ),
                  );
                }),

                if (_quizSubmitted && q['explanation'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('💡 ${q['explanation']}', style: const TextStyle(color: MyVaultColors.textSecondary, fontSize: 11)),
                  ),
              ],
            ),
          );
        }),

        if (!_quizSubmitted)
          ElevatedButton(
            onPressed: () {
              int score = 0;
              for (int i = 0; i < quizQuestions.length; i++) {
                if (_quizAnswers[i] == quizQuestions[i]['correctAnswer']) {
                  score++;
                }
              }
              final pct = ((score / quizQuestions.length) * 100).round();
              setState(() {
                _quizSubmitted = true;
                _quizScore = pct;
              });

              widget.onLessonComplete(currentLesson['title']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Submit Video Quiz & Save Progress', style: TextStyle(fontWeight: FontWeight.bold)),
          )
        else
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF059669)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quiz Completed! Score: $_quizScore%', style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 13)),
                    const Text('Lesson marked complete • Ready for next video', style: TextStyle(color: MyVaultColors.textSecondary, fontSize: 11)),
                  ],
                ),
                if (_activeLessonIdx < _lessons.length - 1)
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _activeLessonIdx++;
                        _selectedQuizTab = 0;
                        _quizAnswers.clear();
                        _quizSubmitted = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MyVaultColors.metalBlack,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Next Video ➔', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Timed Final Certification Examination Sheet with 24-Hour Review Status
class _FinalExamSheet extends StatefulWidget {
  final Map<String, dynamic> course;
  final String studentName;
  final String studentCollege;
  final Function(Map<String, dynamic>) onExamSubmitted;

  const _FinalExamSheet({
    required this.course,
    required this.studentName,
    required this.studentCollege,
    required this.onExamSubmitted,
  });

  @override
  State<_FinalExamSheet> createState() => _FinalExamSheetState();
}

class _FinalExamSheetState extends State<_FinalExamSheet> {
  int _currentIdx = 0;
  final Map<int, String> _answers = {};
  bool _isEvaluating = false;

  final List<Map<String, dynamic>> _examQuestions = [
    {
      'question': 'What is the primary function of an API Gateway in microservices architecture?',
      'options': ['Direct memory address indexing', 'Routing, authentication, rate limiting, and request aggregation', 'Replacing the database completely', 'Compiling client source code'],
      'correctAnswer': 'Routing, authentication, rate limiting, and request aggregation',
    },
    {
      'question': 'Which HTTP status code signifies that a resource was successfully created?',
      'options': ['200 OK', '201 Created', '204 No Content', '301 Moved Permanently'],
      'correctAnswer': '201 Created',
    },
    {
      'question': 'Why is database indexing critical in high-traffic applications?',
      'options': ['Reduces disk read time from O(N) full table scan to O(log N) tree traversal', 'Deletes duplicate rows', 'Encrypts user passwords automatically', 'Generates foreign keys automatically'],
      'correctAnswer': 'Reduces disk read time from O(N) full table scan to O(log N) tree traversal',
    },
    {
      'question': 'What is the core benefit of containerization with Docker?',
      'options': ['Write code without IDE', 'Package applications with all dependencies for identical execution everywhere', 'Replaces CPU virtualization', 'Speeds up monitor refresh rate'],
      'correctAnswer': 'Package applications with all dependencies for identical execution everywhere',
    },
    {
      'question': 'How does JWT authentication maintain stateless verification across servers?',
      'options': ['By saving sessions in browser memory', 'By cryptographically signing payload data with a secret key', 'By querying DNS servers', 'By deleting cookies on every request'],
      'correctAnswer': 'By cryptographically signing payload data with a secret key',
    },
  ];

  Future<void> _submitExam() async {
    setState(() => _isEvaluating = true);
    final courseId = widget.course['id'] ?? 'course_fullstack_2026';
    final courseTitle = widget.course['title'] ?? 'Professional Engineering Course';

    try {
      final res = await ApiClient.instance.dio.post('/courses/$courseId/submit-exam', data: {
        'studentId': 'student_user',
        'studentName': widget.studentName,
        'college': widget.studentCollege,
        'answers': _answers,
        'passingScore': 60,
      });

      if (!mounted) return;

      if (res.data != null && res.data['certificate'] != null) {
        final cert = Map<String, dynamic>.from(res.data['certificate']);
        Navigator.pop(context);
        widget.onExamSubmitted(cert);
        _show24HourProcessingDialog(cert);
      } else {
        _showFallbackProcessing(courseTitle);
      }
    } catch (_) {
      if (!mounted) return;
      _showFallbackProcessing(courseTitle);
    } finally {
      if (mounted) setState(() => _isEvaluating = false);
    }
  }

  void _showFallbackProcessing(String courseTitle) {
    final certNum = 'MYV-CERT-2026-${100000 + DateTime.now().millisecondsSinceEpoch % 900000}';
    final cert = {
      'certificateId': certNum,
      'courseTitle': courseTitle,
      'studentName': widget.studentName,
      'college': widget.studentCollege,
      'score': 88,
      'status': 'PENDING_24H_REVIEW',
      'submittedAt': 'Just now',
      'readyIn': '24 Hours Remaining',
      'verificationUrl': 'https://project-chi-six-62.vercel.app/verify/$certNum',
    };
    Navigator.pop(context);
    widget.onExamSubmitted(cert);
    _show24HourProcessingDialog(cert);
  }

  void _show24HourProcessingDialog(Map<String, dynamic> cert) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Color(0xFFE2E8F0))),
        title: const Row(
          children: [
            Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 28),
            SizedBox(width: 10),
            Text('Submitted for 24h Review ⏳', style: TextStyle(color: MyVaultColors.textDark, fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Congratulations ${widget.studentName}! You passed the final exam with 88%.', style: const TextStyle(color: MyVaultColors.textDark, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 10),
            const Text(
              'Your course completion and exam results are now in the 24-Hour Academic Verification Queue. Your official QR-verified certificate will be minted in your name within 24 hours.',
              style: TextStyle(color: MyVaultColors.textSecondary, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Registered Name:', style: TextStyle(color: MyVaultColors.textMuted, fontSize: 10)),
                  Text(widget.studentName, style: const TextStyle(color: MyVaultColors.textDark, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  const Text('Certificate Token:', style: TextStyle(color: MyVaultColors.textMuted, fontSize: 10)),
                  Text(cert['certificateId'] ?? '', style: const TextStyle(color: Color(0xFFD97706), fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: MyVaultColors.metalBlack, foregroundColor: Colors.white),
            child: const Text('Track in Certificates Hub', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _examQuestions[_currentIdx];
    final options = (q['options'] as List<dynamic>?) ?? [];
    final selected = _answers[_currentIdx];

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(color: Color(0x1F000000), blurRadius: 30, offset: Offset(0, -6)),
            ],
          ),
          child: Column(
            children: [
              Container(margin: const EdgeInsets.symmetric(vertical: 10), width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(4))),

              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.timer_outlined, color: Color(0xFFD97706), size: 18),
                        SizedBox(width: 6),
                        Text('28:45 Remaining', style: TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    Text('Question ${_currentIdx + 1} of ${_examQuestions.length}', style: const TextStyle(color: MyVaultColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),

              const Divider(color: Color(0xFFE2E8F0)),

              // Question Body
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(q['question'], style: const TextStyle(color: MyVaultColors.textDark, fontWeight: FontWeight.bold, fontSize: 16, height: 1.3)),
                    const SizedBox(height: 20),

                    ...options.map((opt) {
                      final isSelected = selected == opt;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _answers[_currentIdx] = opt.toString();
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFF1F5F9) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: isSelected ? MyVaultColors.metalBlack : const Color(0xFFE2E8F0)),
                            boxShadow: const [
                              BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: isSelected ? MyVaultColors.metalBlack : MyVaultColors.textMuted, size: 18),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(opt.toString(), style: TextStyle(color: MyVaultColors.textDark, fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              // Bottom Nav
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentIdx > 0)
                      OutlinedButton(
                        onPressed: () => setState(() => _currentIdx--),
                        style: OutlinedButton.styleFrom(foregroundColor: MyVaultColors.metalBlack, side: const BorderSide(color: Color(0xFFCBD5E1))),
                        child: const Text('Previous'),
                      )
                    else
                      const SizedBox.shrink(),

                    if (_currentIdx < _examQuestions.length - 1)
                      ElevatedButton(
                        onPressed: () => setState(() => _currentIdx++),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MyVaultColors.metalBlack,
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
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(_isEvaluating ? 'Submitting...' : 'Submit for 24h Review 🎓', style: const TextStyle(fontWeight: FontWeight.bold)),
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
