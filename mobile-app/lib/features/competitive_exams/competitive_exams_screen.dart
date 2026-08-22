import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import '../../core/colors.dart';
import '../../core/api_client.dart';

class CompetitiveExamsScreen extends StatefulWidget {
  const CompetitiveExamsScreen({super.key});

  @override
  State<CompetitiveExamsScreen> createState() => _CompetitiveExamsScreenState();
}

class _CompetitiveExamsScreenState extends State<CompetitiveExamsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _subjectTabController;
  List<dynamic> _resources = [];
  bool _loading = true;
  String _selectedExamId = 'upsc-cse-2026';
  String _selectedUnit = 'All';
  String _selectedCategory = 'All';
  String _searchQuery = '';

  final List<Map<String, String>> _examsList = [
    {'id': 'upsc-cse-2026', 'name': 'UPSC Civil Services', 'icon': '🏛️'},
    {'id': 'ssc-cgl-2026', 'name': 'SSC CGL', 'icon': '📚'},
    {'id': 'ibps-po-2026', 'name': 'SBI / IBPS Banking', 'icon': '🏦'},
    {'id': 'rrb-ntpc-2026', 'name': 'RRB Railways', 'icon': '🚆'},
    {'id': 'gate-cse-2027', 'name': 'GATE Engineering', 'icon': '⚡'},
    {'id': 'jee-main-2026', 'name': 'JEE Entrance', 'icon': '🎓'},
    {'id': 'neet-ug-2026', 'name': 'NEET Medical', 'icon': '🩺'},
    {'id': 'cat-mba-2026', 'name': 'CAT Management', 'icon': '💼'},
  ];

  final List<String> _subjects = [
    'All Subjects',
    'Quantitative Aptitude',
    'Logical Reasoning',
    'English Language',
    'General Awareness',
    'Current Affairs',
    'Computer Science Core',
  ];

  final List<String> _units = ['All', '1', '2', '3', '4', '5'];
  final List<String> _categories = [
    'All',
    'NOTES',
    'VIDEO_LECTURE',
    'LAB_MANUAL',
    'CHEAT_SHEET',
    'QUESTION_BANK',
    'SYLLABUS',
  ];

  @override
  void initState() {
    super.initState();
    _subjectTabController = TabController(length: _subjects.length, vsync: this);
    _subjectTabController.addListener(() => setState(() {}));
    _loadResources();
  }

  @override
  void dispose() {
    _subjectTabController.dispose();
    super.dispose();
  }

  Future<void> _loadResources() async {
    setState(() => _loading = true);
    List<dynamic> fetchedList = [];

    try {
      final res = await ApiClient.instance.dio.get('/api/admin/preparation');
      if (res.data != null && res.data['data'] is List) {
        fetchedList = res.data['data'] as List<dynamic>;
      }
    } catch (_) {}

    if (fetchedList.isEmpty) {
      try {
        final vercelRes = await Dio().get('https://myvault-project.vercel.app/api/admin/preparation');
        if (vercelRes.data != null && vercelRes.data['data'] is List) {
          fetchedList = vercelRes.data['data'] as List<dynamic>;
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _resources = fetchedList;
        _loading = false;
      });
    }
  }

  void _openUrl(String? url) async {
    final target = (url == null || url.isEmpty)
        ? 'https://myvault-files-app.s3.eu-north-1.amazonaws.com/app-arm64-v8a-release.apk'
        : url;
    final uri = Uri.parse(target);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  bool _isExamMatch(String targetId, String examId) {
    final t = targetId.toLowerCase();
    final id = examId.toLowerCase();
    if (t == id || id.contains(t) || t.contains(id)) return true;
    if (t.contains('upsc') && id.contains('upsc')) return true;
    if (t.contains('ssc') && id.contains('ssc')) return true;
    if ((t.contains('ibps') || t.contains('banking') || t.contains('bank')) &&
        (id.contains('banking') || id.contains('ibps') || id.contains('bank'))) return true;
    if ((t.contains('rrb') || t.contains('railway')) && id.contains('rrb')) return true;
    if (t.contains('gate') && id.contains('gate')) return true;
    return false;
  }

  List<dynamic> get _filteredResources {
    final selectedSubject = _subjects[_subjectTabController.index];

    return _resources.where((r) {
      final examId = (r['examId'] as String? ?? '').toLowerCase();
      final subject = r['subject'] as String? ?? 'General';
      final unit = String(r['unit'] ?? '1');
      final cat = r['contentType'] as String? ?? 'NOTES';
      final title = (r['title'] as String? ?? '').toLowerCase();

      final matchesExam = _isExamMatch(examId, _selectedExamId);
      final matchesSubject = selectedSubject == 'All Subjects' || subject.toLowerCase() == selectedSubject.toLowerCase();
      final matchesUnit = _selectedUnit == 'All' || unit == _selectedUnit;
      final matchesCat = _selectedCategory == 'All' || cat == _selectedCategory;
      final matchesSearch = title.contains(_searchQuery.toLowerCase()) || subject.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesExam && matchesSubject && matchesUnit && matchesCat && matchesSearch;
    }).toList();
  }

  String _formatCategoryPill(String cat) {
    switch (cat.toUpperCase()) {
      case 'NOTES': return '📄 Lecture Notes';
      case 'VIDEO_LECTURE': return '🎬 Video Lecture';
      case 'LAB_MANUAL': return '🧪 Practice Set';
      case 'CHEAT_SHEET': return '⚡ Formula Sheet';
      case 'ASSIGNMENT': return '📋 Homework';
      case 'QUESTION_BANK': return '📊 Question Bank / PYQs';
      case 'SYLLABUS': return '📜 Syllabus Roadmap';
      default: return cat;
    }
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat.toUpperCase()) {
      case 'VIDEO_LECTURE': return Icons.play_circle_fill_rounded;
      case 'CHEAT_SHEET': return Icons.bolt_rounded;
      case 'LAB_MANUAL': return Icons.science_rounded;
      case 'QUESTION_BANK': return Icons.bar_chart_rounded;
      case 'SYLLABUS': return Icons.assignment_outlined;
      default: return Icons.picture_as_pdf_rounded;
    }
  }

  Color _getCategoryColor(String cat) {
    switch (cat.toUpperCase()) {
      case 'VIDEO_LECTURE': return Colors.purpleAccent;
      case 'CHEAT_SHEET': return Colors.amberAccent;
      case 'LAB_MANUAL': return Colors.emeraldAccent;
      case 'QUESTION_BANK': return Colors.orangeAccent;
      case 'SYLLABUS': return Colors.cyanAccent;
      default: return MyVaultColors.accentCyan;
    }
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
            controller: _subjectTabController,
            isScrollable: true,
            indicatorColor: MyVaultColors.accentCyan,
            labelColor: MyVaultColors.accentCyan,
            unselectedLabelColor: Colors.white54,
            indicatorWeight: 3,
            tabs: _subjects.map((s) => Tab(text: s)).toList(),
          ),
        ),
        body: Column(
          children: [
            // Target Exam Horizontal Selector Chips (Academic Hub Style)
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: _examsList.length,
                itemBuilder: (ctx, i) {
                  final exam = _examsList[i];
                  final isSelected = _selectedExamId == exam['id'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: isSelected,
                      showCheckmark: false,
                      selectedColor: MyVaultColors.accentBlue,
                      backgroundColor: MyVaultColors.glassFill,
                      side: BorderSide(color: isSelected ? MyVaultColors.accentCyan : MyVaultColors.glassBorder),
                      label: Text(
                        '${exam['icon']} ${exam['name']}',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      onSelected: (s) {
                        if (s) setState(() => _selectedExamId = exam['id']!);
                      },
                    ),
                  );
                },
              ),
            ),

            // Search Bar & Unit Selector Pills
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: MyVaultColors.glassFill,
                        border: Border.all(color: MyVaultColors.glassBorder),
                      ),
                      child: TextField(
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        onChanged: (v) => setState(() => _searchQuery = v),
                        decoration: const InputDecoration(
                          hintText: 'Search notes, units, topics...',
                          hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
                          prefixIcon: Icon(Icons.search_rounded, color: MyVaultColors.accentCyan, size: 18),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Unit Selector Pill
                  PopupMenuButton<String>(
                    initialValue: _selectedUnit,
                    onSelected: (u) => setState(() => _selectedUnit = u),
                    color: MyVaultColors.obsidian,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: MyVaultColors.glassFill,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: MyVaultColors.glassBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.filter_list_rounded, color: MyVaultColors.accentCyan, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            _selectedUnit == 'All' ? 'Units' : 'Unit $_selectedUnit',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    itemBuilder: (ctx) => _units.map((u) {
                      return PopupMenuItem(
                        value: u,
                        child: Text(u == 'All' ? 'All Units (1-5)' : 'Unit $u', style: const TextStyle(color: Colors.white, fontSize: 13)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // Material Category Filter Pills (Academic Hub Style)
            Container(
              height: 42,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: _categories.length,
                itemBuilder: (ctx, i) {
                  final cat = _categories[i];
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      selected: isSelected,
                      showCheckmark: false,
                      selectedColor: MyVaultColors.accentCyan.withValues(alpha: 0.2),
                      backgroundColor: Colors.transparent,
                      side: BorderSide(color: isSelected ? MyVaultColors.accentCyan : Colors.white12),
                      label: Text(
                        cat == 'All' ? 'All Formats' : _formatCategoryPill(cat),
                        style: TextStyle(
                          color: isSelected ? MyVaultColors.accentCyan : Colors.white60,
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      onSelected: (s) {
                        setState(() => _selectedCategory = cat);
                      },
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 6),

            // Resource Card List (Exact Academic Hub Layout)
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: MyVaultColors.accentCyan))
                  : _filteredResources.isEmpty
                      ? const Center(
                          child: Text(
                            'No preparation materials uploaded for this selection',
                            style: TextStyle(color: Colors.white54, fontSize: 13),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadResources,
                          color: MyVaultColors.accentCyan,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            itemCount: _filteredResources.length,
                            itemBuilder: (ctx, i) => _buildResourceCard(_filteredResources[i]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceCard(Map<String, dynamic> item) {
    final title = item['title'] ?? 'Preparation Resource';
    final subject = item['subject'] ?? 'Quantitative Aptitude';
    final unit = String(item['unit'] ?? '1');
    final cat = item['contentType'] as String? ?? 'NOTES';
    final url = item['fileUrl'] as String?;
    final icon = _getCategoryIcon(cat);
    final color = _getCategoryColor(cat);
    final isVideo = cat == 'VIDEO_LECTURE';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: MyVaultColors.glassFill,
        border: Border.all(color: MyVaultColors.glassBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        subject,
                        style: const TextStyle(color: MyVaultColors.accentCyan, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          'Unit $unit',
                          style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () => _openUrl(url),
              style: ElevatedButton.styleFrom(
                backgroundColor: isVideo ? Colors.purpleAccent.withValues(alpha: 0.8) : MyVaultColors.accentBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: Text(
                isVideo ? 'Watch 🎬' : 'Read 📄',
                style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
