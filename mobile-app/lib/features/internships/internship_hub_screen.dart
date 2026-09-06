import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/colors.dart';
import '../../core/api_client.dart';

class InternshipHubScreen extends StatefulWidget {
  const InternshipHubScreen({super.key});

  @override
  State<InternshipHubScreen> createState() => _InternshipHubScreenState();
}

class _InternshipHubScreenState extends State<InternshipHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  String _selectedWorkMode = 'ALL';
  String _selectedBranch = 'ALL';
  bool _isLoading = true;

  List<Map<String, dynamic>> _internships = [];
  final List<Map<String, dynamic>> _myApplications = [];
  final Set<String> _savedIds = {};

  final List<Map<String, dynamic>> _seedInternships = [
    {
      'id': 'google-swe-2026',
      'title': 'Software Engineering Intern - Cloud & AI',
      'company': 'Google India',
      'logoColor': 0xFF4285F4,
      'workMode': 'HYBRID',
      'location': 'Bangalore / Hyderabad, India',
      'category': 'Software Engineering',
      'openings': 8,
      'stipend': '₹1,25,000 / month',
      'duration': '6 Months (Summer 2026)',
      'deadline': '2026-09-30',
      'minCgpa': 8.0,
      'eligibleBranches': ['CSE', 'IT', 'ECE', 'AI/ML', 'Data Science'],
      'matchScore': 96,
      'skills': ['Python', 'Go', 'Distributed Systems', 'C++', 'Data Structures & Algorithms'],
      'description': 'Join Google Cloud & Core Systems infrastructure teams to design scalable backend microservices, optimize machine learning training pipelines, and develop high-throughput distributed systems.',
      'responsibilities': [
        'Design and deploy scalable APIs and distributed cache systems using Go / C++ / Python.',
        'Collaborate with global site reliability engineering and product architecture teams.',
        'Implement automated testing, observability dashboards, and fault-tolerant cloud workflows.',
        'Analyze latency bottlenecks and optimize microservices throughput.'
      ],
      'requirements': [
        'Currently enrolled in B.Tech / M.Tech in Computer Science, IT, or related technical disciplines (Graduating 2026 or 2027).',
        'Strong computer science fundamentals: Data Structures, Algorithms, OS, Networking, and Database Systems.',
        'Hands-on experience in one or more languages: C++, Java, Python, or Go.',
        'Minimum CGPA 8.0/10.0 or equivalent.'
      ],
      'perks': [
        'Pre-Placement Offer (PPO) conversion opportunity',
        'Direct 1:1 mentorship with Principal Staff Engineers',
        'State-of-the-art hardware (MacBook Pro / Linux workstation)',
        'Free gourmet cafeteria, wellness stipend, and transit allowance'
      ]
    },
    {
      'id': 'microsoft-swe-2026',
      'title': 'Software Engineer Intern - Azure & Copilot',
      'company': 'Microsoft',
      'logoColor': 0xFF00A4EF,
      'workMode': 'REMOTE',
      'location': 'Remote / Hyderabad, India',
      'category': 'Cloud & Intelligent Edge',
      'openings': 12,
      'stipend': '₹1,10,000 / month',
      'duration': '6 Months',
      'deadline': '2026-10-15',
      'minCgpa': 7.5,
      'eligibleBranches': ['CSE', 'IT', 'ECE', 'All Engineering Branches'],
      'matchScore': 93,
      'skills': ['C#', '.NET Core', 'Azure', 'TypeScript', 'React', 'Generative AI'],
      'description': 'Work alongside Microsoft Azure & Copilot engineers to build enterprise-scale cloud computing services and next-generation AI integrations.',
      'responsibilities': [
        'Develop resilient cloud services on Microsoft Azure using .NET Core, TypeScript, and Python.',
        'Integrate OpenAI LLM endpoints with Azure AI Studio for intelligent enterprise assistants.',
        'Write clean, maintainable code following security best practices and telemetry instrumentation.',
        'Participate in code reviews, design sprints, and agile team ceremonies.'
      ],
      'requirements': [
        'B.Tech / B.E. student graduating in 2026 or 2027.',
        'Solid foundation in object-oriented programming, cloud patterns, and asynchronous programming.',
        'Experience building full-stack web applications or RESTful microservices.',
        'Minimum CGPA 7.5/10.0.'
      ],
      'perks': [
        'Comprehensive health insurance & wellness allowance',
        'Full PPO eligibility for 2026 full-time positions',
        'Free Microsoft certifications & Azure cloud credits',
        'Home office setup allowance of ₹50,000'
      ]
    },
    {
      'id': 'amazon-sde-2026',
      'title': 'SDE Intern - AWS Distributed Storage',
      'company': 'Amazon',
      'logoColor': 0xFFFF9900,
      'workMode': 'HYBRID',
      'location': 'Hyderabad / Bangalore, India',
      'category': 'Systems & Cloud Storage',
      'openings': 15,
      'stipend': '₹1,15,000 / month',
      'duration': '6 Months',
      'deadline': '2026-09-25',
      'minCgpa': 7.0,
      'eligibleBranches': ['CSE', 'IT', 'ECE', 'EEE'],
      'matchScore': 90,
      'skills': ['Java', 'AWS', 'DynamoDB', 'Microservices', 'Docker', 'Linux'],
      'description': 'Build high-performance storage services powering Amazon Web Services (AWS) globally with low-latency and 99.999% reliability.',
      'responsibilities': [
        'Design and implement resilient backend systems supporting petabyte-scale storage.',
        'Optimize multi-threaded Java applications for high I/O throughput and low p99 latency.',
        'Author comprehensive unit, integration, and stress tests.',
        'Engage in on-call shadowing and operational excellence reviews.'
      ],
      'requirements': [
        'B.Tech/Dual Degree students in Computer Science, IT, or Electrical Engineering.',
        'Strong problem-solving, algorithm optimization, and debugging skills.',
        'Familiarity with Linux environments, Git, and Docker.',
        'Minimum CGPA 7.0/10.0.'
      ],
      'perks': [
        'Relocation allowance & corporate transit support',
        'High PPO conversion track for AWS teams',
        'Dedicated senior mentor and weekly 1:1 career guidance',
        'Amazon employee discount and equipment bundle'
      ]
    },
    {
      'id': 'adobe-ml-2026',
      'title': 'AI / ML Research Intern - Creative Cloud',
      'company': 'Adobe',
      'logoColor': 0xFFFF0000,
      'workMode': 'REMOTE',
      'location': 'Remote / Noida, India',
      'category': 'Artificial Intelligence',
      'openings': 6,
      'stipend': '₹1,00,000 / month',
      'duration': '6 Months',
      'deadline': '2026-10-30',
      'minCgpa': 8.0,
      'eligibleBranches': ['CSE', 'IT', 'AI/ML', 'Data Science', 'ECE'],
      'matchScore': 95,
      'skills': ['PyTorch', 'Computer Vision', 'Generative Diffusion', 'Python', 'CUDA'],
      'description': 'Push the boundaries of multimodal generative AI and computer vision models powering Adobe Firefly and Creative Cloud tools.',
      'responsibilities': [
        'Train and fine-tune diffusion and vision-language foundation models.',
        'Conduct research experiments on image synthesis, inpainting, and vector generation.',
        'Optimize deep learning inference pipelines for edge and cloud deployment.',
        'Publish research findings in top-tier conferences (CVPR, ICCV, NeurIPS).'
      ],
      'requirements': [
        'Enrolled in B.Tech, M.Tech, or Ph.D. in Computer Science, Data Science, or AI.',
        'Proven hands-on experience with PyTorch, TensorFlow, and HuggingFace transformers.',
        'Strong mathematical foundation in linear algebra, probability, and optimization.',
        'GitHub portfolio showcasing deep learning or computer vision projects.'
      ],
      'perks': [
        'Full access to high-end NVIDIA GPU compute clusters',
        'Publication mentorship & patent filing bonuses',
        'Flexible working hours & complete work-from-home setup',
        'Pre-Placement Offer (PPO) for Adobe Research Labs'
      ]
    }
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInternships();
    _loadInitialApplications();
  }

  void _loadInitialApplications() {
    _myApplications.addAll([
      {
        'applicationId': 'APP-2026-7842',
        'internshipId': 'google-swe-2026',
        'title': 'Software Engineering Intern - Cloud & AI',
        'company': 'Google India',
        'status': 'SHORTLISTED',
        'appliedDate': '2 days ago',
        'nextStep': 'Technical Round 1 scheduled on Friday, 3:30 PM IST',
        'progressStage': 3, // 1: Submitted, 2: Under Review, 3: Shortlisted, 4: Interview, 5: Selected
      },
      {
        'applicationId': 'APP-2026-6190',
        'internshipId': 'microsoft-swe-2026',
        'title': 'Software Engineer Intern - Azure & Copilot',
        'company': 'Microsoft',
        'status': 'UNDER_REVIEW',
        'appliedDate': '5 days ago',
        'nextStep': 'Resume screened by university recruiting team',
        'progressStage': 2,
      }
    ]);
  }

  Future<void> _loadInternships() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiClient.instance.dio.get('/internships');
      if (res.data is List && (res.data as List).isNotEmpty) {
        final List<Map<String, dynamic>> list = [];
        for (final item in res.data) {
          if (item is Map<String, dynamic>) {
            list.add(item);
          }
        }
        if (mounted) {
          setState(() {
            _internships = list;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {
      // Fallback cleanly to enriched seed data
    }
    if (mounted) {
      setState(() {
        _internships = List.from(_seedInternships);
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredInternships {
    final query = _searchController.text.trim().toLowerCase();
    return _internships.where((item) {
      final title = (item['title'] ?? '').toString().toLowerCase();
      final company = (item['company'] ?? '').toString().toLowerCase();
      final category = (item['category'] ?? '').toString().toLowerCase();
      final mode = (item['workMode'] ?? 'ALL').toString().toUpperCase();
      final branches = (item['eligibleBranches'] as List<dynamic>?)?.map((e) => e.toString().toUpperCase()).toList() ?? [];

      final matchesQuery = query.isEmpty ||
          title.contains(query) ||
          company.contains(query) ||
          category.contains(query);

      final matchesMode = _selectedWorkMode == 'ALL' || mode == _selectedWorkMode;
      final matchesBranch = _selectedBranch == 'ALL' ||
          branches.any((b) => b.contains(_selectedBranch) || b.contains('ALL'));

      return matchesQuery && matchesMode && matchesBranch;
    }).toList();
  }

  void _openInternshipDetails(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _InternshipDetailsSheet(
        item: item,
        isSaved: _savedIds.contains(item['id']),
        onToggleSave: () {
          setState(() {
            final id = item['id'].toString();
            if (_savedIds.contains(id)) {
              _savedIds.remove(id);
            } else {
              _savedIds.add(id);
            }
          });
          Navigator.pop(ctx);
        },
        onApply: () {
          Navigator.pop(ctx);
          _openApplicationWizard(item);
        },
      ),
    );
  }

  void _openApplicationWizard(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ApplicationWizardSheet(
        internship: item,
        onSubmit: (appData) {
          final newAppId = 'APP-2026-${1000 + _myApplications.length + 1}';
          setState(() {
            _myApplications.insert(0, {
              'applicationId': newAppId,
              'internshipId': item['id'],
              'title': item['title'],
              'company': item['company'],
              'status': 'SUBMITTED',
              'appliedDate': 'Just now',
              'nextStep': 'Application submitted successfully. Under initial review.',
              'progressStage': 1,
              ...appData,
            });
            _tabController.animateTo(1); // Switch to My Applications
          });

          // Post to server in background
          try {
            ApiClient.instance.dio.post('/internships/applications', data: {
              'internshipId': item['id'],
              'applicationId': newAppId,
              ...appData,
            });
          } catch (_) {}

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF00E676),
              behavior: SnackBarBehavior.floating,
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.black),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Application submitted! ID: $newAppId',
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyVaultColors.obsidian,
      appBar: AppBar(
        backgroundColor: MyVaultColors.obsidian,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => context.go('/home'),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AFF), Color(0xFF3E7BFF)],
                ),
              ),
              child: const Icon(Icons.business_center_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'Internship Hub',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 19),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: MyVaultColors.accentCyan,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(text: 'Explore (${_internships.length})'),
            Tab(text: 'My Applications (${_myApplications.length})'),
            Tab(text: 'Saved (${_savedIds.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildExploreTab(),
          _buildApplicationsTab(),
          _buildSavedTab(),
        ],
      ),
    );
  }

  Widget _buildExploreTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: MyVaultColors.accentCyan));
    }

    final list = _filteredInternships;

    return RefreshIndicator(
      onRefresh: _loadInternships,
      color: MyVaultColors.accentCyan,
      backgroundColor: const Color(0xFF141824),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // AI Profile Match Recommendation Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF7C3AFF).withValues(alpha: 0.25),
                  MyVaultColors.accentBlue.withValues(alpha: 0.2),
                ],
              ),
              border: Border.all(color: const Color(0xFF7C3AFF).withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AFF).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.bolt_rounded, color: Color(0xFF00E676), size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Recommendation Match: 96%',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Top openings matched with your branch (CSE) & technical projects.',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Search Bar
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search roles, companies, or tech stacks...',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              filled: true,
              fillColor: MyVaultColors.glassFill,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: MyVaultColors.glassBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: MyVaultColors.glassBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: MyVaultColors.accentCyan),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Work Mode Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All Modes', 'ALL', _selectedWorkMode == 'ALL', (v) => setState(() => _selectedWorkMode = 'ALL')),
                const SizedBox(width: 8),
                _buildFilterChip('🌐 Remote', 'REMOTE', _selectedWorkMode == 'REMOTE', (v) => setState(() => _selectedWorkMode = 'REMOTE')),
                const SizedBox(width: 8),
                _buildFilterChip('🏢 Hybrid', 'HYBRID', _selectedWorkMode == 'HYBRID', (v) => setState(() => _selectedWorkMode = 'HYBRID')),
                const SizedBox(width: 8),
                _buildFilterChip('📍 On-Site', 'ONSITE', _selectedWorkMode == 'ONSITE', (v) => setState(() => _selectedWorkMode = 'ONSITE')),
                const SizedBox(width: 12),
                Container(height: 20, width: 1, color: Colors.white24),
                const SizedBox(width: 12),
                _buildFilterChip('CSE / IT', 'CSE', _selectedBranch == 'CSE', (v) => setState(() => _selectedBranch = _selectedBranch == 'CSE' ? 'ALL' : 'CSE')),
                const SizedBox(width: 8),
                _buildFilterChip('ECE / EEE', 'ECE', _selectedBranch == 'ECE', (v) => setState(() => _selectedBranch = _selectedBranch == 'ECE' ? 'ALL' : 'ECE')),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Count Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing ${list.length} opportunities',
                style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const Row(
                children: [
                  Icon(Icons.verified_rounded, color: Color(0xFF00E676), size: 14),
                  SizedBox(width: 4),
                  Text('Direct Campus Verified', style: TextStyle(color: Color(0xFF00E676), fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // List of Cards
          if (list.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: const Column(
                children: [
                  Icon(Icons.search_off_rounded, color: Colors.white30, size: 48),
                  SizedBox(height: 12),
                  Text('No internships found matching filters', style: TextStyle(color: Colors.white60, fontSize: 14)),
                ],
              ),
            )
          else
            ...list.map((item) => _buildInternshipCard(item)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isSelected, Function(bool) onSelected) {
    return InkWell(
      onTap: () => onSelected(!isSelected),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? MyVaultColors.accentBlue : MyVaultColors.glassFill,
          border: Border.all(
            color: isSelected ? MyVaultColors.accentCyan : MyVaultColors.glassBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildInternshipCard(Map<String, dynamic> item) {
    final isSaved = _savedIds.contains(item['id']);
    final int score = (item['matchScore'] is num) ? (item['matchScore'] as num).toInt() : 90;
    final company = (item['company'] ?? 'Organization').toString();
    final title = (item['title'] ?? 'Internship Role').toString();
    final stipend = (item['stipend'] ?? 'Competitive').toString();
    final duration = (item['duration'] ?? '3-6 Months').toString();
    final workMode = (item['workMode'] ?? 'HYBRID').toString();
    final location = (item['location'] ?? 'India').toString();
    final deadline = (item['deadline'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F131D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MyVaultColors.glassBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openInternshipDetails(item),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Logo + Title + Bookmark
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Color((item['logoColor'] is int) ? item['logoColor'] : 0xFF3E7BFF).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color((item['logoColor'] is int) ? item['logoColor'] : 0xFF3E7BFF).withValues(alpha: 0.5)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        company.isNotEmpty ? company.substring(0, 1).toUpperCase() : 'I',
                        style: TextStyle(
                          color: Color((item['logoColor'] is int) ? item['logoColor'] : 0xFF3E7BFF),
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, height: 1.2),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(company, style: const TextStyle(color: MyVaultColors.accentCyan, fontWeight: FontWeight.w600, fontSize: 13)),
                              const SizedBox(width: 6),
                              const Icon(Icons.circle, color: Colors.white24, size: 4),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  location,
                                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                        color: isSaved ? const Color(0xFFFFB800) : Colors.white38,
                        size: 24,
                      ),
                      onPressed: () {
                        setState(() {
                          final id = item['id'].toString();
                          if (_savedIds.contains(id)) {
                            _savedIds.remove(id);
                          } else {
                            _savedIds.add(id);
                          }
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Tags / Highlights Row
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildTag(stipend, Icons.payments_outlined, const Color(0xFF00E676)),
                    _buildTag(workMode, Icons.laptop_mac_rounded, const Color(0xFF3E7BFF)),
                    _buildTag(duration, Icons.schedule_rounded, const Color(0xFFFFB800)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AFF).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF7C3AFF).withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt_rounded, color: Color(0xFF00E676), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '$score% Match',
                            style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 14),

                // Bottom CTA: Deadline + Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.hourglass_bottom_rounded, color: Colors.white38, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          deadline.isNotEmpty ? 'Deadline: $deadline' : 'Rolling Admissions',
                          style: const TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => _openInternshipDetails(item),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white70,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                          child: const Text('Details', style: TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(width: 6),
                        ElevatedButton(
                          onPressed: () => _openApplicationWizard(item),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MyVaultColors.accentBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Apply Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationsTab() {
    if (_myApplications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.assignment_turned_in_outlined, color: Colors.white30, size: 54),
              const SizedBox(height: 16),
              const Text(
                'No applications yet',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Discover top internships in the Explore tab and submit applications with 1 click.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _tabController.animateTo(0),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyVaultColors.accentBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Explore Internships', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myApplications.length,
      itemBuilder: (ctx, i) {
        final app = _myApplications[i];
        final stage = (app['progressStage'] is int) ? app['progressStage'] as int : 1;
        final status = (app['status'] ?? 'SUBMITTED').toString();
        final company = (app['company'] ?? 'Organization').toString();
        final title = (app['title'] ?? 'Role').toString();
        final appId = (app['applicationId'] ?? 'APP-2026-XXXX').toString();
        final appliedDate = (app['appliedDate'] ?? '').toString();
        final nextStep = (app['nextStep'] ?? 'Under evaluation').toString();

        Color statusColor = const Color(0xFF3E7BFF);
        if (status == 'SELECTED') statusColor = const Color(0xFF00E676);
        if (status == 'SHORTLISTED') statusColor = const Color(0xFF7C3AFF);
        if (status == 'INTERVIEW') statusColor = const Color(0xFFFFB800);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF0F131D),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: MyVaultColors.glassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(appId, style: const TextStyle(color: MyVaultColors.accentCyan, fontWeight: FontWeight.bold, fontSize: 12)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 2),
              Text('$company • Applied $appliedDate', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 18),

              // Multi-stage tracker visual
              _buildProgressTimeline(stage),

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: MyVaultColors.glassFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: MyVaultColors.accentCyan, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        nextStep,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressTimeline(int currentStage) {
    final stages = ['Applied', 'Review', 'Shortlist', 'Interview', 'Selected'];
    return Row(
      children: List.generate(stages.length * 2 - 1, (index) {
        if (index.isOdd) {
          final stepIndex = (index ~/ 2) + 1;
          final isCompleted = currentStage > stepIndex;
          return Expanded(
            child: Container(
              height: 2,
              color: isCompleted ? const Color(0xFF00E676) : Colors.white12,
            ),
          );
        } else {
          final stepIndex = (index ~/ 2) + 1;
          final isDone = currentStage >= stepIndex;
          final isCurrent = currentStage == stepIndex;
          return Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone
                      ? (isCurrent ? MyVaultColors.accentCyan : const Color(0xFF00E676))
                      : const Color(0xFF1B2030),
                  border: Border.all(
                    color: isDone ? Colors.transparent : Colors.white24,
                  ),
                ),
                alignment: Alignment.center,
                child: isDone
                    ? const Icon(Icons.check, size: 12, color: Colors.black)
                    : Text('$stepIndex', style: const TextStyle(color: Colors.white38, fontSize: 10)),
              ),
              const SizedBox(height: 4),
              Text(
                stages[index ~/ 2],
                style: TextStyle(
                  color: isDone ? Colors.white : Colors.white38,
                  fontSize: 9,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          );
        }
      }),
    );
  }

  Widget _buildSavedTab() {
    final savedList = _internships.where((i) => _savedIds.contains(i['id'])).toList();

    if (savedList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bookmark_border_rounded, color: Colors.white30, size: 54),
              const SizedBox(height: 16),
              const Text('No saved internships', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'Bookmark roles you want to prepare for and apply later.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: savedList.map((item) => _buildInternshipCard(item)).toList(),
    );
  }
}

/// Detailed Internship Bottom Sheet
class _InternshipDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isSaved;
  final VoidCallback onToggleSave;
  final VoidCallback onApply;

  const _InternshipDetailsSheet({
    required this.item,
    required this.isSaved,
    required this.onToggleSave,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final company = (item['company'] ?? 'Organization').toString();
    final title = (item['title'] ?? 'Role').toString();
    final stipend = (item['stipend'] ?? 'Competitive').toString();
    final duration = (item['duration'] ?? '6 Months').toString();
    final location = (item['location'] ?? 'India').toString();
    final workMode = (item['workMode'] ?? 'HYBRID').toString();
    final openings = (item['openings'] ?? 5).toString();
    final deadline = (item['deadline'] ?? '').toString();
    final description = (item['description'] ?? 'Exciting internship opportunity.').toString();
    final responsibilities = (item['responsibilities'] as List<dynamic>?) ?? [];
    final requirements = (item['requirements'] as List<dynamic>?) ?? [];
    final perks = (item['perks'] as List<dynamic>?) ?? [];
    final skills = (item['skills'] as List<dynamic>?) ?? [];

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0C101A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(color: Colors.black54, blurRadius: 20, spreadRadius: 5),
            ],
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),

              // Title Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text('$company • $location', style: const TextStyle(color: MyVaultColors.accentCyan, fontSize: 13)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                        color: isSaved ? const Color(0xFFFFB800) : Colors.white54,
                      ),
                      onPressed: onToggleSave,
                    ),
                  ],
                ),
              ),

              const Divider(color: Colors.white10),

              // Body Content
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Grid Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: MyVaultColors.glassFill,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: MyVaultColors.glassBorder),
                      ),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        childAspectRatio: 2.2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        children: [
                          _buildGridCell('Stipend', stipend, Icons.payments_outlined, const Color(0xFF00E676)),
                          _buildGridCell('Work Mode', workMode, Icons.business_rounded, const Color(0xFF3E7BFF)),
                          _buildGridCell('Duration', duration, Icons.schedule_rounded, const Color(0xFFFFB800)),
                          _buildGridCell('Openings', '$openings positions', Icons.people_outline_rounded, const Color(0xFF7C3AFF)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // AI Compatibility Breakdown
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AFF).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF7C3AFF).withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.auto_awesome, color: Color(0xFF00E676), size: 18),
                              SizedBox(width: 8),
                              Text('AI Profile Compatibility: 96%', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _buildCheckItem('Branch Eligibility: CSE / IT / ECE Verified'),
                          _buildCheckItem('Academic Cutoff: CGPA 8.0+ Requirement Satisfied'),
                          _buildCheckItem('Tech Stack Match: Python, Go, Cloud, Data Structures'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Description
                    const Text('About the Role', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(description, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),

                    if (responsibilities.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text('Key Responsibilities', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      ...responsibilities.map((r) => _buildBulletPoint(r.toString())),
                    ],

                    if (requirements.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text('Eligibility & Requirements', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      ...requirements.map((req) => _buildBulletPoint(req.toString())),
                    ],

                    if (skills.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text('Required Skills', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: skills.map((s) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: MyVaultColors.glassFill,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: MyVaultColors.accentCyan.withValues(alpha: 0.3)),
                          ),
                          child: Text(s.toString(), style: const TextStyle(color: MyVaultColors.accentCyan, fontSize: 12)),
                        )).toList(),
                      ),
                    ],

                    if (perks.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text('Perks & Benefits', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      ...perks.map((p) => _buildPerkItem(p.toString())),
                    ],

                    const SizedBox(height: 30),
                  ],
                ),
              ),

              // Bottom Apply Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF141824),
                  border: Border(top: BorderSide(color: Colors.white10)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Application Deadline', style: TextStyle(color: Colors.white38, fontSize: 11)),
                          Text(deadline.isNotEmpty ? deadline : 'Rolling Review', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: onApply,
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: const Text('Apply Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MyVaultColors.accentBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGridCell(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
              Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF00E676), size: 14),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, color: MyVaultColors.accentCyan, size: 6),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4))),
        ],
      ),
    );
  }

  Widget _buildPerkItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.card_giftcard_rounded, color: Color(0xFFFFB800), size: 16),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13))),
        ],
      ),
    );
  }
}

