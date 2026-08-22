import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../core/colors.dart';
import '../../core/api_client.dart';
import 'exam_preparation_screen.dart';

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
    'SSC',
    'Banking',
    'UPSC',
    'Railway',
    'Defence',
    'GATE',
    'Police',
    'Teaching',
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
      if (fetched.isNotEmpty) {
        setState(() {
          _exams = fetched;
          _loading = false;
        });
        return;
      }
    } catch (_) {}

    try {
      final vercelRes = await Dio().get('https://myvault-project.vercel.app/api/exams');
      final vercelFetched = vercelRes.data as List<dynamic>;
      if (vercelFetched.isNotEmpty) {
        setState(() {
          _exams = vercelFetched;
          _loading = false;
        });
        return;
      }
    } catch (_) {}

    setState(() {
      _exams = _fallbackExams;
      _loading = false;
    });
  }

  List<dynamic> get _fallbackExams => [
        {
          'id': 'ssc-cgl-2026',
          'name': 'SSC CGL 2026 (Staff Selection Commission)',
          'cat': 'SSC',
          'icon': '📚',
          'description': 'Combined Graduate Level Examination for Group B & C central government posts.',
          'eligibility': 'Bachelor\'s Degree in any stream',
          'ageLimit': '18 - 30 Years',
          'selectionProcess': 'Tier-1 CBT ➔ Tier-2 CBT & Speed Test',
          'syllabusSummary': 'Quantitative Aptitude, Reasoning, English & General Awareness',
          'videos': [],
          'pdfNotes': [],
        },
        {
          'id': 'upsc-cse-2026',
          'name': 'UPSC Civil Services 2026 (IAS / IPS / IFS)',
          'cat': 'UPSC',
          'icon': '🏛️',
          'description': 'Union Public Service Commission Civil Services Examination full preparation roadmap, S3 video series, PYQs & PDF study notes.',
          'eligibility': 'Graduate in any discipline',
          'ageLimit': '21 - 32 Years',
          'selectionProcess': 'Prelims ➔ Mains ➔ Interview',
          'syllabusSummary': 'History, Polity, Economy, Geography, Ethics & Current Affairs',
          'videos': [],
          'pdfNotes': [],
        },
        {
          'id': 'ibps-po-2026',
          'name': 'IBPS PO / SBI PO 2026',
          'cat': 'Banking',
          'icon': '🏦',
          'description': 'Probationary Officer & Specialist Officer examinations for nationalized banks.',
          'eligibility': 'Graduate in any discipline',
          'ageLimit': '20 - 30 Years',
          'selectionProcess': 'Prelims ➔ Mains ➔ Psychometric & Interview',
          'syllabusSummary': 'Data Interpretation, Reasoning, English & Banking Awareness',
          'videos': [],
          'pdfNotes': [],
        },
        {
          'id': 'rrb-ntpc-2026',
          'name': 'RRB NTPC & Railway JE 2026',
          'cat': 'Railway',
          'icon': '🚆',
          'description': 'Indian Railways recruitment for Non-Technical Popular Categories & Junior Engineer posts.',
          'eligibility': '10+2 / Graduate / Diploma / B.Tech',
          'ageLimit': '18 - 33 Years',
          'selectionProcess': '1st Stage CBT ➔ 2nd Stage CBT ➔ Typing Test',
          'syllabusSummary': 'General Science, Math & Reasoning',
          'videos': [],
          'pdfNotes': [],
        },
        {
          'id': 'gate-cse-2027',
          'name': 'GATE CSE 2027 (Engineering)',
          'cat': 'GATE',
          'icon': '⚡',
          'description': 'Graduate Aptitude Test in Engineering for M.Tech & Direct PSU Recruitment.',
          'eligibility': 'B.Tech / B.E. / M.Sc / MCA',
          'ageLimit': 'No Age Limit',
          'selectionProcess': 'CBT Exam (100 Marks)',
          'syllabusSummary': 'Engineering Math, Aptitude & Core Computer Science',
          'videos': [],
          'pdfNotes': [],
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
                  'Preparation Hub',
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
            // Search Input
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
                    hintText: 'Search SSC CGL, UPSC, IBPS, GATE, RRB...',
                    hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded, color: MyVaultColors.accentCyan, size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
            ),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: MyVaultColors.accentCyan))
                  : _filteredExams.isEmpty
                      ? const Center(
                          child: Text(
                            'No competitive exam modules found matching your search',
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
    final id = exam['id'] ?? 'ssc-cgl-2026';
    final name = exam['name'] ?? 'Competitive Exam';
    final cat = exam['cat'] ?? 'Government';
    final icon = exam['icon'] ?? '📚';
    final desc = exam['description'] ?? 'Exam roadmap, S3 video series, PYQs & study notes.';
    final eligibility = exam['eligibility'] ?? 'Graduate';
    final ageLimit = exam['ageLimit'] ?? '18+ Years';
    final selection = exam['selectionProcess'] ?? 'Written Exam ➔ Interview';
    final syllabus = exam['syllabusSummary'] ?? 'Core Subjects & Aptitude';
    final videos = (exam['videos'] as List<dynamic>?) ?? [];
    final pdfNotes = (exam['pdfNotes'] as List<dynamic>?) ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: MyVaultColors.glassFill,
        border: Border.all(color: MyVaultColors.glassBorder),
      ),
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
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Text(
              desc,
              style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Preparation Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Your Preparation Progress', style: TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w600)),
                    Text('72%', style: TextStyle(color: MyVaultColors.accentCyan, fontSize: 12, fontWeight: FontWeight.bold)),
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
              ],
            ),

            const SizedBox(height: 14),

            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _chip(Icons.school_outlined, eligibility),
                _chip(Icons.person_outline_rounded, 'Age: $ageLimit'),
                _chip(Icons.play_circle_fill_rounded, '${videos.length} Videos'),
                _chip(Icons.picture_as_pdf_rounded, '${pdfNotes.length} PDFs'),
              ],
            ),

            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExamPreparationScreen(
                        examId: id,
                        examName: name,
                        category: cat,
                        initialVideos: videos,
                        initialPdfNotes: pdfNotes,
                        syllabusSummary: syllabus,
                        selectionProcess: selection,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                label: const Text(
                  'Prepare Now ➔',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
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

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: MyVaultColors.accentCyan),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
