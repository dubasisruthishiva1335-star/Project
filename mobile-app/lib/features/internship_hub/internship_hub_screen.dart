import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../core/colors.dart';
import 'models/internship_hub_models.dart';
import '../jobs/course_details_screen.dart';
import '../jobs/job_listings_screen.dart';
import '../jobs/my_learning_screen.dart';

class InternshipHubScreen extends StatefulWidget {
  const InternshipHubScreen({super.key});

  @override
  State<InternshipHubScreen> createState() => _InternshipHubScreenState();
}

class _InternshipHubScreenState extends State<InternshipHubScreen> with SingleTickerProviderStateMixin {
  late TabController _mainTabController;
  List<CourseModel> _courses = [];
  bool _loading = true;
  String _selectedCategory = 'All';
  String _searchQuery = '';

  final List<String> _categories = [
    'All',
    'Mobile',
    'Web',
    'AI',
    'Data',
    'Cloud',
    'Security',
    'DevOps',
  ];

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
        final List list = res.data['data'];
        setState(() {
          _courses = list.map((e) => CourseModel.fromJson(e)).toList();
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

  List<CourseModel> get _fallbackCourses => [
        CourseModel(
          id: 'course_flutter_dev',
          title: 'Flutter Mobile App Development',
          category: 'Mobile',
          level: 'Beginner to Advanced',
          duration: '8 Hours',
          lessonsCount: 6,
          isFree: true,
          description: 'Build real-world Android & iOS apps from scratch using Flutter, GoRouter, REST APIs & AWS S3.',
          learnings: [
            'Flutter fundamentals & Dart syntax',
            'Building responsive Material 3 UIs',
            'GoRouter navigation & state management',
            'Connecting Node.js & AWS S3 REST APIs',
          ],
        ),
        CourseModel(
          id: 'course_python_ai',
          title: 'Python AI & Machine Learning Foundations',
          category: 'AI',
          level: 'Beginner',
          duration: '10 Hours',
          lessonsCount: 8,
          isFree: true,
          description: 'Learn Python, NumPy, Pandas, and build intelligent machine learning models for real-world projects.',
          learnings: [
            'Python data structures & OOP',
            'Data analysis with Pandas & NumPy',
            'Supervised machine learning algorithms',
          ],
        ),
      ];

  List<CourseModel> get _filteredCourses {
    return _courses.where((c) {
      final matchesCat = _selectedCategory == 'All' || c.category.toLowerCase() == _selectedCategory.toLowerCase();
      final matchesSearch = c.title.toLowerCase().contains(_searchQuery.toLowerCase());
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
          bottom: TabBar(
            controller: _mainTabController,
            indicatorColor: MyVaultColors.accentCyan,
            labelColor: MyVaultColors.accentCyan,
            unselectedLabelColor: Colors.white54,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: '🎓 LEARN & CERTIFY'),
              Tab(text: '💼 OPPORTUNITIES'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _mainTabController,
          children: [
            _buildLearnAndCertifyTab(),
            const JobListingsScreen(type: 'INTERNSHIP', title: 'Internship & Job Opportunities', icon: Icons.work_outline_rounded),
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
          // Subtitle Header
          const Text(
            'Learn • Build • Get Certified • Apply',
            style: TextStyle(color: MyVaultColors.accentCyan, fontSize: 12.5, fontWeight: FontWeight.bold, letterSpacing: 0.3),
          ),
          const SizedBox(height: 10),

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
                hintText: 'Search courses, skills, internships...',
                hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
                prefixIcon: Icon(Icons.search_rounded, color: MyVaultColors.accentCyan, size: 18),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Welcome & Continue Learning Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: [MyVaultColors.accentBlue.withValues(alpha: 0.3), MyVaultColors.accentCyan.withValues(alpha: 0.12)],
              ),
              border: Border.all(color: MyVaultColors.accentCyan.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('👋 Welcome back, Student', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                    Text('78%', style: TextStyle(color: MyVaultColors.accentCyan, fontSize: 14, fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Flutter Mobile App Development', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: const LinearProgressIndicator(
                    value: 0.78,
                    minHeight: 6,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(MyVaultColors.accentCyan),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CourseDetailsScreen(course: {
                            'id': 'course_flutter_dev',
                            'title': 'Flutter Mobile App Development',
                            'category': 'Mobile',
                            'level': 'Beginner to Advanced',
                            'duration': '8 Hours',
                            'description': 'Build real-world Android and iOS apps from scratch using Flutter and Dart.',
                          }),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MyVaultColors.accentBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    ),
                    child: const Text('Continue Learning ➔', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Quick Access Grid
          const Text('QUICK ACCESS', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
          const SizedBox(height: 10),

          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.2,
            children: [
              _quickAccessTile(Icons.menu_book_rounded, '📚 Courses', () {}),
              _quickAccessTile(Icons.assignment_rounded, '📝 Assignments', () {}),
              _quickAccessTile(Icons.quiz_rounded, '🧪 Exams', () {}),
              _quickAccessTile(Icons.workspace_premium_rounded, '🏆 Certificates', () {}),
              _quickAccessTile(Icons.work_rounded, '💼 Internships', () => _mainTabController.animateTo(1)),
              _quickAccessTile(Icons.bookmark_rounded, '📁 My Learning', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MyLearningScreen()));
              }),
            ],
          ),
          const SizedBox(height: 24),

          // Free Courses Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('FREE COURSES', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const MyLearningScreen()));
                },
                child: const Text('My Learning ➔', style: TextStyle(color: MyVaultColors.accentCyan, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Category Filter Chips
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

          // Course List Cards
          _loading
              ? const Center(child: CircularProgressIndicator(color: MyVaultColors.accentCyan))
              : _filteredCourses.isEmpty
                  ? const Center(child: Text('No courses found matching criteria', style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredCourses.length,
                      itemBuilder: (ctx, i) => _buildCourseCard(_filteredCourses[i]),
                    ),
          const SizedBox(height: 24),

          // Recommended Internships Section
          const Text('RECOMMENDED INTERNSHIPS', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          const Text('Tailored to your completed courses & skills:', style: TextStyle(color: Colors.white54, fontSize: 11.5)),
          const SizedBox(height: 12),

          _buildRecommendedInternshipCard(
            title: 'Flutter Mobile Developer Intern',
            company: 'Acme Software Labs',
            stipend: '₹20,000 / month',
            location: 'Hyderabad / Remote',
          ),
          const SizedBox(height: 10),
          _buildRecommendedInternshipCard(
            title: 'Python & AI Engineer Intern',
            company: 'TCS Innovation Hub',
            stipend: '₹25,000 / month',
            location: 'Bangalore / Hybrid',
          ),
        ],
      ),
    );
  }

  Widget _quickAccessTile(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: MyVaultColors.glassFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MyVaultColors.glassBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: MyVaultColors.accentCyan, size: 14),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard(CourseModel course) {
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
                  child: Text(course.category.toUpperCase(), style: const TextStyle(color: MyVaultColors.accentCyan, fontSize: 10.5, fontWeight: FontWeight.bold)),
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

            Text(course.title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(course.description, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),

            Row(
              children: [
                _miniIcon(Icons.bar_chart_rounded, course.level),
                const SizedBox(width: 12),
                _miniIcon(Icons.schedule_rounded, course.duration),
                const SizedBox(width: 12),
                _miniIcon(Icons.menu_book_rounded, '${course.lessonsCount} lessons'),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CourseDetailsScreen(course: {
                          'id': course.id,
                          'title': course.title,
                          'category': course.category,
                          'level': course.level,
                          'duration': course.duration,
                          'description': course.description,
                        }),
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

  Widget _buildRecommendedInternshipCard({required String title, required String company, required String stipend, required String location}) {
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
            onPressed: () => _mainTabController.animateTo(1),
            style: ElevatedButton.styleFrom(
              backgroundColor: MyVaultColors.accentBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            child: const Text('View ➔', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold)),
          ),
        ],
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
