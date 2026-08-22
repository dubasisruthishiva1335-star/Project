import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/colors.dart';
import '../../core/api_client.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _announcements = [];
  bool _loadingAnnouncements = true;
  final ScrollController _tickerController = ScrollController();
  Timer? _tickerTimer;

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements();
  }

  Future<void> _fetchAnnouncements() async {
    try {
      final res = await ApiClient.instance.dio.get('/announcements');
      if (mounted) {
        setState(() {
          _announcements = res.data as List<dynamic>;
          _loadingAnnouncements = false;
        });
        _startTickerAutoScroll();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingAnnouncements = false;
        });
      }
    }
  }

  void _startTickerAutoScroll() {
    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_tickerController.hasClients) {
        final maxExtent = _tickerController.position.maxScrollExtent;
        final currentOffset = _tickerController.offset;
        if (currentOffset >= maxExtent) {
          _tickerController.jumpTo(0);
        } else {
          _tickerController.jumpTo(currentOffset + 1.2);
        }
      }
    });
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    _tickerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _HomeTile('Academic Hub', 'Notes, Syllabus, Papers', Icons.menu_book_rounded, const Color(0xFF3E7BFF), () => context.go('/academic-hub')),
      _HomeTile('Documents Vault', 'Certificates & Resume', Icons.folder_special_rounded, const Color(0xFF00E676), () => context.go('/documents-vault')),
      _HomeTile('Internships', 'Stipends & Industrial', Icons.work_outline_rounded, const Color(0xFF00D9F5), () => context.go('/internships')),
      _HomeTile('Placements', 'Campus Hiring Drives', Icons.business_center_outlined, const Color(0xFF7C3AFF), () => context.go('/placements')),
      _HomeTile('Govt Jobs', 'TSPSC, ISRO, Railway', Icons.account_balance_outlined, const Color(0xFF00C48C), () => context.go('/govt-jobs')),
      _HomeTile('Competitive Exams', 'Preparation Hub & S3 Media', Icons.workspace_premium_rounded, const Color(0xFFE040FB), () => context.go('/competitive-exams')),
      _HomeTile('Results & AI', 'SGPA & AI Analyzer', Icons.grade_outlined, const Color(0xFFFFB800), () => context.go('/results')),
      _HomeTile('Aptitude', 'Quant, Logical & Verbal', Icons.psychology_outlined, const Color(0xFFFF4757), () => context.go('/aptitude')),
    ];

    return Scaffold(
      backgroundColor: MyVaultColors.obsidian,
      appBar: AppBar(
        backgroundColor: MyVaultColors.obsidian,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: MyVaultColors.accentGradient,
              ),
              child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            ShaderMask(
              shaderCallback: (b) => MyVaultColors.accentGradient.createShader(b),
              child: const Text('MyVault', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: Colors.white70, size: 26),
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Live Announcement Scrolling Ticker
            if (!_loadingAnnouncements && _announcements.isNotEmpty)
              Container(
                width: double.infinity,
                height: 40,
                color: MyVaultColors.accentBlue.withValues(alpha: 0.12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      color: MyVaultColors.accentBlue,
                      child: const Row(
                        children: [
                          Icon(Icons.campaign_rounded, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text('NOTICE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: _tickerController,
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _announcements.length * 10,
                        itemBuilder: (ctx, index) {
                          final item = _announcements[index % _announcements.length];
                          final title = item['title'] ?? 'Notice';
                          final msg = item['message'] ?? '';
                          return Padding(
                            padding: const EdgeInsets.only(right: 32, top: 10),
                            child: Text(
                              '📢 $title: $msg',
                              style: const TextStyle(color: MyVaultColors.accentCyan, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

            // Greeting Banner
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      MyVaultColors.accentBlue.withValues(alpha: 0.25),
                      MyVaultColors.accentCyan.withValues(alpha: 0.08),
                    ],
                  ),
                  border: Border.all(color: MyVaultColors.glassBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome to MyVault 🎓',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Your All-In-One Engineering Academic & Career Hub',
                      style: TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

            // Quick Action Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.25,
                ),
                itemCount: tiles.length,
                itemBuilder: (context, i) => tiles[i],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _HomeTile(this.label, this.subtitle, this.icon, this.accentColor, this.onTap);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: MyVaultColors.glassFill,
          border: Border.all(color: accentColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: accentColor.withValues(alpha: 0.15),
              ),
              child: Icon(icon, color: accentColor, size: 26),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
