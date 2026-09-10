import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../core/colors.dart';
import '../academic_hub/pdf_viewer_screen.dart';
import 'screens/result_upload_analyze_screen.dart';

const String kBackendBaseUrl = 'https://romantic-serenity-production-3e5b.up.railway.app';
const String kEmulatorBackendBaseUrl = 'http://10.0.2.2:4000';

class SubjectMark {
  final String name;
  final num? marksObtained;
  final num? maxMarks;
  final String? grade;

  SubjectMark({this.name = '', this.marksObtained, this.maxMarks, this.grade});

  factory SubjectMark.fromJson(Map<String, dynamic> json) => SubjectMark(
        name: json['name'] ?? '',
        marksObtained: json['marksObtained'],
        maxMarks: json['maxMarks'],
        grade: json['grade'],
      );
}

class ResultAnalysis {
  final String? studentName;
  final String? rollNumber;
  final String? semester;
  final List<SubjectMark> subjects;
  final num? sgpa;
  final num? cgpa;
  final String? result;
  final String? aiSummary;
  final List<String> strengths;
  final List<String> improvementAreas;

  ResultAnalysis({
    this.studentName,
    this.rollNumber,
    this.semester,
    this.subjects = const [],
    this.sgpa,
    this.cgpa,
    this.result,
    this.aiSummary,
    this.strengths = const [],
    this.improvementAreas = const [],
  });

  factory ResultAnalysis.fromJson(Map<String, dynamic> json) => ResultAnalysis(
        studentName: json['studentName'],
        rollNumber: json['rollNumber'],
        semester: json['semester'],
        subjects: (json['subjects'] as List? ?? []).map((s) => SubjectMark.fromJson(s)).toList(),
        sgpa: json['sgpa'],
        cgpa: json['cgpa'],
        result: json['result'],
        aiSummary: json['aiSummary'],
        strengths: List<String>.from(json['strengths'] ?? []),
        improvementAreas: List<String>.from(json['improvementAreas'] ?? []),
      );
}

class ResultRecord {
  final String id;
  final String title;
  final ResultAnalysis analysis;
  final String pdfUrl;
  final DateTime createdAt;

  ResultRecord({
    required this.id,
    required this.title,
    required this.analysis,
    required this.pdfUrl,
    required this.createdAt,
  });

  String get fullPdfUrl => pdfUrl.startsWith('http') ? pdfUrl : '$kBackendBaseUrl$pdfUrl';

  factory ResultRecord.fromJson(Map<String, dynamic> json) => ResultRecord(
        id: json['id']?.toString() ?? '',
        title: json['title'] ?? 'Result Analysis',
        analysis: ResultAnalysis.fromJson(json['analysis'] ?? {}),
        pdfUrl: json['pdfUrl'] ?? json['pdf_url'] ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
      );
}

