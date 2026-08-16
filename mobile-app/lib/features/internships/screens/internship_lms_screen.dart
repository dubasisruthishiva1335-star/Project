import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/colors.dart';
import '../models/internship_lms_model.dart';
import '../services/internship_lms_service.dart';
import 'lesson_player_screen.dart';
import 'quiz_screen.dart';
import 'submit_work_screen.dart';

class InternshipLmsScreen extends StatefulWidget {
  const InternshipLmsScreen({super.key, required this.internshipId});
  final String internshipId;

  @override
  State<InternshipLmsScreen> createState() => _InternshipLmsScreenState();
}

class _InternshipLmsScreenState extends State<InternshipLmsScreen> with SingleTickerProviderStateMixin {
  final _service = InternshipLmsService();
  late TabController _tabController;

  InternshipLms? _internship;
  Map<String, dynamic>? _certEligibility;
  CertificateDataLms? _issuedCert;
  bool _loading = true;
  bool _generatingCert = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadLmsData();
  }

  Future<void> _loadLmsData() async {
    setState(() => _loading = true);
    final data = await _service.fetchInternshipLmsTree(widget.internshipId);
    final elig = await _service.checkCertificateEligibility(widget.internshipId);
    setState(() {
      _internship = data;
      _certEligibility = elig;
      if (elig['isIssued'] == true && elig['certificate'] != null) {
        _issuedCert = CertificateDataLms.fromJson(elig['certificate']);
      }
      _loading = false;
    });
  }

  Future<void> _claimCertificate() async {
    setState(() => _generatingCert = true);
    final cert = await _service.generateCertificate(widget.internshipId);
    setState(() {
      _issuedCert = cert;
      _generatingCert = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _internship == null) {
      return Scaffold(
        backgroundColor: MyVaultColors.obsidian,
        body: const Center(child: CircularProgressIndicator(color: MyVaultColors.accentCyan)),
      );
    }

    final intData = _internship!;

    return Scaffold(
      backgroundColor: MyVaultColors.obsidian,
      appBar: AppBar(
        backgroundColor: MyVaultColors.obsidian,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(intData.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: MyVaultColors.accentCyan,
          labelColor: MyVaultColors.accentCyan,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Roadmap'),
            Tab(text: 'Learning LMS'),
            Tab(text: 'Assignments'),
            Tab(text: 'Certificate Vault'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(intData),
          _buildRoadmapTab(intData),
          _buildLearningTab(intData),
          _buildAssignmentsTab(intData),
          _buildCertificateVaultTab(intData),
        ],
      ),
    );
  }

  // ---------------- 1) OVERVIEW TAB ----------------
  Widget _buildOverviewTab(InternshipLms intData) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [MyVaultColors.accentBlue.withValues(alpha: 0.3), MyVaultColors.accentCyan.withValues(alpha: 0.1)],
            ),
            border: Border.all(color: MyVaultColors.accentCyan.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: MyVaultColors.accentBlue, borderRadius: BorderRadius.circular(6)),
                    child: Text(intData.duration, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                  const SizedBox(width: 8),
                  Text(intData.level, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 12),
              Text(intData.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 8),
              Text(intData.description, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('Skills You Will Gain', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: intData.skills
              .map((s) => Chip(
                    backgroundColor: MyVaultColors.glassFill,
                    side: const BorderSide(color: MyVaultColors.glassBorder),
                    label: Text(s, style: const TextStyle(color: MyVaultColors.accentCyan, fontSize: 12)),
                  ))
              .toList(),
        ),
      ],
    );
  }

  // ---------------- 2) ROADMAP TAB ----------------
  Widget _buildRoadmapTab(InternshipLms intData) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: intData.modules.length,
      itemBuilder: (context, index) {
        final mod = intData.modules[index];
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
              Text(mod.title, style: const TextStyle(color: MyVaultColors.accentCyan, fontWeight: FontWeight.bold, fontSize: 15)),
              if (mod.description != null) ...[
                const SizedBox(height: 4),
                Text(mod.description!, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
              const SizedBox(height: 12),
              ...mod.lessons.map((l) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          l.userProgress.completed ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          color: l.userProgress.completed ? const Color(0xFF00C48C) : Colors.white38,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(l.title, style: const TextStyle(color: Colors.white70, fontSize: 13))),
                        Text(l.type.toUpperCase(), style: const TextStyle(color: MyVaultColors.accentBlue, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }

  // ---------------- 3) LEARNING LMS TREE TAB ----------------
  Widget _buildLearningTab(InternshipLms intData) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: intData.modules.length,
      itemBuilder: (context, mIdx) {
        final mod = intData.modules[mIdx];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: MyVaultColors.glassFill,
            border: Border.all(color: MyVaultColors.glassBorder),
          ),
          child: ExpansionTile(
            initiallyExpanded: true,
            title: Text(mod.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: Text('${mod.lessons.length} lessons', style: const TextStyle(color: Colors.white54, fontSize: 12)),
            children: mod.lessons.map((les) {
              return ListTile(
                onTap: () {
                  if (les.type == 'quiz') {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => QuizScreen(lesson: les)),
                    );
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LessonPlayerScreen(lesson: les, internshipId: intData.id),
                      ),
                    );
                  }
                },
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: les.userProgress.completed
                        ? const Color(0xFF00C48C).withValues(alpha: 0.2)
                        : MyVaultColors.accentBlue.withValues(alpha: 0.2),
                  ),
                  child: Icon(
                    les.type == 'video'
                        ? Icons.play_arrow_rounded
                        : les.type == 'quiz'
                            ? Icons.quiz_rounded
                            : Icons.article_rounded,
                    color: les.userProgress.completed ? const Color(0xFF00C48C) : MyVaultColors.accentCyan,
                  ),
                ),
                title: Text(les.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text(
                  les.userProgress.completed ? '✓ Completed' : '${les.userProgress.percentage.toStringAsFixed(0)}% watched',
                  style: TextStyle(
                    color: les.userProgress.completed ? const Color(0xFF00C48C) : Colors.white54,
                    fontSize: 12,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 14),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // ---------------- 4) ASSIGNMENTS TAB ----------------
  Widget _buildAssignmentsTab(InternshipLms intData) {
    final assignmentLessons = intData.modules
        .expand((m) => m.lessons)
        .where((l) => l.type == 'assignment' || l.type == 'project')
        .toList();

    if (assignmentLessons.isEmpty) {
      return const Center(child: Text('No active assignments.', style: TextStyle(color: Colors.white54)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: assignmentLessons.length,
      itemBuilder: (context, idx) {
        final les = assignmentLessons[idx];
        final sub = les.userSubmission;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: MyVaultColors.glassFill,
            border: Border.all(color: MyVaultColors.glassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: MyVaultColors.accentBlue, borderRadius: BorderRadius.circular(6)),
                    child: Text(les.type.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const Spacer(),
                  if (sub != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: sub.status == 'approved' ? const Color(0xFF00C48C).withValues(alpha: 0.2) : Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        sub.status.toUpperCase(),
                        style: TextStyle(
                          color: sub.status == 'approved' ? const Color(0xFF00C48C) : Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(les.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              if (les.description != null) ...[
                const SizedBox(height: 4),
                Text(les.description!, style: const TextStyle(color: Colors.white60, fontSize: 13)),
              ],
              const SizedBox(height: 16),
              if (sub != null && sub.score != null) ...[
                Text('Score: ${sub.score}/100', style: const TextStyle(color: MyVaultColors.accentCyan, fontWeight: FontWeight.bold)),
                if (sub.feedback != null) Text('Feedback: "${sub.feedback}"', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 12),
              ],
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SubmitWorkScreen(lesson: les, internshipId: intData.id),
                    ),
                  );
                },
                icon: const Icon(Icons.upload_file_rounded, color: Colors.white, size: 18),
                label: Text(sub == null ? 'Submit Work' : 'Resubmit Work', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyVaultColors.accentBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------- 5) CERTIFICATE VAULT TAB ----------------
  Widget _buildCertificateVaultTab(InternshipLms intData) {
    if (_issuedCert != null) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [MyVaultColors.accentBlue.withValues(alpha: 0.4), MyVaultColors.accentCyan.withValues(alpha: 0.2)],
              ),
              border: Border.all(color: MyVaultColors.accentCyan),
            ),
            child: Column(
              children: [
                const Icon(Icons.verified_rounded, size: 64, color: MyVaultColors.accentCyan),
                const SizedBox(height: 12),
                const Text('MYVAULT VERIFIED CERTIFICATE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 6),
                Text('Certificate ID: ${_issuedCert!.certificateNumber}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => launchUrl(Uri.parse(_issuedCert!.pdfUrl)),
                  icon: const Icon(Icons.download_rounded, color: Colors.white),
                  label: const Text('Download Certificate PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: MyVaultColors.accentBlue, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Certificate Eligibility Requirements', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 14),
        ...((_certEligibility?['requirements'] as List? ?? []).map((r) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(r['met'] == true ? Icons.check_circle_rounded : Icons.cancel_outlined, color: r['met'] == true ? const Color(0xFF00C48C) : Colors.redAccent, size: 20),
                  const SizedBox(width: 10),
                  Text(r['name'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ))),
        const SizedBox(height: 28),
        _generatingCert
            ? const Center(child: CircularProgressIndicator(color: MyVaultColors.accentCyan))
            : ElevatedButton(
                onPressed: _claimCertificate,
                style: ElevatedButton.styleFrom(backgroundColor: MyVaultColors.accentBlue, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Claim & Generate Certificate PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
      ],
    );
  }
}
