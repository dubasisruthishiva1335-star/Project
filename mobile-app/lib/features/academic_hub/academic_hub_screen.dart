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
                                  margin: const EdgeInsets.only(bottom: 14),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: MyVaultColors.glassFill,
                                    border: Border.all(color: MyVaultColors.glassBorder),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(6),
                                              color: MyVaultColors.accentBlue.withValues(alpha: 0.2),
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
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              subject['name'] ?? '',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (contents.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: contents.map((c) {
                                            final item = c as Map<String, dynamic>;
                                            final type = item['contentType'] ?? 'File';
                                            final fileUrl = item['fileUrl'] as String?;
                                            return ActionChip(
                                              avatar: const Icon(Icons.picture_as_pdf_rounded, size: 14, color: MyVaultColors.accentCyan),
                                              label: Text(type.toString().replaceAll('_', ' ')),
                                              backgroundColor: MyVaultColors.glassFill,
                                              side: const BorderSide(color: MyVaultColors.glassBorder),
                                              labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                                              onPressed: () async {
                                                if (fileUrl != null && fileUrl.isNotEmpty) {
                                                  final uri = Uri.tryParse(fileUrl);
                                                  if (uri != null && await canLaunchUrl(uri)) {
                                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                                  }
                                                }
                                              },
                                            );
                                          }).toList(),
                                        ),
                                      ] else ...[
                                        const SizedBox(height: 8),
                                        const Text(
                                          'No PDF resources uploaded yet',
                                          style: TextStyle(color: Colors.white24, fontSize: 12),
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
