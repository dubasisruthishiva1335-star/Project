import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
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
    
    // 1. Try Primary Railway API endpoint
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

    // 2. Dual Fallback: Fetch directly from Vercel Web API endpoint
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

    // 3. Static Fallback
    setState(() {
      _exams = _fallbackExams;
      _loading = false;
    });
  }

  List<dynamic> get _fallbackExams => [
        {
          'id': 'exam_upsc',
          'name': 'UPSC Civil Services (IAS / IPS / IFS)',
          'cat': 'Government',
          'icon': '🏛️',
          'description': 'Union Public Service Commission Civil Services Examination full preparation roadmap, S3 video series, PYQs & PDF study notes.',
          'eligibility': 'Graduate in any discipline',
          'ageLimit': '21 - 32 Years',
          'selectionProcess': 'Prelims ➔ Mains ➔ Interview',
          'syllabusSummary': 'History, Polity, Economy, Geography, Ethics & Current Affairs',
          'videos': [
            {'title': 'UPSC Prelims & Mains Complete Strategy & Exam Pattern', 'duration': '18:30', 'subject': 'Exam Strategy'},
            {'title': 'Indian Polity & Constitution Fundamental Rights', 'duration': '25:40', 'subject': 'Indian Polity'},
            {'title': 'Indian Economy & Budget Analysis', 'duration': '22:15', 'subject': 'Economy'},
          ],
          'pdfNotes': [
            {'title': 'UPSC Indian Polity Laxmikanth Summary Notes', 'subject': 'Polity'},
            {'title': 'UPSC Prelims Last 10 Years Solved PYQ Paper', 'subject': 'PYQs'},
          ],
        },
        {
          'id': 'exam_ssc',
          'name': 'SSC CGL (Staff Selection Commission)',
          'cat': 'Government',
          'icon': '🏛️',
          'description': 'Combined Graduate Level Examination for Group B & C central government posts.',
          'eligibility': 'Bachelor\'s Degree in any stream',
          'ageLimit': '18 - 30 Years',
          'selectionProcess': 'Tier-1 CBT ➔ Tier-2 CBT & Speed Test',
          'syllabusSummary': 'Quantitative Aptitude, Reasoning, English & General Awareness',
          'videos': [
            {'title': 'Quantitative Aptitude Shortcut Methods & Vedic Math', 'duration': '28:10', 'subject': 'Quant'},
            {'title': 'Logical Reasoning & Non-Verbal Tricks', 'duration': '20:00', 'subject': 'Reasoning'},
          ],
          'pdfNotes': [
            {'title': 'SSC CGL Math Formulas & Speed Test Sheet', 'subject': 'Quant'},
          ],
        },
        {
          'id': 'exam_banking',
          'name': 'SBI PO / IBPS PO & Clerk',
          'cat': 'Banking',
          'icon': '🏦',
          'description': 'Probationary Officer & Specialist Officer examinations for nationalized banks.',
          'eligibility': 'Graduate in any discipline',
          'ageLimit': '20 - 30 Years',
          'selectionProcess': 'Prelims ➔ Mains ➔ Psychometric & Interview',
          'syllabusSummary': 'Data Interpretation, Reasoning, English & Banking Awareness',
          'videos': [
            {'title': 'Banking Awareness & RBI Monetary Policy Masterclass', 'duration': '24:30', 'subject': 'Banking GK'},
          ],
          'pdfNotes': [
            {'title': 'Banking Terms & Financial Awareness PDF Capsule', 'subject': 'Banking GK'},
          ],
        },
        {
          'id': 'exam_rrb',
          'name': 'RRB NTPC & Railway JE',
          'cat': 'Railways',
          'icon': '🚆',
          'description': 'Indian Railways recruitment for Non-Technical Popular Categories & Junior Engineer posts.',
          'eligibility': '10+2 / Graduate / Diploma / B.Tech',
          'ageLimit': '18 - 33 Years',
          'selectionProcess': '1st Stage CBT ➔ 2nd Stage CBT ➔ Typing Test',
          'syllabusSummary': 'General Science (Physics, Chemistry, Life Sciences), Math & Reasoning',
          'videos': [
            {'title': 'General Science Physics & Chemistry Railway Special', 'duration': '19:45', 'subject': 'Science'},
          ],
          'pdfNotes': [
            {'title': 'RRB Science Previous 500 Question Bank PDF', 'subject': 'Science'},
          ],
        },
        {
          'id': 'exam_jee',
          'name': 'JEE Main / Advanced (Engineering)',
          'cat': 'Higher Education',
          'icon': '🎓',
          'description': 'Premier national engineering entrance examination for IITs, NITs, IIITs, and CFTIs.',
          'eligibility': 'Class 12 Passed (PCM)',
          'ageLimit': 'No Age Limit',
          'selectionProcess': 'JEE Main CBT ➔ Advanced CBT for top 2.5 Lakhs',
          'syllabusSummary': 'Physics (Mechanics), Chemistry (Organic/Physical), Math (Calculus)',
          'videos': [
            {'title': 'Physics Mechanics & Calculus Problem Solving Techniques', 'duration': '32:00', 'subject': 'Physics'},
          ],
          'pdfNotes': [
            {'title': 'JEE Main Chemistry Formula Cheat Sheet PDF', 'subject': 'Chemistry'},
          ],
        },
        {
          'id': 'exam_neet',
          'name': 'NEET-UG (Medical Entrance)',
          'cat': 'Higher Education',
          'icon': '🩺',
          'description': 'National entrance examination for MBBS, BDS, BAMS, BHMS, and medical admissions.',
          'eligibility': 'Class 12 Passed (PCB)',
          'ageLimit': 'Minimum 17 Years',
          'selectionProcess': 'Pen & Paper OMR Exam (720 Marks)',
          'syllabusSummary': 'NCERT Biology (Botany & Zoology), Organic Chemistry & Physics',
          'videos': [
            {'title': 'NCERT Biology High-Yield Concepts & Diagram Questions', 'duration': '35:10', 'subject': 'Biology'},
          ],
          'pdfNotes': [
            {'title': 'NEET Biology One-Liner Revision PDF', 'subject': 'Biology'},
          ],
        },
        {
          'id': 'exam_gate',
          'name': 'GATE (Engineering & PSUs)',
          'cat': 'Higher Education',
          'icon': '⚡',
          'description': 'Graduate Aptitude Test in Engineering for M.Tech admissions & Direct PSU Recruitment.',
          'eligibility': 'B.Tech / B.E. / M.Sc / MCA',
          'ageLimit': 'No Age Limit',
          'selectionProcess': 'Computer Based Test (100 Marks)',
          'syllabusSummary': 'Engineering Mathematics, General Aptitude, Core Engineering Subjects',
          'videos': [
            {'title': 'Data Structures, Algorithms & OS Memory Management', 'duration': '26:45', 'subject': 'Computer Science'},
          ],
          'pdfNotes': [
            {'title': 'GATE Computer Science Handwritten Notes PDF', 'subject': 'CS'},
          ],
        },
        {
          'id': 'exam_cat',
          'name': 'CAT / XAT (Management)',
          'cat': 'Management',
          'icon': '💼',
          'description': 'Common Admission Test for MBA & PGDM programs at IIMs & top B-schools.',
          'eligibility': 'Bachelor\'s Degree with 50% marks',
          'ageLimit': 'No Age Limit',
          'selectionProcess': 'CAT Exam ➔ WAT / GD ➔ Personal Interview',
          'syllabusSummary': 'Verbal Ability (VARC), Data Interpretation (DILR), Quant (QA)',
          'videos': [
            {'title': 'VARC Passage Analysis & DILR Puzzle Solving Techniques', 'duration': '23:15', 'subject': 'VARC & DILR'},
          ],
          'pdfNotes': [
            {'title': 'CAT Quant Formula Book & DILR Tricks PDF', 'subject': 'QA'},
          ],
        },
        {
          'id': 'exam_ca',
          'name': 'CA (Chartered Accountant)',
          'cat': 'Professional',
          'icon': '📊',
          'description': 'ICAI Professional Qualification for Foundation, Intermediate & Final stages.',
          'eligibility': 'Class 12 Passed / Graduate',
          'ageLimit': 'No Age Limit',
          'selectionProcess': 'CA Foundation ➔ CA Inter ➔ 2 Yrs Articleship ➔ CA Final',
          'syllabusSummary': 'Accounting, Corporate Laws, Costing, Taxation, Auditing & SFM',
          'videos': [
            {'title': 'Accounting Standards & Corporate Law Fundamentals', 'duration': '29:00', 'subject': 'Accounting'},
          ],
          'pdfNotes': [
            {'title': 'CA Inter Income Tax Summary Notes PDF', 'subject': 'Taxation'},
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
                  'Competitive Exams Hub',
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
                    hintText: 'Search UPSC, SSC, Banking, JEE, NEET, GATE, CAT, CA...',
                    hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded, color: MyVaultColors.accentCyan, size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
            ),

            // Exam Preparation Directory
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
    final name = exam['name'] ?? 'Competitive Exam';
    final cat = exam['cat'] ?? 'Government';
    final icon = exam['icon'] ?? '🏛️';
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
                Text(icon, style: const TextStyle(fontSize: 30)),
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

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: MyVaultColors.accentBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: MyVaultColors.accentBlue.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.alt_route_rounded, color: MyVaultColors.accentCyan, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Flow: $selection',
                      style: const TextStyle(color: MyVaultColors.accentCyan, fontSize: 11.5, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.menu_book_rounded, color: Colors.white70, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Syllabus: $syllabus',
                      style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _chip(Icons.school_outlined, eligibility),
                _chip(Icons.person_outline_rounded, 'Age: $ageLimit'),
                _chip(Icons.play_circle_fill_rounded, '${videos.length} Lectures'),
                _chip(Icons.picture_as_pdf_rounded, '${pdfNotes.length} S3 PDFs'),
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
                      builder: (_) => ExamVideoScreen(
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
                icon: const Icon(Icons.school_rounded, color: Colors.white, size: 16),
                label: const Text(
                  'Start Preparation ➔',
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
