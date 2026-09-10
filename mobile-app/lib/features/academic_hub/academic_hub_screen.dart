import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api_client.dart';
import '../../core/colors.dart';
import 'academic_curriculum_data.dart';
import 'pdf_viewer_screen.dart';

const _branches = ['CSE', 'ECE', 'AI_ML', 'EEE', 'MECH', 'CIVIL', 'GENERAL'];

class AcademicHubScreen extends StatefulWidget {
  const AcademicHubScreen({super.key});

  @override
  State<AcademicHubScreen> createState() => _AcademicHubScreenState();
}

class _AcademicHubScreenState extends State<AcademicHubScreen> {
  String _branch = 'ECE';
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

    final defaultSubjects = AcademicCurriculumData.getSubjects(_branch, _semester);

    try {
      final res = await ApiClient.instance.dio.get('/subjects', queryParameters: {
        'branch': _branch,
        'semester': _semester,
      });
      final serverData = res.data as List<dynamic>;

      if (serverData.isEmpty) {
        setState(() {
          _subjects = defaultSubjects;
        });
      } else {
        final Map<String, Map<String, dynamic>> subjectMap = {};

        for (final ds in defaultSubjects) {
          final code = (ds['code'] ?? '').toString().toUpperCase();
          subjectMap[code] = Map<String, dynamic>.from(ds);
        }

        for (final ss in serverData) {
          if (ss is Map<String, dynamic>) {
            final code = (ss['code'] ?? '').toString().toUpperCase();
            if (subjectMap.containsKey(code)) {
              final existingContents = List<dynamic>.from(subjectMap[code]!['contents'] as List<dynamic>? ?? []);
              final serverContents = ss['contents'] as List<dynamic>? ?? [];
              
              final Set<String> existingKeys = existingContents.map((c) => '${c['title']}_${c['unit']}').toSet();
              for (final sc in serverContents) {
                final key = '${sc['title']}_${sc['unit']}';
                if (!existingKeys.contains(key)) {
                  existingContents.add(sc);
                }
              }
              subjectMap[code]!['contents'] = existingContents;
              if (ss['name'] != null && (ss['name'] as String).isNotEmpty) {
                subjectMap[code]!['name'] = ss['name'];
              }
            } else {
              subjectMap[code] = ss;
            }
          }
        }

        setState(() {
          _subjects = subjectMap.values.toList();
        });
      }
    } catch (e) {
      setState(() {
        _subjects = defaultSubjects;
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
        backgroundColor: MyVaultColors.backgroundWhite,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: MyVaultColors.metalBlack),
            onPressed: () => context.go('/home'),
          ),
          title: const Text(
            'Academic Study Repository',
            style: TextStyle(fontWeight: FontWeight.bold, color: MyVaultColors.metalBlack, fontSize: 18),
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: Color(0xFFE2E8F0)),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: MyVaultColors.whiteShadingGradient,
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Branch & Semester Selectors
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      // Branch Selector
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                            boxShadow: const [
                              BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2)),
                            ],
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _branch,
                              dropdownColor: Colors.white,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: MyVaultColors.metalBlack),
                              style: const TextStyle(color: MyVaultColors.textDark, fontWeight: FontWeight.bold, fontSize: 13),
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
                            borderRadius: BorderRadius.circular(14),
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                            boxShadow: const [
                              BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2)),
                            ],
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _semester,
                              dropdownColor: Colors.white,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: MyVaultColors.metalBlack),
                              style: const TextStyle(color: MyVaultColors.textDark, fontWeight: FontWeight.bold, fontSize: 13),
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
                        selectedColor: MyVaultColors.metalBlack,
                        backgroundColor: Colors.white,
                        side: BorderSide(color: selected ? MyVaultColors.metalBlack : const Color(0xFFCBD5E1)),
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : MyVaultColors.textSecondary,
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
                        selectedColor: const Color(0xFFE2E8F0),
                        backgroundColor: Colors.white,
                        side: BorderSide(color: selected ? MyVaultColors.metalBlack : const Color(0xFFCBD5E1)),
                        labelStyle: TextStyle(
                          color: selected ? MyVaultColors.metalBlack : MyVaultColors.textSecondary,
                          fontSize: 12,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        ),
                        checkmarkColor: MyVaultColors.metalBlack,
                      ),
                    );
                  }).toList(),
                ),
              ),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(_error!, style: const TextStyle(color: Colors.orangeAccent, fontSize: 12)),
                      ),
                      TextButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh_rounded, size: 14, color: MyVaultColors.metalBlack),
                        label: const Text('Retry', style: TextStyle(color: MyVaultColors.metalBlack, fontSize: 12)),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 6),

              // Main List
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: MyVaultColors.metalBlack))
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: MyVaultColors.metalBlack,
                        child: _subjects.isEmpty
                            ? LayoutBuilder(
                                builder: (context, constraints) => SingleChildScrollView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.folder_open_rounded, color: Color(0xFF94A3B8), size: 64),
                                          const SizedBox(height: 16),
                                          Text(
                                            'No subjects found for $_branch (Sem $_semester)',
                                            style: const TextStyle(color: MyVaultColors.textMuted, fontSize: 14),
                                          ),
                                          const SizedBox(height: 12),
                                          ElevatedButton.icon(
                                            onPressed: _load,
                                            icon: const Icon(Icons.refresh_rounded, size: 16),
                                            label: const Text('Refresh', style: TextStyle(fontSize: 12)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: MyVaultColors.metalBlack,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : ListView.builder(
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
                                      borderRadius: BorderRadius.circular(20),
                                      color: Colors.white,
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
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
                                                gradient: MyVaultColors.metalGradient,
                                              ),
                                              child: Text(
                                                subject['code'] ?? 'SUBJ',
                                                style: const TextStyle(
                                                  color: Colors.white,
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
                                                  color: MyVaultColors.textDark,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
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
                                                color: const Color(0xFFF8FAFC),
                                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.all(6),
                                                        decoration: BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius: BorderRadius.circular(8),
                                                          border: Border.all(color: const Color(0xFFE2E8F0)),
                                                        ),
                                                        child: Icon(icon, color: MyVaultColors.metalBlack, size: 18),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              title,
                                                              style: const TextStyle(
                                                                color: MyVaultColors.textDark,
                                                                fontWeight: FontWeight.w600,
                                                                fontSize: 13,
                                                              ),
                                                            ),
                                                            const SizedBox(height: 2),
                                                            Row(
                                                              children: [
                                                                Container(
                                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                                  decoration: BoxDecoration(
                                                                    borderRadius: BorderRadius.circular(4),
                                                                    color: const Color(0xFFE2E8F0),
                                                                  ),
                                                                  child: Text(
                                                                    'Unit $unitNum',
                                                                    style: const TextStyle(color: MyVaultColors.textDark, fontSize: 10, fontWeight: FontWeight.bold),
                                                                  ),
                                                                ),
                                                                const SizedBox(width: 6),
                                                                Text(
                                                                  _formatContentType(type),
                                                                  style: const TextStyle(
                                                                    color: MyVaultColors.textMuted,
                                                                    fontSize: 11,
                                                                  ),
                                                                ),
                                                                if (item['uploadedAt'] != null) ...[
                                                                  const SizedBox(width: 6),
                                                                  const Text('•', style: TextStyle(color: MyVaultColors.textLight, fontSize: 10)),
                                                                  const SizedBox(width: 6),
                                                                  const Text('Verified', style: TextStyle(color: Color(0xFF059669), fontSize: 10, fontWeight: FontWeight.bold)),
                                                                ],
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 10),
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
                                                            backgroundColor: MyVaultColors.metalBlack,
                                                            foregroundColor: Colors.white,
                                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                            elevation: 0,
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
                                                            foregroundColor: MyVaultColors.metalBlack,
                                                            side: const BorderSide(color: Color(0xFFCBD5E1)),
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
                                          const Padding(
                                            padding: EdgeInsets.symmetric(vertical: 8),
                                            child: Text('No contents uploaded yet.', style: TextStyle(color: MyVaultColors.textMuted, fontSize: 12)),
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
    ),
    );
  }
}
