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
      setState(() {
        _jobs = res.data as List<dynamic>;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load ${widget.title.toLowerCase()}. Please try again.';
        _loading = false;
      });
    }
  }

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
    final deadline = job['deadline'] != null
        ? DateTime.tryParse(job['deadline'])
        : null;
    final isExpired = deadline != null && deadline.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: MyVaultColors.glassFill,
        border: Border.all(
          color: isExpired
              ? Colors.red.withValues(alpha: 0.2)
              : _accentColor.withValues(alpha: 0.25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
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
                        job['title'] ?? 'Untitled',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
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
                            fontWeight: FontWeight.w500,
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
                      color: Colors.red.withValues(alpha: 0.15),
                    ),
                    child: const Text(
                      'Expired',
                      style: TextStyle(color: Colors.redAccent, fontSize: 11),
                    ),
                  ),
              ],
            ),

            if (job['description'] != null) ...[
              const SizedBox(height: 12),
              Text(
                job['description'],
                style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.5),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (job['location'] != null)
                  _chip(Icons.location_on_outlined, job['location']),
                if (job['salary'] != null)
                  _chip(Icons.currency_rupee_rounded, job['salary']),
                if (job['branch'] != null && job['branch'] != 'ALL')
                  _chip(Icons.school_outlined, job['branch']),
                if (deadline != null)
                  _chip(
                    Icons.calendar_today_outlined,
                    'Due: ${deadline.day}/${deadline.month}/${deadline.year}',
                    color: isExpired ? Colors.redAccent : Colors.white54,
                  ),
              ],
            ),

            if (job['applyUrl'] != null || job['fileUrl'] != null) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  if (job['applyUrl'] != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openUrl(job['applyUrl']),
                        icon: const Icon(Icons.open_in_new_rounded, size: 15),
                        label: const Text('Apply Now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  if (job['applyUrl'] != null && job['fileUrl'] != null)
                    const SizedBox(width: 8),
                  if (job['fileUrl'] != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openUrl(job['fileUrl']),
                        icon: const Icon(Icons.download_rounded, size: 15),
                        label: const Text('Download PDF'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _accentColor,
                          side: BorderSide(color: _accentColor.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String text, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color ?? Colors.white38, size: 13),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(color: color ?? Colors.white54, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.white24, size: 60),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadJobs,
              style: ElevatedButton.styleFrom(backgroundColor: MyVaultColors.accentBlue),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(widget.icon, color: Colors.white12, size: 70),
          const SizedBox(height: 16),
          Text(
            'No ${widget.title} posted yet',
            style: const TextStyle(color: Colors.white38, fontSize: 15),
          ),
          const SizedBox(height: 6),
          const Text(
            'Check back later or ask your admin',
            style: TextStyle(color: Colors.white24, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
