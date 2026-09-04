import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api_client.dart';
import '../../core/colors.dart';
import 'pdf_viewer_screen.dart';

const _branches = ['CSE', 'ECE', 'AI_ML', 'EEE', 'MECH', 'CIVIL', 'GENERAL'];

class AcademicHubScreen extends StatefulWidget {
  const AcademicHubScreen({super.key});

  @override
  State<AcademicHubScreen> createState() => _AcademicHubScreenState();
}

class _AcademicHubScreenState extends State<AcademicHubScreen> {
  String _branch = 'CSE';
  int _semester = 1;
  int _selectedUnit = 0; // 0 = All Units, 1-5 = Unit 1..5
  String _selectedCategory = 'ALL';

  List<dynamic> _subjects = [];
  bool _loading = true;
  String? _error;

  final List<Map<String, String>> _categories = [
    {'key': 'ALL', 'label': 'All'},
    {'key': 'NOTES', 'label': '📄 Notes'},
    {'key': 'VIDEO_LECTURE', 'label': '🎬 Videos'},
    {'key': 'LAB_MANUAL', 'label': '🧪 Labs'},
    {'key': 'CHEAT_SHEET', 'label': '⚡ Cheat Sheets'},
    {'key': 'ASSIGNMENT', 'label': '📋 Assignments'},
    {'key': 'QUESTION_BANK', 'label': '📊 Question Banks'},
    {'key': 'SYLLABUS', 'label': '📜 Syllabus'},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiClient.instance.dio.get('/subjects', queryParameters: {
        'branch': _branch,
        'semester': _semester,
      });
      final data = res.data as List<dynamic>;
      setState(() {
        _subjects = data;
      });
    } catch (e) {
      setState(() {
        _error = "Could not connect to live backend.";
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  void _viewPdfInApp(String title, String? fileUrl) {
    if (fileUrl == null || fileUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resource URL is not available.')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(title: title, pdfUrl: fileUrl),
      ),
    );
  }

  Future<void> _downloadFile(String? fileUrl) async {
    if (fileUrl == null || fileUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download URL is not available.')),
      );
      return;
    }
    final uri = Uri.tryParse(fileUrl);
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to open download: $e')),
          );
        }
      }
    }
  }

  String _formatContentType(String? raw) {
    if (raw == null) return 'Resource';
    switch (raw.toUpperCase()) {
      case 'NOTES':
        return 'Lecture Notes';
      case 'VIDEO_LECTURE':
        return 'Video Lecture';
      case 'LAB_MANUAL':
        return 'Lab Manual';
      case 'CHEAT_SHEET':
        return 'Cheat Sheet';
      case 'ASSIGNMENT':
        return 'Assignment';
      case 'QUESTION_BANK':
        return 'Question Bank / Paper';
      case 'SYLLABUS':
        return 'Syllabus';
      default:
        return raw.replaceAll('_', ' ');
    }
  }

  IconData _getContentIcon(String? raw) {
    if (raw == null) return Icons.picture_as_pdf_rounded;
    switch (raw.toUpperCase()) {
      case 'NOTES':
        return Icons.description_outlined;
      case 'VIDEO_LECTURE':
        return Icons.play_circle_outline_rounded;
      case 'LAB_MANUAL':
        return Icons.science_outlined;
      case 'CHEAT_SHEET':
        return Icons.bolt_outlined;
      case 'ASSIGNMENT':
        return Icons.assignment_outlined;
      case 'QUESTION_BANK':
        return Icons.quiz_outlined;
      case 'SYLLABUS':
        return Icons.list_alt_rounded;
      default:
        return Icons.picture_as_pdf_rounded;
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
          title: ShaderMask(
            shaderCallback: (b) => MyVaultColors.accentGradient.createShader(b),
            child: const Text(
              'Academic Study Repository',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Branch & Semester Selectors
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // Branch Selector
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: MyVaultColors.glassFill,
                          border: Border.all(color: MyVaultColors.glassBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _branch,
                            dropdownColor: const Color(0xFF141722),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: MyVaultColors.accentCyan),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            items: _branches.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _branch = v);
                                _load();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Semester Selector (Sem 1 - 8)
                    Expanded(
                      flex: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: MyVaultColors.glassFill,
                          border: Border.all(color: MyVaultColors.glassBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _semester,
                            dropdownColor: const Color(0xFF141722),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: MyVaultColors.accentCyan),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            items: List.generate(8, (i) => i + 1)
                                .map((s) => DropdownMenuItem(value: s, child: Text('Sem $s (${(s + 1) ~/ 2} Year)')))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _semester = v);
                                _load();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Unit Selector Chips (All Units, Unit 1-5)
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [0, 1, 2, 3, 4, 5].map((u) {
                    final selected = _selectedUnit == u;
                    final label = u == 0 ? 'All Units' : 'Unit $u';
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: selected,
                        onSelected: (_) => setState(() => _selectedUnit = u),
                        selectedColor: MyVaultColors.accentBlue,
                        backgroundColor: MyVaultColors.glassFill,
                        side: BorderSide(color: selected ? MyVaultColors.accentBlue : MyVaultColors.glassBorder),
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : Colors.white60,
                          fontSize: 12,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 6),

              // Category Filter Bar (Notes, Videos, Labs, Cheat Sheets, Assignments, Papers)
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: _categories.map((cat) {
                    final selected = _selectedCategory == cat['key'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(cat['label']!),
                        selected: selected,
                        onSelected: (_) => setState(() => _selectedCategory = cat['key']!),
                        selectedColor: MyVaultColors.accentCyan.withValues(alpha: 0.25),
                        backgroundColor: MyVaultColors.glassFill,
                        side: BorderSide(color: selected ? MyVaultColors.accentCyan : MyVaultColors.glassBorder),
                        labelStyle: TextStyle(
                          color: selected ? MyVaultColors.accentCyan : Colors.white54,
                          fontSize: 12,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        ),
                        checkmarkColor: MyVaultColors.accentCyan,
                      ),
                    );
                  }).toList(),
                ),
              ),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(_error!, style: const TextStyle(color: Colors.orangeAccent, fontSize: 12)),
                ),

              const SizedBox(height: 6),

              // Main List
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: MyVaultColors.accentCyan))
                    : _subjects.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.folder_open_rounded, color: Colors.white12, size: 64),
                                const SizedBox(height: 16),
                                Text(
                                  'No subjects found for $_branch (Sem $_semester)',
                                  style: const TextStyle(color: Colors.white38, fontSize: 14),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            color: MyVaultColors.accentCyan,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _subjects.length,
                              itemBuilder: (context, i) {
                                final subject = _subjects[i] as Map<String, dynamic>;
                                var contents = (subject['contents'] as List<dynamic>? ?? []);

                                // Apply Unit filter
                                if (_selectedUnit > 0) {
                                  contents = contents.where((c) => (c['unit'] ?? 1) == _selectedUnit).toList();
                                }

                                // Apply Category filter
                                if (_selectedCategory != 'ALL') {
                                  contents = contents.where((c) => c['contentType'].toString().toUpperCase() == _selectedCategory).toList();
                                }

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: MyVaultColors.glassFill,
                                    border: Border.all(color: MyVaultColors.glassBorder),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Subject Header
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(8),
                                              color: MyVaultColors.accentBlue.withValues(alpha: 0.2),
                                              border: Border.all(color: MyVaultColors.accentBlue.withValues(alpha: 0.4)),
                                            ),
                                            child: Text(
                                              subject['code'] ?? 'SUBJ',
                                              style: const TextStyle(
                                                color: MyVaultColors.accentCyan,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              subject['name'] ?? 'Untitled Subject',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 14),

                                      // Uploaded Files List
                                      if (contents.isNotEmpty) ...[
                                        ...contents.map((c) {
                                          final item = c as Map<String, dynamic>;
                                          final type = item['contentType'] as String?;
                                          final title = item['title'] as String? ?? _formatContentType(type);
                                          final fileUrl = item['fileUrl'] as String?;
                                          final unitNum = item['unit'] ?? 1;
                                          final icon = _getContentIcon(type);

                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 10),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(12),
                                              color: Colors.white.withValues(alpha: 0.03),
                                              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(icon, color: MyVaultColors.accentCyan, size: 22),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            title,
                                                            style: const TextStyle(
                                                              color: Colors.white,
                                                              fontWeight: FontWeight.w600,
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                          const SizedBox(height: 2),
                                                          Row(
                                                            children: [
                                                              Container(
                                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                                decoration: BoxDecoration(
                                                                  borderRadius: BorderRadius.circular(4),
                                                                  color: MyVaultColors.accentBlue.withValues(alpha: 0.2),
                                                                ),
                                                                child: Text(
                                                                  'Unit $unitNum',
                                                                  style: const TextStyle(color: MyVaultColors.accentCyan, fontSize: 10, fontWeight: FontWeight.bold),
                                                                ),
                                                              ),
                                                              const SizedBox(width: 6),
                                                              Text(
                                                                _formatContentType(type),
                                                                style: const TextStyle(
                                                                  color: Colors.white54,
                                                                  fontSize: 11,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                // View & Download Actions
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: ElevatedButton.icon(
                                                        onPressed: () => _viewPdfInApp(title, fileUrl),
                                                        icon: Icon(
                                                          type == 'VIDEO_LECTURE' ? Icons.play_arrow_rounded : Icons.picture_as_pdf_rounded,
                                                          size: 15,
                                                        ),
                                                        label: Text(type == 'VIDEO_LECTURE' ? 'Watch' : 'View PDF'),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: MyVaultColors.accentBlue,
                                                          foregroundColor: Colors.white,
                                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: OutlinedButton.icon(
                                                        onPressed: () => _downloadFile(fileUrl),
                                                        icon: const Icon(Icons.download_rounded, size: 15),
                                                        label: const Text('Download'),
                                                        style: OutlinedButton.styleFrom(
                                                          foregroundColor: MyVaultColors.accentCyan,
                                                          side: BorderSide(color: MyVaultColors.accentCyan.withValues(alpha: 0.5)),
                                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                      ] else ...[
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(10),
                                            color: Colors.white.withValues(alpha: 0.02),
                                          ),
                                          child: const Text(
                                            'No uploaded resources available for this filter.',
                                            style: TextStyle(color: Colors.white30, fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
