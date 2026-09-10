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
  int _navIndex = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _announcements = [];
  bool _loadingAnnouncements = true;
  final ScrollController _tickerController = ScrollController();
  Timer? _tickerTimer;

  // Student Profile Data
  final String _userName = 'Abhimanu S.';
  final String _branch = 'ECE';
  final int _semester = 1;
  final String _college = 'College of Engineering & Tech';
  final String _rollNo = '2026-ECE-1042';

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
    _searchController.dispose();
    super.dispose();
  }

  void _showProfileModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 30,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // Profile Header
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: MyVaultColors.metalGlossGradient,
                    boxShadow: [
                      BoxShadow(
                        color: MyVaultColors.metalBlack.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.person_rounded, color: Colors.white, size: 32),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName,
                        style: const TextStyle(
                          color: MyVaultColors.textDark,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_branch · Semester $_semester · Scholar',
                        style: const TextStyle(
                          color: MyVaultColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: Color(0xFFF1F5F9), height: 1),
            const SizedBox(height: 16),
            // Information Rows
            _profileInfoTile(Icons.badge_outlined, 'Roll Number', _rollNo),
            _profileInfoTile(Icons.account_balance_outlined, 'Institution', _college),
            _profileInfoTile(Icons.cloud_done_rounded, 'Cloud Storage', 'AWS S3 Permanent (0 Expiry)'),
            _profileInfoTile(Icons.security_rounded, 'Vault Security', 'End-to-End Encrypted'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/documents-vault');
                },
                icon: const Icon(Icons.folder_special_rounded, color: Colors.white, size: 18),
                label: const Text(
                  'Open Personal Document Vault',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyVaultColors.metalBlack,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Icon(icon, color: MyVaultColors.metalBlack, size: 18),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: MyVaultColors.textMuted, fontSize: 11, fontWeight: FontWeight.w500),
              ),
              Text(
                value,
                style: const TextStyle(color: MyVaultColors.textDark, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Master Hub Cards List
    final allHubs = [
      _HubCardData(
        title: 'Academic Study Hub',
        subtitle: 'Curriculum, Lecture Notes, PYQs & Lab Manuals',
        category: 'ACADEMIC',
        icon: Icons.menu_book_rounded,
        badgeText: 'Sem 1-8 All Branches',
        route: '/academic-hub',
        accentColor: const Color(0xFF0284C7),
      ),
      _HubCardData(
        title: 'Courses & Certification',
        subtitle: 'Learn In-Demand Skills, Online Exams & Certificates',
        category: 'COURSES',
        icon: Icons.school_rounded,
        badgeText: 'Verified Certs',
        route: '/courses',
        accentColor: const Color(0xFF4F46E5),
      ),
      _HubCardData(
        title: 'Internship & Job Hub',
        subtitle: 'Live Tech Internships & Placement Openings',
        category: 'CAREER',
        icon: Icons.business_center_rounded,
        badgeText: 'Live Openings',
        route: '/internships',
        accentColor: const Color(0xFF059669),
      ),
      _HubCardData(
        title: 'Competitive Exams Hub',
        subtitle: 'GATE, UPSC, GRE & Campus Placement Prep',
        category: 'EXAMS',
        icon: Icons.psychology_rounded,
        badgeText: 'Solved Papers',
        route: '/competitive-exams',
        accentColor: const Color(0xFFD97706),
      ),
      _HubCardData(
        title: 'Documents Vault',
        subtitle: 'Store & Manage Verified Degrees, Marks & IDs',
        category: 'VAULT',
        icon: Icons.folder_special_rounded,
        badgeText: 'S3 Permanent',
        route: '/documents-vault',
        accentColor: const Color(0xFF0F766E),
      ),
      _HubCardData(
        title: 'AI Mock Interview',
        subtitle: 'Real-Time Technical & HR Voice/Text Practice',
        category: 'AI_TOOLS',
        icon: Icons.psychology_outlined,
        badgeText: 'AI Powered',
        route: '/ai-interview',
        accentColor: const Color(0xFF7C3AED),
      ),
      _HubCardData(
        title: 'Results & CGPA Analyzer',
        subtitle: 'SGPA Forecast, Credit Tracker & Analytics',
        category: 'ACADEMIC',
        icon: Icons.grade_outlined,
        badgeText: 'Performance',
        route: '/results',
        accentColor: const Color(0xFFEA580C),
      ),
      _HubCardData(
        title: 'Uploaded Files & Storage',
        subtitle: 'Browse All Cloud Uploaded Notes & Archives',
        category: 'STORAGE',
        icon: Icons.cloud_done_rounded,
        badgeText: 'Cloud Sync',
        route: '/uploaded-files',
        accentColor: const Color(0xFFE11D48),
      ),
    ];

    // Filter Hubs by search query
    final filteredHubs = _searchQuery.isEmpty
        ? allHubs
        : allHubs.where((h) =>
            h.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            h.subtitle.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            h.category.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: MyVaultColors.backgroundWhite,
      body: Container(
        decoration: const BoxDecoration(
          gradient: MyVaultColors.whiteShadingGradient,
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Top Bar with Shading & Metallic Logo
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                child: Row(
                  children: [
                    // Metallic Icon Container
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: MyVaultColors.metalGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: MyVaultColors.metalBlack.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.shield_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'MyVault',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w800,
                        color: MyVaultColors.metalBlack,
                        fontSize: 22,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),
                    // Top Action: Profile avatar with metallic ring
                    InkWell(
                      onTap: _showProfileModal,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: MyVaultColors.metalGradient,
                          boxShadow: [
                            BoxShadow(
                              color: MyVaultColors.metalBlack.withValues(alpha: 0.2),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person, color: MyVaultColors.metalBlack, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Live Scrolling Announcement Ticker
              if (!_loadingAnnouncements && _announcements.isNotEmpty)
                Container(
                  width: double.infinity,
                  height: 36,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    border: Border.symmetric(
                      horizontal: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: const BoxDecoration(
                          gradient: MyVaultColors.metalGradient,
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.campaign_rounded, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'NOTICE',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                            ),
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
                              padding: const EdgeInsets.only(right: 32, top: 8),
                              child: Text(
                                '📢 $title: $msg',
                                style: const TextStyle(
                                  color: MyVaultColors.textDark,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

              // Main Scrollable Body
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  children: [
                    // 1. Premium Metallic Profile Card
                    _buildProfileCard(),

                    const SizedBox(height: 16),

                    // 2. Liquid Glassy Search Bar
                    _buildSearchBar(),

                    const SizedBox(height: 18),

                    // 3. Section Title: "Hubs & Repositories"
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Hubs & Vault Repositories',
                          style: TextStyle(
                            color: MyVaultColors.textDark,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            '${filteredHubs.length} Active',
                            style: const TextStyle(
                              color: MyVaultColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // 4. Hubs / Folders Grid Cards
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredHubs.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.05,
                      ),
                      itemBuilder: (context, i) {
                        return _buildHubCard(filteredHubs[i]);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // Bottom Navigation Bar with Middle Document Vault
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ─── 1. Premium Profile Card ────────────────────────────────────────────────
  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: MyVaultColors.metalGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: MyVaultColors.metalBlack.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Liquid Metallic Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1E232A),
                  border: Border.all(color: const Color(0xFF4A5568), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.person_rounded, color: Colors.white, size: 26),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, $_userName 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_branch (Semester $_semester) · Scholar',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Profile Action Button
              IconButton(
                onPressed: _showProfileModal,
                icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
                tooltip: 'View Profile',
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stats Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatChip(Icons.folder_open_rounded, '8 Repos', 'Active'),
                _buildVerticalDivider(),
                _buildStatChip(Icons.cloud_done_rounded, 'S3 Vault', '0-Expiry'),
                _buildVerticalDivider(),
                _buildStatChip(Icons.verified_user_rounded, 'Encrypted', 'Permanent'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF38BDF8), size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            Text(subtitle, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9)),
          ],
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 24,
      color: Colors.white.withValues(alpha: 0.12),
    );
  }

  // ─── 2. Liquid Glassy Search Bar ────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        style: const TextStyle(color: MyVaultColors.textDark, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search notes, courses, exams, vault...',
          hintStyle: const TextStyle(color: MyVaultColors.textMuted, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: MyVaultColors.metalBlack, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, color: MyVaultColors.textMuted, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // ─── 3. Hub / Folder Cards with Liquid Metal Black Styling ─────────────────
  Widget _buildHubCard(_HubCardData hub) {
    return InkWell(
      onTap: () => context.go(hub.route),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Metallic Black Liquid Icon Container
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: MyVaultColors.metalGlossGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: MyVaultColors.metalBlack.withValues(alpha: 0.22),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(hub.icon, color: Colors.white, size: 20),
                ),
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    hub.badgeText,
                    style: const TextStyle(
                      color: MyVaultColors.textSecondary,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hub.title,
                  style: const TextStyle(
                    color: MyVaultColors.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  hub.subtitle,
                  style: const TextStyle(
                    color: MyVaultColors.textMuted,
                    fontSize: 10,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── 4. Liquid Glass Bottom Navigation Bar with Middle Document Vault ───────
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        border: const Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 1. Home
              _buildNavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isSelected: _navIndex == 0,
                onTap: () => setState(() => _navIndex = 0),
              ),
              // 2. Search
              _buildNavItem(
                icon: Icons.search_rounded,
                label: 'Search',
                isSelected: _navIndex == 1,
                onTap: () {
                  setState(() => _navIndex = 1);
                  FocusScope.of(context).requestFocus();
                },
              ),
              // 3. Middle Item: Document Vault (➕ / 🗄️)
              _buildMiddleVaultButton(),
              // 4. Hubs / Courses
              _buildNavItem(
                icon: Icons.school_rounded,
                label: 'Courses',
                isSelected: _navIndex == 3,
                onTap: () => context.go('/courses'),
              ),
              // 5. Profile
              _buildNavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                isSelected: _navIndex == 4,
                onTap: _showProfileModal,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? MyVaultColors.metalBlack : const Color(0xFF94A3B8),
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? MyVaultColors.metalBlack : const Color(0xFF94A3B8),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Center Elevated Metallic Document Vault Action Button ─────────────────
  Widget _buildMiddleVaultButton() {
    return GestureDetector(
      onTap: () => context.go('/documents-vault'),
      child: Transform.translate(
        offset: const Offset(0, -10),
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: MyVaultColors.metalGlossGradient,
            boxShadow: [
              BoxShadow(
                color: MyVaultColors.metalBlack.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: Colors.white,
              width: 2.5,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.folder_special_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}

class _HubCardData {
  final String title;
  final String subtitle;
  final String category;
  final IconData icon;
  final String badgeText;
  final String route;
  final Color accentColor;

  _HubCardData({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.icon,
    required this.badgeText,
    required this.route,
    required this.accentColor,
  });
}
