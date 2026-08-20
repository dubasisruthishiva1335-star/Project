import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/colors.dart';
import '../../core/api_client.dart';
import 'exam_certificate_screen.dart';

class ExamVideoScreen extends StatefulWidget {
  final String examName;
  final String category;
  final List<dynamic> initialVideos;

  const ExamVideoScreen({
    super.key,
    required this.examName,
    required this.category,
    required this.initialVideos,
  });

  @override
  State<ExamVideoScreen> createState() => _ExamVideoScreenState();
}

class _ExamVideoScreenState extends State<ExamVideoScreen> {
  List<dynamic> _videos = [];
  final Set<String> _watchedVideoIds = {};
  bool _loading = true;
  bool _generatingCert = false;
  int _activeVideoIndex = 0;

  @override
  void initState() {
    super.initState();
    _videos = widget.initialVideos;
    _fetchExamVideos();
  }

  Future<void> _fetchExamVideos() async {
    try {
      final res = await ApiClient.instance.dio.get('/api/exams/${Uri.encodeComponent(widget.examName)}/videos');
      final data = res.data as Map<String, dynamic>;
      final fetched = data['videos'] as List<dynamic>?;
      if (fetched != null && fetched.isNotEmpty) {
        setState(() {
          _videos = fetched;
          _loading = false;
        });
        return;
      }
    } catch (_) {}
    setState(() => _loading = false);
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

    // Save progress to API
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
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 17),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: MyVaultColors.accentCyan))
          : Column(
              children: [
                // Video Stream Player Screen Banner
                Container(
                  width: double.infinity,
                  height: 210,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              MyVaultColors.accentBlue.withValues(alpha: 0.3),
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
                              width: 64,
                              height: 64,
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
                              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              activeVideo?['title'] ?? 'Select a Video Lecture',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'AWS S3 Stream • ${activeVideo?['duration'] ?? '15:00'}',
                            style: const TextStyle(color: MyVaultColors.accentCyan, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Progress Tracker Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: MyVaultColors.glassFill,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Course Completion Progress',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${(_progressPercentage * 100).toInt()}% Complete',
                            style: const TextStyle(color: MyVaultColors.accentCyan, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: _progressPercentage,
                          minHeight: 8,
                          backgroundColor: Colors.white10,
                          valueColor: const AlwaysStoppedAnimation<Color>(MyVaultColors.accentCyan),
                        ),
                      ),
                    ],
                  ),
                ),

                // Video Playlist Title
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Row(
                    children: [
                      Icon(Icons.video_library_rounded, color: MyVaultColors.accentCyan, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'AWS S3 Video Lectures & Materials',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                // Playlist
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
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
                          color: isSelected ? MyVaultColors.accentBlue.withValues(alpha: 0.15) : MyVaultColors.glassFill,
                          border: Border.all(
                            color: isSelected ? MyVaultColors.accentCyan : MyVaultColors.glassBorder,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: isWatched ? Colors.green.withValues(alpha: 0.2) : MyVaultColors.accentBlue.withValues(alpha: 0.2),
                            child: Icon(
                              isWatched ? Icons.check_circle_rounded : Icons.play_arrow_rounded,
                              color: isWatched ? Colors.greenAccent : MyVaultColors.accentCyan,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            v['title'] ?? 'Lecture ${i + 1}',
                            style: TextStyle(
                              color: isSelected ? MyVaultColors.accentCyan : Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'Duration: ${v['duration'] ?? '15:00'} • ${v['subject'] ?? 'General'}',
                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (v['pdfUrl'] != null)
                                IconButton(
                                  icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.amber, size: 20),
                                  onPressed: () => _openPdf(v['pdfUrl']),
                                ),
                              IconButton(
                                icon: const Icon(Icons.play_circle_fill_rounded, color: MyVaultColors.accentCyan, size: 22),
                                onPressed: () => _playVideo(i),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Certificate Action Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: MyVaultColors.obsidian,
                    border: Border(top: BorderSide(color: MyVaultColors.glassBorder)),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _generatingCert ? null : _generateCertificate,
                      icon: _generatingCert
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 20),
                      label: Text(
                        _generatingCert ? 'Generating S3 Certificate...' : 'Get Verified S3 Certificate',
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