class ResultsService {
  Future<ResultRecord> uploadAndAnalyze({
    required File imageFile,
    String? title,
    String? studentId,
  }) async {
    final uri = Uri.parse('$kBackendBaseUrl/api/results/analyze');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    if (title != null) request.fields['title'] = title;
    if (studentId != null) request.fields['studentId'] = studentId;

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return ResultRecord.fromJson(json);
    } else {
      throw Exception('Upload failed with status: ${response.statusCode}');
    }
  }

  Future<List<ResultRecord>> fetchResults({String? studentId}) async {
    try {
      final query = studentId != null ? '?studentId=$studentId' : '';
      final uri = Uri.parse('$kBackendBaseUrl/api/results$query');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((j) => ResultRecord.fromJson(j as Map<String, dynamic>)).toList();
      }
    } catch (_) {
      // Return sample records if offline
    }

    return [
      ResultRecord(
        id: '1',
        title: 'B.Tech Sem 6 Result (Autonomous)',
        analysis: ResultAnalysis(
          studentName: 'Rahul Kumar',
          rollNumber: '1RV21CS102',
          semester: 'Semester 6',
          sgpa: 9.14,
          cgpa: 8.87,
          result: 'FIRST CLASS WITH DISTINCTION',
          aiSummary: 'Outstanding performance in Operating Systems and Distributed Cloud Networks. Demonstrates strong analytical and core computer science fundamentals.',
          strengths: ['Cloud Computing (100/100)', 'Operating Systems (94/100)', 'System Architecture'],
          improvementAreas: ['Discrete Mathematics proof structuring'],
        ),
        pdfUrl: 'https://myvault-files-app.s3.eu-north-1.amazonaws.com/notes/1786544055523-478f14f9-ade1-411b-882d-5124b5b84967-RADAR_Ashok.pdf',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      ResultRecord(
        id: '2',
        title: 'B.Tech Sem 5 Result',
        analysis: ResultAnalysis(
          studentName: 'Rahul Kumar',
          rollNumber: '1RV21CS102',
          semester: 'Semester 5',
          sgpa: 8.65,
          cgpa: 8.78,
          result: 'FIRST CLASS WITH DISTINCTION',
          aiSummary: 'Consistent upper-percentile ranking. High marks in Database Management and Software Engineering.',
          strengths: ['Database Systems', 'Algorithms'],
          improvementAreas: ['Automata Theory & Computability'],
        ),
        pdfUrl: 'https://myvault-files-app.s3.eu-north-1.amazonaws.com/notes/1786544055523-478f14f9-ade1-411b-882d-5124b5b84967-RADAR_Ashok.pdf',
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
      ),
    ];
  }
}

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key, this.studentId});
  final String? studentId;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final _service = ResultsService();

  List<ResultRecord> _results = [];
  bool _loadingList = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() {
      _loadingList = true;
      _error = null;
    });
    try {
      final results = await _service.fetchResults(studentId: widget.studentId);
      setState(() => _results = results);
    } catch (e) {
      setState(() => _error = 'Could not load results. Check your backend connection.');
    } finally {
      setState(() => _loadingList = false);
    }
  }

  Future<void> _openPdf(String title, String url) async {
    if (url.isEmpty) return;
    if (url.endsWith('.pdf')) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PdfViewerScreen(title: title, pdfUrl: url),
        ),
      );
      return;
    }
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open the PDF')));
      }
    }
  }

  void _showAnalysisSheet(ResultRecord record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                record.title,
                style: const TextStyle(color: MyVaultColors.textDark, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 14),
              _statRow('SGPA', record.analysis.sgpa?.toString() ?? '-'),
              _statRow('CGPA', record.analysis.cgpa?.toString() ?? '-'),
              _statRow('Result', record.analysis.result ?? '-'),
              const SizedBox(height: 16),
              const Text('AI Summary', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 6),
              Text(
                record.analysis.aiSummary ?? '-',
                style: const TextStyle(color: MyVaultColors.textSecondary, fontSize: 13, height: 1.4),
              ),
              if (record.analysis.strengths.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text('Key Strengths', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                ...record.analysis.strengths.map((s) => Text('• $s', style: const TextStyle(color: MyVaultColors.textSecondary, fontSize: 12))),
              ],
              if (record.analysis.improvementAreas.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text('Areas for Improvement', style: TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                ...record.analysis.improvementAreas.map((s) => Text('• $s', style: const TextStyle(color: MyVaultColors.textSecondary, fontSize: 12))),
              ],
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: MyVaultColors.metalGradient,
                  boxShadow: const [
                    BoxShadow(color: Color(0x18000000), blurRadius: 8, offset: Offset(0, 3)),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _openPdf(record.title, record.fullPdfUrl),
                  icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
                  label: const Text('Open Styled PDF Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: MyVaultColors.textMuted, fontSize: 13))),
          Text(value, style: const TextStyle(color: MyVaultColors.textDark, fontWeight: FontWeight.bold, fontSize: 15)),
        ],
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
        backgroundColor: MyVaultColors.backgroundWhite,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: MyVaultColors.metalBlack, size: 20),
            onPressed: () => context.go('/home'),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: MyVaultColors.metalGradient,
                ),
                child: const Icon(Icons.auto_graph_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Results & AI Analyzer',
                style: TextStyle(fontWeight: FontWeight.bold, color: MyVaultColors.metalBlack, fontSize: 18),
              ),
            ],
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: Color(0xFFE2E8F0)),
          ),
        ),
        floatingActionButton: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: MyVaultColors.metalGradient,
            boxShadow: const [
              BoxShadow(color: Color(0x20000000), blurRadius: 10, offset: Offset(0, 4)),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ResultUploadAnalyzeScreen()),
              );
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
            label: const Text('Performance Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: MyVaultColors.whiteShadingGradient,
          ),
          child: RefreshIndicator(
            onRefresh: _loadResults,
            color: MyVaultColors.metalBlack,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Banner for Performance Dashboard Launch
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ResultUploadAnalyzeScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                      boxShadow: const [
                        BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: MyVaultColors.metalGradient,
                          ),
                          child: const Icon(Icons.insights_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Performance Dashboard & AI OCR',
                                style: TextStyle(color: MyVaultColors.textDark, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Upload marksheet -> AI OCR -> SGPA & GPA Trend charts.',
                                style: TextStyle(color: MyVaultColors.textSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, color: MyVaultColors.metalBlack, size: 16),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                if (_loadingList)
                  const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: MyVaultColors.metalBlack)))
                else if (_results.isEmpty)
                  ListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 40),
                      const Icon(Icons.insert_drive_file_outlined, size: 64, color: Color(0xFFCBD5E1)),
                      const SizedBox(height: 12),
                      const Center(
                        child: Text(
                          'No results yet.\nUpload a marksheet image to get an\nAI-analyzed, styled PDF report.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: MyVaultColors.textMuted, height: 1.4),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent))),
                      ],
                    ],
                  )
                else
                  ..._results.map((record) => Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: const [
                            BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4)),
                          ],
                        ),
                        child: ListTile(
                          onTap: () => _showAnalysisSheet(record),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: MyVaultColors.metalGradient,
                            ),
                            child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 20),
                          ),
                          title: Text(
                            record.title,
                            style: const TextStyle(color: MyVaultColors.textDark, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'SGPA ${record.analysis.sgpa ?? '-'}  •  CGPA ${record.analysis.cgpa ?? '-'}  •  ${record.analysis.result ?? '-'}',
                              style: const TextStyle(color: MyVaultColors.textSecondary, fontSize: 12),
                            ),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, color: MyVaultColors.textMuted, size: 16),
                        ),
                      )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