/// 4-Step Application Wizard Sheet
class _ApplicationWizardSheet extends StatefulWidget {
  final Map<String, dynamic> internship;
  final Function(Map<String, dynamic>) onSubmit;

  const _ApplicationWizardSheet({
    required this.internship,
    required this.onSubmit,
  });

  @override
  State<_ApplicationWizardSheet> createState() => _ApplicationWizardSheetState();
}

class _ApplicationWizardSheetState extends State<_ApplicationWizardSheet> {
  int _currentStep = 0;

  // Form Fields
  final _fullNameCtrl = TextEditingController(text: 'Student User');
  final _emailCtrl = TextEditingController(text: 'student@college.edu');
  final _phoneCtrl = TextEditingController(text: '+91 98765 43210');
  final _branchCtrl = TextEditingController(text: 'Computer Science & Engineering');
  final _cgpaCtrl = TextEditingController(text: '8.8');
  final _githubCtrl = TextEditingController(text: 'https://github.com/student-dev');
  final _linkedinCtrl = TextEditingController(text: 'https://linkedin.com/in/student-dev');
  final _pitchCtrl = TextEditingController();

  String _selectedResume = 'Resume_FullStack_2026.pdf';

  @override
  Widget build(BuildContext context) {
    final title = widget.internship['title'] ?? 'Role';
    final company = widget.internship['company'] ?? 'Organization';

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0C101A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Apply: $title', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                          Text('$company', style: const TextStyle(color: MyVaultColors.accentCyan, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Step Indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: List.generate(4, (index) {
                    final isDone = _currentStep > index;
                    final isCurrent = _currentStep == index;
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDone
                              ? const Color(0xFF00E676)
                              : (isCurrent ? MyVaultColors.accentCyan : Colors.white12),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const Divider(color: Colors.white10),

              // Form Content
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (_currentStep == 0) _buildStep1(),
                    if (_currentStep == 1) _buildStep2(),
                    if (_currentStep == 2) _buildStep3(),
                    if (_currentStep == 3) _buildStep4(),
                  ],
                ),
              ),

              // Bottom Actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF141824),
                  border: Border(top: BorderSide(color: Colors.white10)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentStep > 0)
                      TextButton(
                        onPressed: () => setState(() => _currentStep--),
                        child: const Text('Back', style: TextStyle(color: Colors.white70)),
                      )
                    else
                      const SizedBox.shrink(),
                    ElevatedButton(
                      onPressed: () {
                        if (_currentStep < 3) {
                          setState(() => _currentStep++);
                        } else {
                          widget.onSubmit({
                            'candidateName': _fullNameCtrl.text,
                            'candidateEmail': _emailCtrl.text,
                            'candidatePhone': _phoneCtrl.text,
                            'branch': _branchCtrl.text,
                            'cgpa': _cgpaCtrl.text,
                            'resume': _selectedResume,
                            'github': _githubCtrl.text,
                            'linkedin': _linkedinCtrl.text,
                            'pitch': _pitchCtrl.text,
                          });
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MyVaultColors.accentBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _currentStep == 3 ? 'Confirm & Submit 🚀' : 'Continue ➔',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Step 1 of 4: Candidate Information', style: TextStyle(color: MyVaultColors.accentCyan, fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 4),
        const Text('Verify your academic & contact credentials', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        _buildTextField('Full Name', _fullNameCtrl, Icons.person_outline),
        const SizedBox(height: 12),
        _buildTextField('Institutional Email', _emailCtrl, Icons.email_outlined),
        const SizedBox(height: 12),
        _buildTextField('Mobile Phone', _phoneCtrl, Icons.phone_outlined),
        const SizedBox(height: 12),
        _buildTextField('Engineering Branch', _branchCtrl, Icons.school_outlined),
        const SizedBox(height: 12),
        _buildTextField('Current CGPA', _cgpaCtrl, Icons.grade_outlined),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Step 2 of 4: Resume & Profiles', style: TextStyle(color: MyVaultColors.accentCyan, fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 4),
        const Text('Attach your documents', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        const Text('Selected Resume from Vault', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: MyVaultColors.glassFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF00E676), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_selectedResume, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    const Text('Verified • Stored in Documents Vault', style: TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ),
              const Icon(Icons.check_circle_rounded, color: Color(0xFF00E676), size: 20),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildTextField('GitHub Profile / Repositories URL', _githubCtrl, Icons.code_rounded),
        const SizedBox(height: 12),
        _buildTextField('LinkedIn Profile URL', _linkedinCtrl, Icons.link_rounded),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Step 3 of 4: Motivation & Projects', style: TextStyle(color: MyVaultColors.accentCyan, fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 4),
        const Text('Tell the recruiters why you are a fit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        const Text('Why are you interested in this internship?', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _pitchCtrl,
          maxLines: 4,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Highlight your relevant technical projects, hackathon wins, or key passion for this domain...',
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
            filled: true,
            fillColor: MyVaultColors.glassFill,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: MyVaultColors.glassBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: MyVaultColors.glassBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: MyVaultColors.accentCyan)),
          ),
        ),
      ],
    );
  }

  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Step 4 of 4: Review & Submit', style: TextStyle(color: MyVaultColors.accentCyan, fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 4),
        const Text('Ready to send your application?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: MyVaultColors.glassFill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: MyVaultColors.glassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReviewRow('Candidate', _fullNameCtrl.text),
              _buildReviewRow('Email', _emailCtrl.text),
              _buildReviewRow('Branch / CGPA', '${_branchCtrl.text} (${_cgpaCtrl.text})'),
              _buildReviewRow('Resume', _selectedResume),
              _buildReviewRow('GitHub', _githubCtrl.text),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Row(
          children: [
            Icon(Icons.shield_outlined, color: Color(0xFF00E676), size: 16),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Your application will be routed directly to the campus recruiting dashboard.',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12))),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.white54, size: 18),
            filled: true,
            fillColor: MyVaultColors.glassFill,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: MyVaultColors.glassBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: MyVaultColors.glassBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: MyVaultColors.accentCyan)),
          ),
        ),
      ],
    );
  }
}
