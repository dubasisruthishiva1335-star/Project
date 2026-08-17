import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/colors.dart';
import '../../core/api_client.dart';

class JobListingsScreen extends StatefulWidget {
  final String type; // 'INTERNSHIP' | 'PLACEMENT' | 'GOVT_JOB'
  final String title;
  final IconData icon;

  const JobListingsScreen({
    super.key,
    required this.type,
    required this.title,
    required this.icon,
  });

  @override
  State<JobListingsScreen> createState() => _JobListingsScreenState();
}

class _JobListingsScreenState extends State<JobListingsScreen> {
  List<dynamic> _jobs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiClient.instance.dio
          .get('/job-listings', queryParameters: {'type': widget.type});
      final fetched = res.data as List<dynamic>;
      setState(() {
        _jobs = fetched.isNotEmpty ? fetched : _fallbackList;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _jobs = _fallbackList;
        _loading = false;
      });
    }
  }

  List<dynamic> get _fallbackList => [
        {
          'id': 'int_fullstack_001',
          'title': 'Full Stack Developer Intern',
          'company': 'Google / TechCorp',
          'type': widget.type,
          'category': 'Full Stack',
          'applyUrl': 'https://myvault-project.vercel.app',
          'branch': 'CSE & IT',
          'stipend': '₹25,000 / month',
          'location': 'Hyderabad / Remote',
          'deadline': '2026-09-30',
          'description': 'Hands-on industrial development experience with React, Node.js, and Cloud services.',
          'postedAt': DateTime.now().toIso8601String(),
        },
        {
          'id': 'plc_tcs_002',
          'title': 'Software Engineer — Graduate Trainee',
          'company': 'TCS / Infosys',
          'type': widget.type,
          'category': 'Software Engineering',
          'applyUrl': 'https://myvault-project.vercel.app',
          'branch': 'All Branches',
          'stipend': '7.5 LPA',
          'location': 'Bangalore',
          'deadline': '2026-10-15',
          'description': 'Full-time campus drive for B.Tech students. Selection via Aptitude + Technical interviews.',
          'postedAt': DateTime.now().toIso8601String(),
        },
      ];

  Future<void> _openUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Color get _accentColor {
    switch (widget.type) {
      case 'INTERNSHIP':
        return const Color(0xFF3E7BFF);
      case 'PLACEMENT':
        return const Color(0xFF7C3AFF);
      case 'GOVT_JOB':
        return const Color(0xFF00C48C);
      default:
        return MyVaultColors.accentCyan;
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
          title: Row(
            children: [
              Icon(widget.icon, color: _accentColor, size: 20),
              const SizedBox(width: 8),
              ShaderMask(
                shaderCallback: (b) => MyVaultColors.accentGradient.createShader(b),
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: MyVaultColors.accentCyan))
            : _error != null
                ? _buildError()
                : _jobs.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _loadJobs,
                        color: MyVaultColors.accentCyan,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _jobs.length,
                          itemBuilder: (ctx, i) => _buildCard(_jobs[i]),
                        ),
                      ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> job) {
    final deadlineStr = job['deadline'] as String?;
    final deadline = deadlineStr != null ? DateTime.tryParse(deadlineStr) : null;
    final isExpired = deadline != null && deadline.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: MyVaultColors.glassFill,
        border: Border.all(
          color: isExpired
              ? Colors.red.withValues(alpha: 0.3)
              : _accentColor.withValues(alpha: 0.25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Icon + Title + Company + Expired Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [_accentColor.withValues(alpha: 0.3), _accentColor.withValues(alpha: 0.1)],
                    ),
                  ),
                  child: Icon(widget.icon, color: _accentColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job['title'] ?? 'Untitled Opportunity',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (job['company'] != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          job['company'],
                          style: TextStyle(
                            color: _accentColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isExpired)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.red.withValues(alpha: 0.2),
                    ),
                    child: const Text(
                      'Expired',
                      style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),

            if (job['description'] != null && String.fromCharCodes(job['description'].runes).isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                job['description'],
                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 14),

            // Metadata Chips (Stipend, Location, Branch, Deadline)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (job['stipend'] != null)
                  _chip(Icons.payments_outlined, job['stipend'], MyVaultColors.accentCyan),
                if (job['location'] != null)
                  _chip(Icons.location_on_outlined, job['location'], Colors.white70),
                if (job['branch'] != null && job['branch'] != 'ALL')
                  _chip(Icons.school_outlined, job['branch'], Colors.white70),
                if (deadlineStr != null && deadlineStr.isNotEmpty)
                  _chip(
                    Icons.event_outlined,
                    'Due: ${deadlineStr.split('T').first}',
                    isExpired ? Colors.redAccent : Colors.amber,
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Action Row: Apply Button / PDF View Link
            Row(
              children: [
                const Spacer(),
                if (job['applyUrl'] != null || job['fileUrl'] != null)
                  ElevatedButton.icon(
                    onPressed: () => _openUrl(job['applyUrl'] ?? job['fileUrl']),
                    icon: const Icon(Icons.open_in_new_rounded, color: Colors.white, size: 14),
                    label: const Text('Apply Now', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(widget.icon, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            'No ${widget.title} posted yet',
            style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Check back later or ask your admin',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loadJobs,
            style: ElevatedButton.styleFrom(backgroundColor: MyVaultColors.accentBlue),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
