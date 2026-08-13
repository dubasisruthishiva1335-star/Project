import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api_client.dart';
import '../../core/colors.dart';

const _branches = ['CSE', 'ECE', 'AI_ML', 'EEE', 'MECH', 'CIVIL', 'GENERAL'];

class AcademicHubScreen extends StatefulWidget {
  const AcademicHubScreen({super.key});

  @override
  State<AcademicHubScreen> createState() => _AcademicHubScreenState();
}

class _AcademicHubScreenState extends State<AcademicHubScreen> {
  String _branch = 'CSE';
  int _year = 1;
  List<dynamic> _subjects = [];
  bool _loading = true;
  String? _error;

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
        'year': _year,
      });
      setState(() => _subjects = res.data as List<dynamic>);
    } catch (e) {
      setState(() => _error = "Couldn't load live data — showing cached view.");
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _openPdf(String? fileUrl, {bool isDownload = false}) async {
    if (fileUrl == null || fileUrl.isEmpty) return;
    final uri = Uri.tryParse(fileUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatContentType(String? raw) {
    if (raw == null) return 'Resource';
    switch (raw.toUpperCase()) {
      case 'NOTES':
        return 'Lecture Notes';
      case 'SYLLABUS':
        return 'Syllabus';
      case 'QUESTION_BANK':
        return 'Question Bank';
      case 'LAB_MANUAL':
        return 'Lab Manual';
      default:
        return raw.replaceAll('_', ' ');
    }
  }

  IconData _getContentIcon(String? raw) {
    if (raw == null) return Icons.picture_as_pdf_rounded;
    switch (raw.toUpperCase()) {
      case 'NOTES':
        return Icons.description_outlined;
      case 'SYLLABUS':
        return Icons.list_alt_rounded;
      case 'QUESTION_BANK':
        return Icons.quiz_outlined;
      case 'LAB_MANUAL':
        return Icons.science_outlined;
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
              'Academic Hub',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Branch and Year Selectors
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
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
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: MyVaultColors.glassFill,
                          border: Border.all(color: MyVaultColors.glassBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _year,
                            dropdownColor: const Color(0xFF141722),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: MyVaultColors.accentCyan),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            items: List.generate(4, (i) => i + 1)
                                .map((y) => DropdownMenuItem(value: y, child: Text('Year $y')))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _year = v);
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

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(_error!, style: const TextStyle(color: Colors.orangeAccent, fontSize: 12)),
                ),

              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: MyVaultColors.accentCyan))
                    : _subjects.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.menu_book_rounded, color: Colors.white12, size: 64),
                                const SizedBox(height: 16),
                                Text(
                                  'No subjects found for $_branch (Year $_year)',
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
                                final contents = (subject['contents'] as List<dynamic>? ?? []);
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
                                        const Text(
                                          'Uploaded Resources:',
                                          style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ...contents.map((c) {
                                          final item = c as Map<String, dynamic>;
                                          final type = item['contentType'] as String?;
                                          final title = item['title'] as String? ?? _formatContentType(type);
                                          final fileUrl = item['fileUrl'] as String?;
                                          final icon = _getContentIcon(type);

                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 8),
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
                                                    Icon(icon, color: MyVaultColors.accentCyan, size: 20),
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
                                                              fontSize: 13,
                                                            ),
                                                          ),
                                                          Text(
                                                            _formatContentType(type),
                                                            style: const TextStyle(
                                                              color: MyVaultColors.accentBlue,
                                                              fontSize: 11,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 10),
                                                // Action Buttons (View PDF & Download PDF)
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: ElevatedButton.icon(
                                                        onPressed: () => _openPdf(fileUrl),
                                                        icon: const Icon(Icons.picture_as_pdf_rounded, size: 14),
                                                        label: const Text('View PDF'),
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
                                                        onPressed: () => _openPdf(fileUrl, isDownload: true),
                                                        icon: const Icon(Icons.download_rounded, size: 14),
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
                                            'No uploaded resources available yet.',
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
