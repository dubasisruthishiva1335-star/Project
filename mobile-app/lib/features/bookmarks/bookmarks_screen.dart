import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/colors.dart';
import '../../services/bookmark_service.dart';
import '../academic_hub/pdf_viewer_screen.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  List<BookmarkItem> _bookmarks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    setState(() => _loading = true);
    final list = await BookmarkService.instance.getBookmarks();
    if (mounted) {
      setState(() {
        _bookmarks = list;
        _loading = false;
      });
    }
  }

  Future<void> _removeBookmark(String id) async {
    await BookmarkService.instance.removeBookmark(id);
    _loadBookmarks();
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
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: MyVaultColors.metalGradient,
              ),
              child: const Icon(Icons.bookmark_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'My Bookmarks & Saved',
              style: TextStyle(fontWeight: FontWeight.bold, color: MyVaultColors.metalBlack, fontSize: 17),
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: MyVaultColors.metalBlack))
          : _bookmarks.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bookmark_border_rounded, size: 64, color: Color(0xFFCBD5E1)),
                      SizedBox(height: 12),
                      Text(
                        'No Bookmarks Saved Yet',
                        style: TextStyle(fontWeight: FontWeight.bold, color: MyVaultColors.metalBlack, fontSize: 15),
                      ),
                      SizedBox(height: 4),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'Bookmark important notes, courses, and internship openings for instant 1-tap access.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: MyVaultColors.textSecondary, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _bookmarks.length,
                  itemBuilder: (context, idx) {
                    final it = _bookmarks[idx];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        title: Text(
                          it.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: MyVaultColors.metalBlack),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(it.subtitle, style: const TextStyle(fontSize: 11, color: MyVaultColors.textSecondary)),
                        trailing: IconButton(
                          icon: const Icon(Icons.bookmark_remove_rounded, color: Colors.redAccent, size: 20),
                          onPressed: () => _removeBookmark(it.id),
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
    );
  }
}
