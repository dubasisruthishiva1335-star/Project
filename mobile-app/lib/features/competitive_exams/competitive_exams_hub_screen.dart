import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/colors.dart';
import '../../core/api_client.dart';
import '../academic_hub/pdf_viewer_screen.dart';

class CompetitiveExamsHubScreen extends StatefulWidget {
  const CompetitiveExamsHubScreen({super.key});

  @override
  State<CompetitiveExamsHubScreen> createState() => _CompetitiveExamsHubScreenState();
}

class _CompetitiveExamsHubScreenState extends State<CompetitiveExamsHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  String _selectedContentType = 'ALL';
  bool _isLoading = true;
  final List<Map<String, dynamic>> _items = [];
  final Set<String> _bookmarkedIds = {};

  final List<Map<String, String>> _categories = [
    {'key': 'ALL', 'label': 'All Streams', 'icon': '🌐'},
    {'key': 'ENGINEERING', 'label': 'GATE & Tech', 'icon': '🚀'},
    {'key': 'CIVIL_SERVICES', 'label': 'UPSC & Govt', 'icon': '🏛️'},
    {'key': 'PLACEMENTS', 'label': 'Placements & DSA', 'icon': '💼'},
    {'key': 'HIGHER_STUDIES', 'label': 'CAT & GRE', 'icon': '🎓'},
    {'key': 'BANKING_SSC', 'label': 'Bank & SSC', 'icon': '🏦'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _loadExams();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _normalizeExam(Map<String, dynamic> raw) {
    return {
      'id': (raw['id'] ?? 'exam_${DateTime.now().millisecondsSinceEpoch}').toString(),
      'examId': (raw['examId'] ?? raw['exam_id'] ?? 'gate-cs-2026').toString(),
      'examName': (raw['examName'] ?? raw['exam_name'] ?? 'Competitive Exam').toString(),
      'category': (raw['category'] ?? 'ENGINEERING').toString().toUpperCase(),
      'title': (raw['title'] ?? 'Exam Preparation Material').toString(),
      'subject': (raw['subject'] ?? 'General Topics').toString(),
      'contentType': (raw['contentType'] ?? raw['content_type'] ?? 'NOTES').toString().toUpperCase(),
      'year': raw['year'] ?? 2026,
      'difficulty': (raw['difficulty'] ?? 'ALL_LEVELS').toString(),
      'fileUrl': (raw['fileUrl'] ?? raw['file_url'] ?? '').toString(),
      'fileSize': (raw['fileSize'] ?? raw['file_size'] ?? '3.5 MB').toString(),
      'description': (raw['description'] ?? '').toString(),
      'author': (raw['author'] ?? 'MyVault Academic Team').toString(),
      'syllabusUrl': (raw['syllabusUrl'] ?? raw['syllabus_url'] ?? '').toString(),
      'examDate': (raw['examDate'] ?? raw['exam_date'] ?? '').toString(),
      'isFeatured': raw['isFeatured'] == true || raw['is_featured'] == true,
      'downloadsCount': raw['downloadsCount'] ?? raw['downloads_count'] ?? 100,
    };
  }

    Future<void> _loadExams() async {
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

    // 1. Fetch from live Vercel Next.js Admin API
    try {
      final vRes = await ApiClient.instance.dio.get('/api/admin/competitive-exams');
      final list = parseResponseList(vRes.data);
      for (final raw in list) {
        if (raw is Map) {
          final item = Map<String, dynamic>.from(raw);
          if (item['type'] == 'COURSE' || item['type'] == 'INTERNSHIP' || item['modulesCount'] != null) continue;
          final norm = _normalizeExam(item);
          if (!seenIds.contains(norm['id'])) {
            seenIds.add(norm['id']);
            combined.add(norm);
          }
        }
      }
    } catch (_) {}

    

    if (mounted) {
      setState(() {
        _items.clear();
        _items.addAll(combined);
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getFilteredList(String categoryKey) {
    final query = _searchController.text.trim().toLowerCase();

    return _items.where((item) {
      final matchesCategory = categoryKey == 'ALL' || item['category'] == categoryKey;
      final matchesType = _selectedContentType == 'ALL' || item['contentType'] == _selectedContentType;

      final title = (item['title'] ?? '').toString().toLowerCase();
      final exam = (item['examName'] ?? '').toString().toLowerCase();
      final subj = (item['subject'] ?? '').toString().toLowerCase();
      final author = (item['author'] ?? '').toString().toLowerCase();

      final matchesQuery = query.isEmpty ||
          title.contains(query) ||
          exam.contains(query) ||
          subj.contains(query) ||
          author.contains(query);

      return matchesCategory && matchesType && matchesQuery;
    }).toList();
  }

  void _openPdf(Map<String, dynamic> item) {
    final url = (item['fileUrl'] ?? '').toString();
    final title = (item['title'] ?? 'Exam Material').toString();

    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document URL is not available.')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => PdfViewerScreen(title: title, pdfUrl: url),
      ),
    );
  }

  Future<void> _launchExternalUrl(String urlStr) async {
    final uri = Uri.tryParse(urlStr);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
          onPressed: () { if (context.canPop()) { context.pop(); } else { context.go('/home'); } },
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: MyVaultColors.metalGradient,
              ),
              child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'Competitive Exams Hub',
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
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: MyVaultColors.metalBlack,
                indicatorWeight: 3,
                labelColor: MyVaultColors.metalBlack,
                unselectedLabelColor: MyVaultColors.textMuted,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: _categories.map((c) => Tab(text: '${c['icon']} ${c['label']}')).toList(),
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
            : Column(
                children: [
                // Top Search & Content Filter Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    children: [
                      // Search Input
                      TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(color: MyVaultColors.textDark, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search GATE, UPSC, PYQ papers, formula sheets...',
                          hintStyle: const TextStyle(color: MyVaultColors.textMuted, fontSize: 13),
                          prefixIcon: const Icon(Icons.search_rounded, color: MyVaultColors.metalBlack, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: MyVaultColors.metalBlack, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: MyVaultColors.glassFill,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFFF5722)),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Format Filter Pills
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFormatFilterChip('All Formats', 'ALL'),
                            const SizedBox(width: 8),
                            _buildFormatFilterChip('📝 Solved PYQs', 'PYQ_PAPER'),
                            const SizedBox(width: 8),
                            _buildFormatFilterChip('📑 Theory Notes', 'NOTES'),
                            const SizedBox(width: 8),
                            _buildFormatFilterChip('⚡ Formula Sheets', 'FORMULA_SHEET'),
                            const SizedBox(width: 8),
                            _buildFormatFilterChip('🎯 Mock Tests', 'MOCK_TEST'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: _categories.map((cat) {
                      final list = _getFilteredList(cat['key']!);
                      return RefreshIndicator(
                        onRefresh: _loadExams,
                        color: const Color(0xFFFF5722),
                        backgroundColor: const Color(0xFF141824),
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                          children: [
                            // Live Exam Countdown Banner
                            if (cat['key'] == 'ALL' || cat['key'] == 'ENGINEERING') ...[
                              _buildExamCountdownBanner(
                                'GATE 2026 (CS & ECE)',
                                'Feb 07, 2026',
                                'Official syllabus released by IIT Kharagpur. Start chapter-wise PYQs.',
                                const Color(0xFFFF5722),
                                'https://gate2026.iitkgp.ac.in',
                              ),
                              const SizedBox(height: 14),
                            ],
                            if (cat['key'] == 'PLACEMENTS') ...[
                              _buildExamCountdownBanner(
                                'TCS NQT & IT Campus Drives 2026',
                                'Dec 2025 - Jan 2026',
                                'Ninja & Prime foundation coding packages with live solution templates.',
                                const Color(0xFF00E676),
                                'https://learning.tcsionhub.in',
                              ),
                              const SizedBox(height: 14),
                            ],

                            // Count Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${list.length} resources available',
                                  style: const TextStyle(color: MyVaultColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                const Row(
                                  children: [
                                    Icon(Icons.verified_rounded, color: Color(0xFF00E676), size: 14),
                                    SizedBox(width: 4),
                                    Text('100% Free & Verified', style: TextStyle(color: Color(0xFF00E676), fontSize: 11, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            if (list.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(40),
                                alignment: Alignment.center,
                                child: const Column(
                                  children: [
                                    Icon(Icons.search_off_rounded, color: Color(0xFFCBD5E1), size: 48),
                                    SizedBox(height: 12),
                                    Text('No exam resources found matching filters', style: TextStyle(color: MyVaultColors.textSecondary, fontSize: 13)),
                                  ],
                                ),
                              )
                            else
                              ...list.map((item) => _buildResourceCard(item)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
        ),
      ),
    );
  }

  Widget _buildFormatFilterChip(String label, String value) {
    final isSelected = _selectedContentType == value;
    return InkWell(
      onTap: () => setState(() => _selectedContentType = value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isSelected ? MyVaultColors.metalBlack : Colors.white,
          border: Border.all(
            color: isSelected ? MyVaultColors.metalBlack : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(color: isSelected ? Colors.white : MyVaultColors.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildExamCountdownBanner(String examTitle, String targetDate, String subtitle, Color color, String syllabusUrl) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.25),
            const Color(0xFF0C101A),
          ],
        ),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.timer_rounded, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(examTitle, style: const TextStyle(color: MyVaultColors.textDark, fontWeight: FontWeight.bold, fontSize: 13)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(targetDate, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: MyVaultColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceCard(Map<String, dynamic> item) {
    final id = item['id'].toString();
    final isBookmarked = _bookmarkedIds.contains(id);
    final title = (item['title'] ?? 'Preparation Resource').toString();
    final examName = (item['examName'] ?? 'Competitive Exam').toString();
    final subject = (item['subject'] ?? 'General Topics').toString();
    final author = (item['author'] ?? 'MyVault Academic Team').toString();
    final contentType = (item['contentType'] ?? 'NOTES').toString();
    final fileSize = (item['fileSize'] ?? 'PDF').toString();
    final syllabusUrl = (item['syllabusUrl'] ?? '').toString();
    final examDate = (item['examDate'] ?? '').toString();

    Color typeColor = const Color(0xFF00E676);
    String typeLabel = '📑 Theory Notes';
    if (contentType == 'PYQ_PAPER') {
      typeColor = const Color(0xFFFF5722);
      typeLabel = '📝 Solved PYQ';
    } else if (contentType == 'FORMULA_SHEET') {
      typeColor = const Color(0xFF00D9F5);
      typeLabel = '⚡ Formula Sheet';
    } else if (contentType == 'MOCK_TEST') {
      typeColor = const Color(0xFFFFB800);
      typeLabel = '🎯 Mock Test';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Badge Row: Type + Size + Bookmark
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: typeColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    typeLabel,
                    style: TextStyle(color: typeColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    fileSize,
                    style: const TextStyle(color: MyVaultColors.textSecondary, fontSize: 10, fontFamily: 'monospace'),
                  ),
                ),
                const Spacer(),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                    color: isBookmarked ? const Color(0xFFFFB800) : MyVaultColors.textMuted,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      if (isBookmarked) {
                        _bookmarkedIds.remove(id);
                      } else {
                        _bookmarkedIds.add(id);
                      }
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Title & Exam
            Text(
              title,
              style: const TextStyle(color: MyVaultColors.textDark, fontWeight: FontWeight.bold, fontSize: 15, height: 1.25),
            ),
            const SizedBox(height: 4),
            Text(
              examName,
              style: const TextStyle(color: Color(0xFFFF5722), fontWeight: FontWeight.w600, fontSize: 12),
            ),

            const SizedBox(height: 10),

            // Subject / Author Info Card
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Topic: ', style: TextStyle(color: MyVaultColors.textMuted, fontSize: 11)),
                      Expanded(
                        child: Text(subject, style: const TextStyle(color: MyVaultColors.textDark, fontSize: 11, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Text('Credit: ', style: TextStyle(color: MyVaultColors.textMuted, fontSize: 11)),
                      Expanded(
                        child: Text(author, style: const TextStyle(color: MyVaultColors.textSecondary, fontSize: 11), overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            const Divider(color: Color(0xFFE2E8F0), height: 1),
            const SizedBox(height: 10),

            // Bottom Actions: Syllabus + Open PDF Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (syllabusUrl.isNotEmpty)
                  InkWell(
                    onTap: () => _launchExternalUrl(syllabusUrl),
                    child: const Row(
                      children: [
                        Icon(Icons.open_in_new_rounded, color: MyVaultColors.textMuted, size: 12),
                        SizedBox(width: 4),
                        Text('Syllabus ↗', style: TextStyle(color: MyVaultColors.textSecondary, fontSize: 11)),
                      ],
                    ),
                  )
                else
                  Text(
                    examDate.isNotEmpty ? 'Date: $examDate' : '2026 Batch',
                    style: const TextStyle(color: MyVaultColors.textMuted, fontSize: 11),
                  ),

                ElevatedButton.icon(
                  onPressed: () => _openPdf(item),
                  icon: const Icon(Icons.menu_book_rounded, size: 15),
                  label: const Text('Read PDF ↗', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5722),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
