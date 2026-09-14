import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../services/offline_vault_service.dart';
import '../academic_hub/pdf_viewer_screen.dart';

class OfflineVaultScreen extends StatefulWidget {
  const OfflineVaultScreen({super.key});

  @override
  State<OfflineVaultScreen> createState() => _OfflineVaultScreenState();
}

class _OfflineVaultScreenState extends State<OfflineVaultScreen> {
  List<OfflineItem> _files = [];
  bool _loading = true;
  String _searchQuery = '';
  int _totalStorageBytes = 0;

  @override
  void initState() {
    super.initState();
    _loadVault();
  }

  Future<void> _loadVault() async {
    setState(() => _loading = true);
    final list = await OfflineVaultService.instance.getOfflineFiles();
    final total = await OfflineVaultService.instance.getTotalStorageUsedBytes();
    if (mounted) {
      setState(() {
        _files = list;
        _totalStorageBytes = total;
        _loading = false;
      });
    }
  }

  Future<void> _deleteFile(OfflineItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Offline Download?'),
        content: Text('Delete "${item.title}" from local storage? You can re-download it when online.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await OfflineVaultService.instance.deleteOfflineFile(item.id);
      _loadVault();
    }
  }

  String _formatTotalStorage(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _files.where((f) {
      final q = _searchQuery.toLowerCase();
      return f.title.toLowerCase().contains(q) ||
          f.subtitle.toLowerCase().contains(q) ||
          (f.category != null && f.category!.toLowerCase().contains(q));
    }).toList();

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
              child: const Icon(Icons.download_done_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'Offline Downloads Vault',
              style: TextStyle(fontWeight: FontWeight.bold, color: MyVaultColors.metalBlack, fontSize: 17),
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: Column(
        children: [
          // Storage Summary Banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: MyVaultColors.metalGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.offline_bolt_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Instant Offline Access',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_files.length} Files Downloaded • ${_formatTotalStorage(_totalStorageBytes)} Used',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search downloaded files...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: MyVaultColors.metalBlack, size: 20),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: MyVaultColors.metalBlack))
                : filtered.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_download_outlined, size: 64, color: Color(0xFFCBD5E1)),
                            SizedBox(height: 12),
                            Text(
                              'No Offline Files Saved Yet',
                              style: TextStyle(fontWeight: FontWeight.bold, color: MyVaultColors.metalBlack, fontSize: 15),
                            ),
                            SizedBox(height: 4),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                'Tap the download icon while reading any unit notes or exam papers to store them offline.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: MyVaultColors.textSecondary, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filtered.length,
                        itemBuilder: (context, idx) {
                          final it = filtered[idx];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF2563EB), size: 24),
                              ),
                              title: Text(
                                it.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: MyVaultColors.metalBlack),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${it.subtitle.isNotEmpty ? "${it.subtitle} • " : ""}${it.formattedSize}',
                                style: const TextStyle(fontSize: 11, color: MyVaultColors.textSecondary),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                    onPressed: () => _deleteFile(it),
                                  ),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PdfViewerScreen(
                                      title: it.title,
                                      localFilePath: it.localPath,
                                      fileUrl: it.remoteUrl,
                                    ),
                                  ),
                                );
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
}
