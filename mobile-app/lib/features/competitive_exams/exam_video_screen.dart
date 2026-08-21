import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/colors.dart';
import '../../core/api_client.dart';
import 'exam_certificate_screen.dart';

class ExamVideoScreen extends StatefulWidget {
  final String examName;
  final String category;
  final List<dynamic> initialVideos;
  final List<dynamic>? initialPdfNotes;
  final String? syllabusSummary;
  final String? selectionProcess;

  const ExamVideoScreen({
    super.key,
    required this.examName,
    required this.category,
    required this.initialVideos,
    this.initialPdfNotes,
    this.syllabusSummary,
    this.selectionProcess,
  });

  @override
  State<ExamVideoScreen> createState() => _ExamVideoScreenState();
}

class _ExamVideoScreenState extends State<ExamVideoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _prepTabController;
  List<dynamic> _videos = [];
  List<dynamic> _pdfNotes = [];
  final Set<String> _watchedVideoIds = {};
  bool _loading = true;
  bool _generatingCert = false;
  int _activeVideoIndex = 0;

  @override
  void initState() {
    super.initState();
    _prepTabController = TabController(length: 4, vsync: this);
    _videos = widget.initialVideos;
    _pdfNotes = widget.initialPdfNotes ?? [];
    _fetchExamDetails();
  }

  @override
  void dispose() {
    _prepTabController.dispose();
    super.dispose();
  }

  Future<void> _fetchExamDetails() async {
    try {
      final res = await ApiClient.instance.dio.get('/api/exams/${Uri.encodeComponent(widget.examName)}');
      final data = res.data as Map<String, dynamic>;
      final fetchedVideos = data['videos'] as List<dynamic>?;
      final fetchedPdfs = data['pdfNotes'] as List<dynamic>?;

      setState(() {
        if (fetchedVideos != null && fetchedVideos.isNotEmpty) _videos = fetchedVideos;
        if (fetchedPdfs != null && fetchedPdfs.isNotEmpty) _pdfNotes = fetchedPdfs;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  double get _progressPercentage {
    if (_videos.isEmpty) return 0.0;
    return (_watchedVideoIds.length / _videos.length).clamp(0.0, 1.0);
  }

  Future<void> _playVideo(int index) async {
    setState(() {
      _activeVideoIndex = index;
    });
    final v = _videos[index];
    final videoId = v['id'] as String? ?? 'v_$index';
    _watchedVideoIds.add(videoId);

    try {
      await ApiClient.instance.dio.post('/api/exams/progress', data: {
        'userId': 'user123',
        'examName': widget.examName,
        'videoId': videoId,
      });
    } catch (_) {}

    setState(() {});

    final url = v['s3Url'] as String?;
    if (url != null && url.isNotEmpty) {
      final uri = Uri.tryParse(url);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  Future<void> _openPdf(String? pdfUrl) async {
    if (pdfUrl == null || pdfUrl.isEmpty) return;
    final uri = Uri.tryParse(pdfUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _generateCertificate() async {
    setState(() => _generatingCert = true);
    try {
      final res = await ApiClient.instance.dio.post('/api/exams/certificate', data: {
        'userId': 'user123',
        'userName': 'Rahul Kumar',
        'examName': widget.examName,
      });

      final data = res.data as Map<String, dynamic>;
      final pdfUrl = data['certificateUrl'] as String? ?? 'https://myvault-files-app.s3.eu-north-1.amazonaws.com/app-arm64-v8a-release.apk';
      final certNum = data['certificateNumber'] as String? ?? 'MV-EXAM-2026-884920';

      if (mounted) {
        setState(() => _generatingCert = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExamCertificateScreen(
              studentName: 'Rahul Kumar',
              examName: widget.examName,
              certificateNumber: certNum,
              pdfUrl: pdfUrl,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _generatingCert = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate certificate: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeVideo = _videos.isNotEmpty ? _videos[_activeVideoIndex] : null;

    return Scaffold(
      backgroundColor: MyVaultColors.obsidian,
      appBar: AppBar(
        backgroundColor: MyVaultColors.obsidian,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.examName,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
        ),
        bottom: TabBar(
          controller: _prepTabController,
          indicatorColor: MyVaultColors.accentCyan,
          labelColor: MyVaultColors.accentCyan,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(icon: Icon(Icons.play_circle_fill_rounded, size: 18), text: 'Lectures'),
            Tab(icon: Icon(Icons.picture_as_pdf_rounded, size: 18), text: 'S3 Notes'),
            Tab(icon: Icon(Icons.menu_book_rounded, size: 18), text: 'Syllabus'),
            Tab(icon: Icon(Icons.workspace_premium_rounded, size: 18), text: 'Certificate'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: MyVaultColors.accentCyan))
          : TabBarView(
              controller: _prepTabController,
              children: [
                // TAB 1: S3 Video Lectures Player & Playlist
                Column(
                  children: [
                    // Stream Player Card
                    Container(
                      width: double.infinity,
                      height: 200,
                      color: Colors.black,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  MyVaultColors.accentBlue.withValues(alpha: 0.35),
                                  MyVaultColors.obsidian,
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () => _playVideo(_activeVideoIndex),
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: MyVaultColors.accentGradient,
                                    boxShadow: [
                                      BoxShadow(
                                        color: MyVaultColors.accentCyan.withValues(alpha: 0.4),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Text(
                                  activeVideo?['title'] ?? 'Select a Video Lecture',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'AWS S3 Stream • ${activeVideo?['duration'] ?? '20:00'}',
                                style: const TextStyle(color: MyVaultColors.accentCyan, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Progress Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      color: MyVaultColors.glassFill,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Lecture Completion', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              Text('${(_progressPercentage * 100).toInt()}% Done', style: const TextStyle(color: MyVaultColors.accentCyan, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _progressPercentage,
                              minHeight: 6,
                              backgroundColor: Colors.white10,
                              valueColor: const AlwaysStoppedAnimation<Color>(MyVaultColors.accentCyan),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Playlist
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _videos.length,
                        itemBuilder: (ctx, i) {
                          final v = _videos[i];
                          final vId = v['id'] as String? ?? 'v_$i';
                          final isWatched = _watchedVideoIds.contains(vId);
                          final isSelected = i == _activeVideoIndex;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: isSelected ? MyVaultColors.accentBlue.withValues(alpha: 0.18) : MyVaultColors.glassFill,
                              border: Border.all(
                                color: isSelected ? MyVaultColors.accentCyan : MyVaultColors.glassBorder,
                              ),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                radius: 18,
                                backgroundColor: isWatched ? Colors.green.withValues(alpha: 0.2) : MyVaultColors.accentBlue.withValues(alpha: 0.2),
                                child: Icon(
                                  isWatched ? Icons.check_circle_rounded : Icons.play_arrow_rounded,
                                  color: isWatched ? Colors.greenAccent : MyVaultColors.accentCyan,
                                  size: 18,
                                ),
                              ),
                              title: Text(
                                v['title'] ?? 'Lecture ${i + 1}',
                                style: TextStyle(
                                  color: isSelected ? MyVaultColors.accentCyan : Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                'Duration: ${v['duration'] ?? '20:00'} • ${v['subject'] ?? 'General'}',
                                style: const TextStyle(color: Colors.white54, fontSize: 11),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.play_circle_fill_rounded, color: MyVaultColors.accentCyan, size: 22),
                                onPressed: () => _playVideo(i),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                // TAB 2: PDF Notes & Previous Year Questions (PYQs)
                ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: _pdfNotes.length,
                  itemBuilder: (ctx, i) {
                    final pdf = _pdfNotes[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: MyVaultColors.glassFill,
                        border: Border.all(color: MyVaultColors.glassBorder),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.amber.withValues(alpha: 0.15),
                          ),
                          child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.amber, size: 22),
                        ),
                        title: Text(
                          pdf['title'] ?? 'Study Material PDF',
                          style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Subject: ${pdf['subject'] ?? 'General'} • Stored on AWS S3',
                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                        trailing: ElevatedButton.icon(
                          onPressed: () => _openPdf(pdf['fileUrl']),
                          icon: const Icon(Icons.open_in_new_rounded, color: Colors.white, size: 12),
                          label: const Text('Open PDF', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MyVaultColors.accentBlue,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // TAB 3: Syllabus & Exam Pattern Roadmap
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📜 Official Exam Pattern & Selection Process',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: MyVaultColors.glassFill,
                          border: Border.all(color: MyVaultColors.glassBorder),
                        ),
                        child: Text(
                          widget.selectionProcess ?? 'Written Examination ➔ Document Verification ➔ Selection',
                          style: const TextStyle(color: MyVaultColors.accentCyan, fontSize: 13, height: 1.4),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        '📚 Syllabus Overview & Weightage',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: MyVaultColors.glassFill,
                          border: Border.all(color: MyVaultColors.glassBorder),
                        ),
                        child: Text(
                          widget.syllabusSummary ?? 'General Studies, Aptitude, Core Technical Subjects & Current Affairs.',
                          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),

                // TAB 4: Verified Certificate Desk
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.workspace_premium_rounded, size: 80, color: Colors.amber),
                        const SizedBox(height: 16),
                        const Text(
                          'S3 Verified Certification Desk',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Complete all S3 video lectures and study materials for ${widget.examName} to unlock your official verified certificate.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white54, fontSize: 12.5),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _generatingCert ? null : _generateCertificate,
                            icon: _generatingCert
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.verified_rounded, color: Colors.white),
                            label: Text(
                              _generatingCert ? 'Generating Certificate...' : 'Generate S3 Verified Certificate',
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
