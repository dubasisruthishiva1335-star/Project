import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/colors.dart';
import '../../core/api_client.dart';
import '../../services/bookmark_service.dart';
import '../academic_hub/pdf_viewer_screen.dart';

class SearchResultItem {
  final String id;
  final String title;
  final String subtitle;
  final String hubType;
  final String? fileUrl;
  final String? targetRoute;
  final String badgeText;
  final Color badgeColor;

  SearchResultItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.hubType,
    this.fileUrl,
    this.targetRoute,
    required this.badgeText,
    required this.badgeColor,
  });
}

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<SearchResultItem> _allItems = [];
  List<SearchResultItem> _filtered = [];
  bool _loading = true;
  String _activeTab = 'ALL';
  final Set<String> _bookmarkedIds = {};

  @override
  void initState() {
    super.initState();
    _loadAllContent();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final bookmarks = await BookmarkService.instance.getBookmarks();
    if (mounted) {
      setState(() {
        _bookmarkedIds.clear();
        _bookmarkedIds.addAll(bookmarks.map((b) => b.id));
      });
    }
  }

  Future<void> _loadAllContent() async {
    setState(() => _loading = true);
    final results = <SearchResultItem>[];

    try {
      final responses = await Future.wait([
        ApiClient.instance.dio.get('/api/notes').catchError((_) => Response(requestOptions: RequestOptions(), data: [])),
        ApiClient.instance.dio.get('/api/admin/courses').catchError((_) => Response(requestOptions: RequestOptions(), data: [])),
        ApiClient.instance.dio.get('/api/admin/competitive-exams').catchError((_) => Response(requestOptions: RequestOptions(), data: [])),
        ApiClient.instance.dio.get('/api/admin/internships').catchError((_) => Response(requestOptions: RequestOptions(), data: [])),
      ]);

      // 1. Notes
      final notesData = responses[0].data;
      if (notesData is List) {
        for (final n in notesData) {
          if (n is Map) {
            results.add(SearchResultItem(
              id: (n['id'] ?? n['_id'] ?? '').toString(),
              title: (n['title'] ?? 'Academic Note').toString(),
              subtitle: '${n['branch'] ?? 'ENGG'} Sem ${n['semester'] ?? 1} • Unit ${n['unit'] ?? 1}',
              hubType: 'NOTE',
              fileUrl: n['fileUrl'] ?? n['url'],
              targetRoute: '/academic-hub',
              badgeText: '📚 Academic',
              badgeColor: const Color(0xFF2563EB),
            ));
          }
        }
      }

      // 2. Courses
      final coursesData = responses[1].data;
      if (coursesData is List) {
        for (final c in coursesData) {
          if (c is Map) {
            results.add(SearchResultItem(
              id: (c['id'] ?? '').toString(),
              title: (c['title'] ?? 'Course').toString(),
              subtitle: '${c['category'] ?? 'Tech'} • ${c['duration'] ?? '30 Hours'}',
              hubType: 'COURSE',
              targetRoute: '/courses',
              badgeText: '🎓 Course',
              badgeColor: const Color(0xFF059669),
            ));
          }
        }
      }

      // 3. Exams
      final examsData = responses[2].data;
      if (examsData is List) {
        for (final e in examsData) {
          if (e is Map) {
            results.add(SearchResultItem(
              id: (e['id'] ?? '').toString(),
              title: (e['title'] ?? 'Exam Material').toString(),
              subtitle: '${e['examName'] ?? 'Competitive Exam'} • ${e['subject'] ?? 'General'}',
              hubType: 'EXAM',
              fileUrl: e['fileUrl'],
              targetRoute: '/competitive-exams',
              badgeText: '🎯 Exam PYQ',
              badgeColor: const Color(0xFF7C3AED),
            ));
          }
        }
      }

      // 4. Internships
      final internData = responses[3].data;
      if (internData is List) {
        for (final i in internData) {
          if (i is Map) {
            results.add(SearchResultItem(
              id: (i['id'] ?? '').toString(),
              title: (i['title'] ?? 'Internship').toString(),
              subtitle: '${i['company'] ?? 'Partner'} • ${i['stipend'] ?? 'Paid'}',
              hubType: 'INTERNSHIP',
              targetRoute: '/internships',
              badgeText: '💼 Internship',
              badgeColor: const Color(0xFFD97706),
            ));
          }
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _allItems = results;
        _filtered = results;
        _loading = false;
      });
    }
  }

  void _filter(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      _filtered = _allItems.where((item) {
        final matchesTab = _activeTab == 'ALL' || item.hubType == _activeTab;
        final matchesQuery = q.isEmpty ||
            item.title.toLowerCase().contains(q) ||
            item.subtitle.toLowerCase().contains(q);
        return matchesTab && matchesQuery;
      }).toList();
    });
  }

  Future<void> _toggleBookmark(SearchResultItem item) async {
    final isNowBookmarked = await BookmarkService.instance.toggleBookmark(
      BookmarkItem(
        id: item.id,
        title: item.title,
        subtitle: item.subtitle,
        hubType: item.hubType,
        fileUrl: item.fileUrl,
        targetRoute: item.targetRoute,
        bookmarkedAt: DateTime.now(),
        badgeText: item.badgeText,
      ),
    );

    setState(() {
      if (isNowBookmarked) {
        _bookmarkedIds.add(item.id);
      } else {
        _bookmarkedIds.remove(item.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyVaultColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: MyVaultColors.metalBlack, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _filter,
          decoration: const InputDecoration(
            hintText: 'Search Notes, Courses, Exams, Jobs...',
            hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            border: InputBorder.none,
          ),
          style: const TextStyle(fontSize: 15, color: MyVaultColors.metalBlack, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_rounded, color: MyVaultColors.textSecondary, size: 20),
              onPressed: () {
                _controller.clear();
                _filter('');
              },
            ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: Column(
        children: [
          // Filter Tabs
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _tabChip('ALL', 'All Results'),
                _tabChip('NOTE', '📚 Notes'),
                _tabChip('COURSE', '🎓 Courses'),
                _tabChip('EXAM', '🎯 Exams'),
                _tabChip('INTERNSHIP', '💼 Internships'),
              ],
            ),
          ),

          // Results Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filtered.length} Items Found',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: MyVaultColors.textSecondary),
                ),
                TextButton.icon(
                  onPressed: _loadAllContent,
                  icon: const Icon(Icons.refresh_rounded, size: 14, color: MyVaultColors.metalBlack),
                  label: const Text('Refresh', style: TextStyle(fontSize: 11, color: MyVaultColors.metalBlack)),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: MyVaultColors.metalBlack))
                : _filtered.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded, size: 56, color: Color(0xFFCBD5E1)),
                            SizedBox(height: 12),
                            Text(
                              'No matching items found',
                              style: TextStyle(fontWeight: FontWeight.bold, color: MyVaultColors.metalBlack, fontSize: 15),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Try searching for a different branch, course, or subject keyword.',
                              style: TextStyle(color: MyVaultColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filtered.length,
                        itemBuilder: (context, idx) {
                          final it = _filtered[idx];
                          final isBookmarked = _bookmarkedIds.contains(it.id);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              title: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: it.badgeColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      it.badgeText,
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: it.badgeColor),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      it.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: MyVaultColors.metalBlack),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(it.subtitle, style: const TextStyle(fontSize: 11, color: MyVaultColors.textSecondary)),
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                                  color: isBookmarked ? const Color(0xFFF59E0B) : const Color(0xFF94A3B8),
                                  size: 22,
                                ),
                                onPressed: () => _toggleBookmark(it),
                              ),
                              onTap: () {
                                if (it.fileUrl != null && it.fileUrl!.isNotEmpty) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PdfViewerScreen(
                                        title: it.title,
                                        fileUrl: it.fileUrl,
                                      ),
                                    ),
                                  );
                                } else if (it.targetRoute != null) {
                                  context.push(it.targetRoute!);
                                }
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _tabChip(String key, String label) {
    final sel = _activeTab == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: sel,
        onSelected: (_) {
          setState(() => _activeTab = key);
          _filter(_controller.text);
        },
        selectedColor: const Color(0xFFE2E8F0),
        backgroundColor: Colors.white,
        side: BorderSide(color: sel ? MyVaultColors.metalBlack : const Color(0xFFCBD5E1)),
        labelStyle: TextStyle(
          color: sel ? MyVaultColors.metalBlack : MyVaultColors.textSecondary,
          fontSize: 11,
          fontWeight: sel ? FontWeight.bold : FontWeight.normal,
        ),
        checkmarkColor: MyVaultColors.metalBlack,
      ),
    );
  }
}
