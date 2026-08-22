import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/colors.dart';
import '../../core/api_client.dart';

class InternshipDetailScreen extends StatefulWidget {
  final String internshipId;

  const InternshipDetailScreen({
    super.key,
    required this.internshipId,
  });

  @override
  State<InternshipDetailScreen> createState() => _InternshipDetailScreenState();
}

class _InternshipDetailScreenState extends State<InternshipDetailScreen> {
  Map<String, dynamic>? _detail;
  bool _loading = true;
  bool _actionLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.instance.dio.get('/internships/${widget.internshipId}');
      setState(() {
        _detail = res.data as Map<String, dynamic>;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load opportunity detail.';
        _loading = false;
      });
    }
  }

  Future<void> _enroll() async {
    setState(() => _actionLoading = true);
    try {
      await ApiClient.instance.dio.post('/internships/${widget.internshipId}/enroll');
      await _fetchDetail();
    } catch (_) {}
    setState(() => _actionLoading = false);
  }

  Future<void> _completeLesson(String lessonId) async {
    setState(() => _actionLoading = true);
    try {
      await ApiClient.instance.dio.post(
        '/internships/lessons/$lessonId/complete',
        data: {'internshipId': widget.internshipId},
      );
      await _fetchDetail();
    } catch (_) {}
    setState(() => _actionLoading = false);
  }

  Future<void> _openUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
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
          onPressed: () => context.go('/home'),
        ),
        title: Text(
          _detail?['title'] ?? 'Opportunity Details',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: MyVaultColors.accentCyan))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
              : _detail == null
                  ? const SizedBox.shrink()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: _detail!['isLmsEnabled'] == true ? _buildLmsView() : _buildPlainView(),
                    ),
    );
  }

  Widget _buildPlainView() {
    final title = _detail!['title'] ?? '';
    final company = _detail!['company'] ?? '';
    final description = _detail!['description'] ?? '';
    final stipend = _detail!['stipend'];
    final location = _detail!['location'];
    final branch = _detail!['branch'];
    final deadline = _detail!['deadline'];
    final applyUrl = _detail!['applyUrl'];
    final fileUrl = _detail!['fileUrl'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: MyVaultColors.glassFill,
            border: Border.all(color: MyVaultColors.accentBlue.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(company, style: const TextStyle(color: MyVaultColors.accentCyan, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (stipend != null) _chip(Icons.payments_outlined, stipend, MyVaultColors.accentCyan),
                  if (location != null) _chip(Icons.location_on_outlined, location, Colors.white70),
                  if (branch != null) _chip(Icons.school_outlined, branch, Colors.white70),
                  if (deadline != null) _chip(Icons.event_outlined, 'Due: $deadline', Colors.amber),
                ],
              ),
            ],
          ),
        ),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text('Description & Requirements', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(description, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
        ],
        const SizedBox(height: 28),
        Row(
          children: [
            if (fileUrl != null)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openUrl(fileUrl),
                  icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent),
                  label: const Text('View PDF Circular', style: TextStyle(color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            if (fileUrl != null && applyUrl != null) const SizedBox(width: 12),
            if (applyUrl != null)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openUrl(applyUrl),
                  icon: const Icon(Icons.open_in_new_rounded, color: Colors.white),
                  label: const Text('Apply via Portal ↗', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MyVaultColors.accentBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildLmsView() {
    final isEnrolled = _detail!['isEnrolled'] == true;
    final progress = (_detail!['progressPercentage'] ?? 0) as int;
    final modules = (_detail!['modules'] ?? []) as List<dynamic>;
    final certUrl = _detail!['certificateUrl'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LMS Course Header Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                MyVaultColors.accentBlue.withOpacity(0.3),
                MyVaultColors.accentCyan.withOpacity(0.1),
              ],
            ),
            border: Border.all(color: MyVaultColors.accentCyan.withOpacity(0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: MyVaultColors.accentCyan.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: MyVaultColors.accentCyan.withOpacity(0.4)),
                    ),
                    child: const Text(
                      '🎓 INDUSTRIAL COURSE',
                      style: TextStyle(color: MyVaultColors.accentCyan, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Spacer(),
                  if (certUrl != null)
                    const Icon(Icons.verified_rounded, color: Colors.amber, size: 24),
                ],
              ),
              const SizedBox(height: 12),
              Text(_detail!['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(_detail!['company'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 16),

              // Progress Bar
              if (isEnrolled) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Course Progress', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text('$progress%', style: const TextStyle(color: MyVaultColors.accentCyan, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress / 100.0,
                    minHeight: 8,
                    backgroundColor: Colors.white12,
                    color: MyVaultColors.accentCyan,
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Certificate Banner
        if (certUrl != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.amber.withOpacity(0.15),
              border: Border.all(color: Colors.amber.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 32),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Course Completed! 🏆', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('Your Verified Certificate is issued.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _openUrl(certUrl),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                  child: const Text('View PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),

        // Enroll Button
        if (!isEnrolled)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _actionLoading ? null : _enroll,
              icon: const Icon(Icons.school_rounded, color: Colors.white),
              label: Text(_actionLoading ? 'Enrolling...' : 'Enroll in Course', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: MyVaultColors.accentCyan,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

        const SizedBox(height: 20),
        const Text('Course Syllabus & Lessons', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        // Modules & Lessons List
        if (modules.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('No modules added yet.', style: TextStyle(color: Colors.white38))),
          )
        else
          ...modules.map((m) {
            final lessons = (m['lessons'] ?? []) as List<dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: MyVaultColors.glassFill,
                border: Border.all(color: Colors.white10),
              ),
              child: ExpansionTile(
                initiallyExpanded: true,
                title: Text(m['title'] ?? 'Module', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                children: lessons.map((l) {
                  final isDone = l['isCompleted'] == true;
                  return ListTile(
                    onTap: () => context.push(
                      '/internships/${widget.internshipId}/lessons/${l['id']}',
                      extra: l,
                    ),
                    leading: Icon(
                      isDone ? Icons.check_circle_rounded : Icons.play_circle_fill_rounded,
                      color: isDone ? const Color(0xFF00E676) : MyVaultColors.accentCyan,
                    ),
                    title: Text(l['title'] ?? '', style: TextStyle(color: isDone ? Colors.white54 : Colors.white, fontSize: 13)),
                    subtitle: Text('${l['contentType']} • ${l['duration']}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    trailing: isEnrolled && !isDone
                        ? IconButton(
                            icon: const Icon(Icons.done_all_rounded, color: MyVaultColors.accentCyan, size: 20),
                            onPressed: _actionLoading ? null : () => _completeLesson(l['id']),
                          )
                        : null,
                  );
                }).toList(),
              ),
            );
          }),
      ],
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
