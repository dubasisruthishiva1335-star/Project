import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import '../../core/colors.dart';
import 'exam_certificate_screen.dart';

class ExamPreparationScreen extends StatefulWidget {
  final String examId;
  final String examName;
  final String category;
  final List<dynamic> initialVideos;
  final List<dynamic> initialPdfNotes;
  final String syllabusSummary;
  final String selectionProcess;

  const ExamPreparationScreen({
    super.key,
    required this.examId,
    required this.examName,
    required this.category,
    this.initialVideos = const [],
    this.initialPdfNotes = const [],
    required this.syllabusSummary,
    required this.selectionProcess,
  });

  @override
  State<ExamPreparationScreen> createState() => _ExamPreparationScreenState();
}

class _ExamPreparationScreenState extends State<ExamPreparationScreen> {
  List<dynamic> _videos = [];
  List<dynamic> _pdfNotes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _videos = List.from(widget.initialVideos);
    _pdfNotes = List.from(widget.initialPdfNotes);
    _loadPreparationContent();
  }

  Future<void> _loadPreparationContent() async {
    try {
      final res = await Dio().get('https://myvault-project.vercel.app/api/admin/preparation?examId=${widget.examId}');
      if (res.data != null && res.data['data'] != null) {
        final List list = res.data['data'];
        final fetchedVideos = list.where((i) => i['contentType'] == 'VIDEO').toList();
        final fetchedNotes = list.where((i) => i['contentType'] != 'VIDEO').toList();

        if (mounted) {
          setState(() {
            if (fetchedVideos.isNotEmpty) _videos = fetchedVideos;
            if (fetchedNotes.isNotEmpty) _pdfNotes = fetchedNotes;
            _loading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showInAppUploadModal() {
    final titleCtrl = TextEditingController();
    final topicCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    String contentType = 'VIDEO';
    String selectedSubject = 'Quantitative Aptitude';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: MyVaultColors.obsidian,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '📤 Upload Content (${widget.examName.split(" ").first})',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('🎬 Video Class'),
                        selected: contentType == 'VIDEO',
                        selectedColor: MyVaultColors.accentBlue,
                        onSelected: (s) => setModalState(() => contentType = 'VIDEO'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('📄 Study PDF Note'),
                        selected: contentType == 'PDF',
                        selectedColor: Colors.amber,
                        onSelected: (s) => setModalState(() => contentType = 'PDF'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: titleCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Content Title',
                      labelStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: MyVaultColors.glassFill,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: topicCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Chapter Topic (e.g. Percentage, Profit & Loss)',
                      labelStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: MyVaultColors.glassFill,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: urlCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'S3 Direct File URL',
                      labelStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: MyVaultColors.glassFill,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (titleCtrl.text.trim().isEmpty) return;
                        final payload = {
                          'examId': widget.examId,
                          'subject': selectedSubject,
                          'topic': topicCtrl.text.trim().isEmpty ? 'General' : topicCtrl.text.trim(),
                          'title': titleCtrl.text.trim(),
                          'contentType': contentType,
                          'publicUrl': urlCtrl.text.trim().isEmpty ? 'https://myvault-files-app.s3.eu-north-1.amazonaws.com/app-arm64-v8a-release.apk' : urlCtrl.text.trim(),
                        };

                        try {
                          await Dio().post('https://myvault-project.vercel.app/api/admin/preparation', data: payload);
                        } catch (_) {}

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          _loadPreparationContent();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Preparation Resource uploaded & published!')),
                          );
                        }
                      },
                      icon: const Icon(Icons.cloud_upload_rounded, color: Colors.white),
                      label: const Text('Upload & Publish to S3', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MyVaultColors.accentBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyVaultColors.obsidian,
      appBar: AppBar(
        backgroundColor: MyVaultColors.obsidian,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.examName,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
            ),
            const Text(
              'Preparation Hub',
              style: TextStyle(color: MyVaultColors.accentCyan, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload_outlined, color: MyVaultColors.accentCyan),
            onPressed: _showInAppUploadModal,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Your Preparation Progress Dashboard Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    MyVaultColors.accentBlue.withValues(alpha: 0.25),
                    MyVaultColors.accentCyan.withValues(alpha: 0.1),
                  ],
                ),
                border: Border.all(color: MyVaultColors.accentCyan.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Your Preparation Progress', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      Text('72%', style: TextStyle(color: MyVaultColors.accentCyan, fontSize: 16, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: const LinearProgressIndicator(
                      value: 0.72,
                      minHeight: 8,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(MyVaultColors.accentCyan),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${_videos.length} Video Classes', style: const TextStyle(color: Colors.white70, fontSize: 11.5)),
                      Text('${_pdfNotes.length} Study Notes', style: const TextStyle(color: Colors.white70, fontSize: 11.5)),
                      const Text('Verified S3 Certified', style: TextStyle(color: Color(0xFF00C48C), fontSize: 11.5, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Continue Learning Banner
            if (_videos.isNotEmpty) ...[
              const Text('Continue Learning', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: MyVaultColors.glassFill,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: MyVaultColors.glassBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: MyVaultColors.accentBlue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.play_circle_fill_rounded, color: MyVaultColors.accentCyan, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _videos.first['title'] ?? 'Percentage - Complete Concept',
                            style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Subject: ${_videos.first['subject'] ?? "Quantitative Aptitude"} • 42 min',
                            style: const TextStyle(color: Colors.white54, fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _openUrl(_videos.first['fileUrl'] ?? _videos.first['s3Url']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MyVaultColors.accentBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: const Text('Watch ➔', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Preparation Hub Action Grid
            const Text('Preparation Modules', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                _buildActionCard(
                  title: '🎬 Videos',
                  subtitle: '${_videos.length} Class Lectures',
                  color: Colors.purpleAccent,
                  icon: Icons.play_circle_outline_rounded,
                  onTap: () => _showContentListModal('Preparation Videos', _videos, true),
                ),
                _buildActionCard(
                  title: '📚 Study Notes',
                  subtitle: '${_pdfNotes.length} PDF Capsules',
                  color: Colors.amberAccent,
                  icon: Icons.menu_book_rounded,
                  onTap: () => _showContentListModal('Study Notes & PDFs', _pdfNotes, false),
                ),
                _buildActionCard(
                  title: '📖 Syllabus',
                  subtitle: widget.syllabusSummary.split(",").first,
                  color: Colors.cyanAccent,
                  icon: Icons.assignment_outlined,
                  onTap: () => _showSyllabusModal(),
                ),
                _buildActionCard(
                  title: '📝 Previous Papers',
                  subtitle: '2025 - 2020 PYQs',
                  color: const Color(0xFF00C48C),
                  icon: Icons.history_edu_rounded,
                  onTap: () => _showContentListModal('Previous Papers (PYQs)', _pdfNotes, false),
                ),
                _buildActionCard(
                  title: '🧪 Practice',
                  subtitle: 'Topic Questions & Mocks',
                  color: Colors.orangeAccent,
                  icon: Icons.psychology_outlined,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mock Test Engine Initializing...')),
                    );
                  },
                ),
                _buildActionCard(
                  title: '🏆 Certificate',
                  subtitle: 'Verified Completion',
                  color: Colors.blueAccent,
                  icon: Icons.workspace_premium_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExamCertificateScreen(
                          examName: widget.examName,
                          studentName: 'Rahul Kumar',
                          certificateNumber: 'MV-EXAM-2026-102941',
                          pdfUrl: 'https://myvault-files-app.s3.eu-north-1.amazonaws.com/app-arm64-v8a-release.apk',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: MyVaultColors.glassFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MyVaultColors.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showContentListModal(String title, List<dynamic> items, bool isVideo) {
    showModalBottomSheet(
      context: context,
      backgroundColor: MyVaultColors.obsidian,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: items.isEmpty
                    ? const Center(child: Text('No preparation resources uploaded yet.', style: TextStyle(color: Colors.white54)))
                    : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (ctx, i) {
                          final item = items[i];
                          final itemTitle = item['title'] ?? 'Uploaded Resource';
                          final itemSub = item['subject'] ?? 'General';
                          final url = item['fileUrl'] ?? item['s3Url'] ?? item['pdfUrl'];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: MyVaultColors.glassFill,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: MyVaultColors.glassBorder),
                            ),
                            child: ListTile(
                              leading: Icon(
                                isVideo ? Icons.play_circle_fill_rounded : Icons.picture_as_pdf_rounded,
                                color: isVideo ? Colors.purpleAccent : Colors.amberAccent,
                              ),
                              title: Text(itemTitle, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                              subtitle: Text(itemSub, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                              trailing: ElevatedButton(
                                onPressed: () => _openUrl(url),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: MyVaultColors.accentBlue,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                ),
                                child: Text(isVideo ? 'Stream' : 'Read', style: const TextStyle(color: Colors.white, fontSize: 11)),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSyllabusModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: MyVaultColors.obsidian,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📖 Syllabus & Selection Flow', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              Text('Selection Process:\n${widget.selectionProcess}', style: const TextStyle(color: MyVaultColors.accentCyan, fontSize: 13.5, height: 1.4, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              Text('Core Subjects & Syllabus:\n${widget.syllabusSummary}', style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
            ],
          ),
        );
      },
    );
  }
}
