import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/colors.dart';
import '../../core/api_client.dart';
import 'exam_video_screen.dart';

class CompetitiveExamsScreen extends StatefulWidget {
  const CompetitiveExamsScreen({super.key});

  @override
  State<CompetitiveExamsScreen> createState() => _CompetitiveExamsScreenState();
}

class _CompetitiveExamsScreenState extends State<CompetitiveExamsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _exams = [];
  bool _loading = true;
  String _searchQuery = '';

  final List<String> _categories = [
    'All',
    'Government',
    'Banking',
    'Railways',
    'Higher Education',
    'Management',
    'Professional',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadExams();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadExams() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.instance.dio.get('/api/exams');
      final fetched = res.data as List<dynamic>;
      setState(() {
        _exams = fetched.isNotEmpty ? fetched : _fallbackExams;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _exams = _fallbackExams;
        _loading = false;
      });
    }
  }

  List<dynamic> get _fallbackExams => [
        {
          'id': 'exam_upsc',
          'name': 'UPSC Civil Services',
          'cat': 'Government',
          'icon': '🏛️',
          'description': 'IAS, IPS, IFS & Allied Services examination comprehensive roadmap & lecture series.',
          'eligibility': 'Graduate (Any Discipline)',
          'ageLimit': '21 - 32 Years',
          'videos': [
            {'title': 'UPSC Syllabus & Exam Pattern Full Guide', 'duration': '15:20', 'subject': 'General Studies'},
            {'title': 'Indian Polity & Constitution Masterclass', 'duration': '22:10', 'subject': 'Polity'},
            {'title': 'Previous Year Questions Analysis', 'duration': '18:45', 'subject': 'Strategy'},
          ],
        },
        {
          'id': 'exam_ssc',
          'name': 'SSC CGL',
          'cat': 'Government',
          'icon': '🏛️',
          'description': 'Staff Selection Commission Combined Graduate Level examination prep series.',
          'eligibility': 'Bachelor\'s Degree',
          'ageLimit': '18 - 30 Years',
          'videos': [
            {'title': 'Quantitative Aptitude & Calculation Shortcuts', 'duration': '25:00', 'subject': 'Quant'},
            {'title': 'Reasoning & Logical Shortcuts', 'duration': '19:30', 'subject': 'Reasoning'},
          ],
        },
        {
          'id': 'exam_banking',
          'name': 'SBI PO / IBPS PO',
          'cat': 'Banking',
          'icon': '🏦',
          'description': 'Probationary Officer & Clerk recruitment exams for public sector banks.',
          'eligibility': 'Graduate in any discipline',
          'ageLimit': '20 - 30 Years',
          'videos': [
            {'title': 'Banking Awareness & Financial GK', 'duration': '20:15', 'subject': 'Banking Awareness'},
          ],
        },
        {
          'id': 'exam_rrb',
          'name': 'RRB NTPC & Railway JE',
          'cat': 'Railways',
          'icon': '🚆',
          'description': 'Indian Railways Non-Technical Popular Categories & Junior Engineer preparation.',
          'eligibility': '12th / Graduate / Diploma',
          'ageLimit': '18 - 33 Years',
          'videos': [
            {'title': 'General Science & Railway Physics', 'duration': '16:40', 'subject': 'Science'},
          ],
        },
        {
          'id': 'exam_jee',
          'name': 'JEE Main / Advanced',
          'cat': 'Higher Education',
          'icon': '🎓',
          'description': 'National engineering entrance for IITs, NITs, and premier institutions.',
          'eligibility': 'Class 12 Passed (PCM)',
          'ageLimit': 'No Age Limit',
          'videos': [
            {'title': 'Physics Mechanics & Calculus Problem Solving', 'duration': '28:10', 'subject': 'Physics'},
          ],
        },
        {
          'id': 'exam_neet',
          'name': 'NEET-UG Medical Entrance',
          'cat': 'Higher Education',
          'icon': '🩺',
          'description': 'National Eligibility cum Entrance Test for MBBS & BDS courses.',
          'eligibility': 'Class 12 Passed (PCB)',
          'ageLimit': '17+ Years',
          'videos': [
            {'title': 'NCERT Biology High-Yield Concepts', 'duration': '31:00', 'subject': 'Biology'},
          ],
        },
        {
          'id': 'exam_gate',
          'name': 'GATE Engineering & PSUs',
          'cat': 'Higher Education',
          'icon': '⚡',
          'description': 'Graduate Aptitude Test in Engineering for M.Tech & PSUs (IOCL, NTPC, ISRO).',
          'eligibility': 'B.Tech / B.E.',
          'ageLimit': 'No Age Limit',
          'videos': [
            {'title': 'Data Structures & OS Memory Layout', 'duration': '24:15', 'subject': 'CS'},
          ],
        },
        {
          'id': 'exam_cat',
          'name': 'CAT / XAT Management',
          'cat': 'Management',
          'icon': '💼',
          'description': 'Common Admission Test for IIMs & top B-schools in India.',
          'eligibility': 'Bachelor\'s Degree',
          'ageLimit': 'No Age Limit',
          'videos': [
            {'title': 'VARC Reading Comprehension Strategy', 'duration': '22:50', 'subject': 'VARC'},
          ],
        },
        {
          'id': 'exam_ca',
          'name': 'CA Foundation & Inter',
          'cat': 'Professional',
          'icon': '📊',
          'description': 'Institute of Chartered Accountants of India professional qualification.',
          'eligibility': '12th Passed / Graduate',
          'ageLimit': 'No Age Limit',
          'videos': [
            {'title': 'Accounting Standards & Law', 'duration': '27:30', 'subject': 'Accounting'},
          ],
        },
      ];

  List<dynamic> get _filteredExams {
    final selectedCat = _categories[_tabController.index];
    return _exams.where((e) {
      final name = (e['name'] as String? ?? '').toLowerCase();
      final cat = (e['cat'] as String? ?? '').toLowerCase();
      final matchesSearch = name.contains(_searchQuery.toLowerCase()) ||
          cat.contains(_searchQuery.toLowerCase());
      final matchesCat = selectedCat == 'All' ||
          cat.contains(selectedCat.toLowerCase());
      return matchesSearch && matchesCat;
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
                child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              ShaderMask(
                shaderCallback: (b) => MyVaultColors.accentGradient.createShader(b),
                child: const Text(
                  'Competitive Exams',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
                ),
              ),
            ],
          ),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: MyVaultColors.accentCyan,
            labelColor: MyVaultColors.accentCyan,
            unselectedLabelColor: Colors.white54,
            indicatorWeight: 3,
            tabs: _categories.map((c) => Tab(text: c)).toList(),
          ),
        ),
        body: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(14),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: MyVaultColors.glassFill,
                  border: Border.all(color: MyVaultColors.glassBorder),
                ),
                child: TextField(
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: const InputDecoration(
                    hintText: 'Search UPSC, SSC, Banking, JEE, NEET, GATE...',
                    hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded, color: MyVaultColors.accentCyan, size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
            ),

            // Exam List
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: MyVaultColors.accentCyan))
                  : _filteredExams.isEmpty
                      ? const Center(
                          child: Text(
                            'No competitive exams found matching your search',
                            style: TextStyle(color: Colors.white54, fontSize: 14),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadExams,
                          color: MyVaultColors.accentCyan,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            itemCount: _filteredExams.length,
                            itemBuilder: (ctx, i) => _buildExamCard(_filteredExams[i]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamCard(Map<String, dynamic> exam) {
    final name = exam['name'] ?? 'Competitive Exam';
    final cat = exam['cat'] ?? 'Government';
    final icon = exam['icon'] ?? '🏛️';
    final desc = exam['description'] ?? 'Exam roadmap and lecture series.';
    final eligibility = exam['eligibility'] ?? 'Graduate';
    final ageLimit = exam['ageLimit'] ?? '18+';
    final videos = (exam['videos'] as List<dynamic>?) ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: MyVaultColors.glassFill,
        border: Border.all(color: MyVaultColors.glassBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ExamVideoScreen(
                  examName: name,
                  category: cat,
                  initialVideos: videos,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            cat.toUpperCase(),
                            style: const TextStyle(
                              color: MyVaultColors.accentCyan,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: MyVaultColors.accentGradient,
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Lectures',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  desc,
                  style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.35),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _chip(Icons.school_outlined, 'Eligibility: $eligibility'),
                    _chip(Icons.person_outline_rounded, 'Age: $ageLimit'),
                    _chip(Icons.video_library_outlined, '${videos.length} S3 Lectures'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: MyVaultColors.accentCyan),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
