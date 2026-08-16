import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/colors.dart';
import '../models/internship_lms_model.dart';
import '../services/internship_lms_service.dart';
import 'internship_lms_screen.dart';

class InternshipCatalogScreen extends StatefulWidget {
  const InternshipCatalogScreen({super.key});

  @override
  State<InternshipCatalogScreen> createState() => _InternshipCatalogScreenState();
}

class _InternshipCatalogScreenState extends State<InternshipCatalogScreen> {
  final _service = InternshipLmsService();
  List<InternshipLms> _internships = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    setState(() => _loading = true);
    final items = await _service.fetchPublishedInternships();
    setState(() {
      _internships = items;
      _loading = false;
    });
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
        title: ShaderMask(
          shaderCallback: (b) => MyVaultColors.accentGradient.createShader(b),
          child: const Text(
            'Industry Internships',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: MyVaultColors.accentCyan))
          : RefreshIndicator(
              onRefresh: _loadCatalog,
              color: MyVaultColors.accentCyan,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _internships.length,
                itemBuilder: (context, index) {
                  final intItem = _internships[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: MyVaultColors.glassFill,
                      border: Border.all(color: MyVaultColors.glassBorder),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => InternshipLmsScreen(internshipId: intItem.id),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: MyVaultColors.accentBlue.withValues(alpha: 0.2),
                                    border: Border.all(color: MyVaultColors.accentBlue.withValues(alpha: 0.4)),
                                  ),
                                  child: Text(
                                    intItem.duration,
                                    style: const TextStyle(color: MyVaultColors.accentCyan, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.white10,
                                  ),
                                  child: Text(
                                    intItem.level,
                                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                                  ),
                                ),
                                const Spacer(),
                                const Icon(Icons.verified_rounded, color: Color(0xFF00C48C), size: 18),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              intItem.title,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              intItem.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.4),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: intItem.skills
                                  .map((s) => Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.05),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.white10),
                                        ),
                                        child: Text(s, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                                      ))
                                  .toList(),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Enrolled • Active Learner', style: TextStyle(color: Colors.white54, fontSize: 11)),
                                      SizedBox(height: 4),
                                      LinearProgressIndicator(value: 0.65, backgroundColor: Colors.white10, color: MyVaultColors.accentCyan, minHeight: 4),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: MyVaultColors.accentBlue,
                                  ),
                                  child: const Row(
                                    children: [
                                      Text('Open LMS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                      SizedBox(width: 4),
                                      Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 12),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
