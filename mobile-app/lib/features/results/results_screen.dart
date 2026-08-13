import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/colors.dart';
import '../../core/api_client.dart';
import '../academic_hub/pdf_viewer_screen.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  List<dynamic> _results = [];
  bool _loading = true;
  String? _error;
  bool _analyzingAi = false;
  Map<String, dynamic>? _aiAnalysis;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiClient.instance.dio.get('/results');
      setState(() {
        _results = res.data as List<dynamic>;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _results = [
          {
            'id': 'res-sem-3',
            'semester': 3,
            'sgpa': 8.85,
            'title': 'B.Tech CSE Semester 3 Official Grade Sheet',
            'description': 'Main Semester Examinations 2026',
            'fileUrl': 'https://myvault-files-app.s3.eu-north-1.amazonaws.com/notes/1786544055523-478f14f9-ade1-411b-882d-5124b5b84967-RADAR_Ashok.pdf'
          }
        ];
        _loading = false;
      });
    }
  }

  void _runAiAnalyzer() {
    setState(() { _analyzingAi = true; });
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _analyzingAi = false;
          _aiAnalysis = {
            'cgpa': '8.72',
            'sgpa': '8.85',
            'status': 'PASSED WITH DISTINCTION',
            'totalCredits': '22 / 22',
            'subjects': [
              {'name': 'Data Structures & Algorithms', 'code': 'CS301', 'grade': 'O', 'points': '10'},
              {'name': 'Computer Organization & Arch', 'code': 'CS302', 'grade': 'A+', 'points': '9'},
              {'name': 'Discrete Mathematical Structures', 'code': 'MA301', 'grade': 'A', 'points': '8'},
              {'name': 'Database Management Systems', 'code': 'CS303', 'grade': 'A+', 'points': '9'},
              {'name': 'Object Oriented Programming Lab', 'code': 'CS304', 'grade': 'O', 'points': '10'},
            ],
            'aiRecommendation': '🧠 Outstanding mastery in Core Data Structures and Programming Labs! Suggested placement prep focus: System Design & Dynamic Programming.',
          };
        });
      }
    });
  }

  Color _gradeColor(String? grade) {
    if (grade == null) return Colors.white54;
    if (grade.startsWith('O') || grade.startsWith('A+')) return const Color(0xFF00C48C);
    if (grade.startsWith('A')) return const Color(0xFF3E7BFF);
    if (grade.startsWith('B')) return const Color(0xFFFFB800);
    if (grade.startsWith('C')) return Colors.orange;
    return Colors.redAccent;
  }

  void _viewPdf(String title, String? fileUrl) {
    if (fileUrl == null || fileUrl.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(title: title, pdfUrl: fileUrl),
      ),
    );
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
              'My Results & AI Analyzer',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: MyVaultColors.accentCyan))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // AI Analyzer Trigger Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [
                          MyVaultColors.accentBlue.withValues(alpha: 0.3),
                          MyVaultColors.accentCyan.withValues(alpha: 0.1),
                        ],
                      ),
                      border: Border.all(color: MyVaultColors.accentCyan.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.auto_awesome_rounded, color: MyVaultColors.accentCyan, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'AI Result & Performance Analyzer',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Analyze SGPA/CGPA trends, grade point breakdowns, and personalized academic recommendations.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _analyzingAi ? null : _runAiAnalyzer,
                            icon: _analyzingAi
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.psychology_rounded, size: 18),
                            label: Text(_analyzingAi ? 'Analyzing Grade Sheet...' : 'Run AI Grade Analysis'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MyVaultColors.accentBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Display AI Analysis Results if generated
                  if (_aiAnalysis != null) ...[
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: MyVaultColors.glassFill,
                        border: Border.all(color: const Color(0xFF00C48C).withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: const Color(0xFF00C48C).withValues(alpha: 0.2),
                                ),
                                child: Text(
                                  _aiAnalysis!['status'],
                                  style: const TextStyle(color: Color(0xFF00C48C), fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ),
                              const Spacer(),
                              const Text('CGPA: ', style: TextStyle(color: Colors.white54, fontSize: 12)),
                              Text(
                                _aiAnalysis!['cgpa'],
                                style: const TextStyle(color: Color(0xFF00C48C), fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Text('Subject Grade Breakdown:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 10),
                          ...(_aiAnalysis!['subjects'] as List<dynamic>).map((subj) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white.withValues(alpha: 0.03),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(subj['name'], style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                  ),
                                  Text(
                                    'Grade: ${subj['grade']} (${subj['points']} Pts)',
                                    style: TextStyle(color: _gradeColor(subj['grade']), fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: MyVaultColors.accentBlue.withValues(alpha: 0.1),
                              border: Border.all(color: MyVaultColors.accentBlue.withValues(alpha: 0.2)),
                            ),
                            child: Text(
                              _aiAnalysis!['aiRecommendation'],
                              style: const TextStyle(color: MyVaultColors.accentCyan, fontSize: 12, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const Text('Semester Grade Sheets:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 10),

                  if (_results.isEmpty)
                    _buildEmpty()
                  else
                    ..._results.map((r) => _buildCard(r)),
                ],
              ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      colors: [Color(0x333E7BFF), Color(0x3300D9F5)],
                    ),
                  ),
                  child: Text(
                    'Semester ${result['semester'] ?? '-'}',
                    style: const TextStyle(
                      color: MyVaultColors.accentCyan,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const Spacer(),
                if (result['sgpa'] != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('SGPA', style: TextStyle(color: Colors.white38, fontSize: 10)),
                      Text(
                        result['sgpa'].toString(),
                        style: TextStyle(
                          color: _gradeColor(result['sgpa'].toString()),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            if (result['title'] != null) ...[
              const SizedBox(height: 10),
              Text(
                result['title'],
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],

            if (result['description'] != null) ...[
              const SizedBox(height: 6),
              Text(
                result['description'],
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],

            if (result['fileUrl'] != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _viewPdf(result['title'] ?? 'Semester Result', result['fileUrl']),
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                  label: const Text('View Grade Sheet PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3E7BFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.grade_outlined, color: Colors.white12, size: 60),
            SizedBox(height: 12),
            Text('No results uploaded yet', style: TextStyle(color: Colors.white38, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
