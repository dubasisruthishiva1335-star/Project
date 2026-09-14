import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../core/colors.dart';
import '../../services/offline_vault_service.dart';
import '../../services/study_activity_service.dart';

class PdfViewerScreen extends StatefulWidget {
  final String title;
  final String? pdfUrl;
  final String? fileUrl;
  final String? url;
  final String? filePath;
  final String? localFilePath;

  const PdfViewerScreen({
    super.key,
    required this.title,
    this.pdfUrl,
    this.fileUrl,
    this.url,
    this.filePath,
    this.localFilePath,
  });

  String? get resolvedRemoteUrl => pdfUrl ?? fileUrl ?? url;
  String? get resolvedLocalPath => localFilePath ?? filePath;

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  bool _isSavedOffline = false;
  DateTime? _openedAt;

  @override
  void initState() {
    super.initState();
    _openedAt = DateTime.now();
    _checkOfflineStatus();
  }

  @override
  void dispose() {
    if (_openedAt != null) {
      final duration = DateTime.now().difference(_openedAt!);
      final mins = (duration.inSeconds / 60).ceil();
      if (mins > 0) {
        StudyActivityService.instance.recordStudySession(minutes: mins, isDocumentRead: true);
      }
    }
    super.dispose();
  }

  Future<void> _checkOfflineStatus() async {
    final local = widget.resolvedLocalPath;
    if (local != null && File(local).existsSync()) {
      setState(() => _isSavedOffline = true);
      return;
    }
    final remote = widget.resolvedRemoteUrl;
    if (remote != null) {
      final saved = await OfflineVaultService.instance.isDownloaded(remote);
      if (mounted) {
        setState(() => _isSavedOffline = saved);
      }
    }
  }

  Future<void> _downloadOffline() async {
    final remote = widget.resolvedRemoteUrl;
    if (remote == null || remote.isEmpty) return;
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    final res = await OfflineVaultService.instance.downloadFile(
      id: 'doc_${DateTime.now().millisecondsSinceEpoch}',
      title: widget.title,
      subtitle: 'Downloaded PDF',
      hubType: 'NOTE',
      remoteUrl: remote,
      onProgress: (p) {
        if (mounted) setState(() => _downloadProgress = p);
      },
    );

    if (mounted) {
      setState(() {
        _isDownloading = false;
        _isSavedOffline = res != null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res != null ? '✅ Document saved to Offline Vault!' : '❌ Download failed. Please try again.'),
          backgroundColor: res != null ? const Color(0xFF10B981) : Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final local = widget.resolvedLocalPath;
    final remote = widget.resolvedRemoteUrl;

    return Scaffold(
      backgroundColor: MyVaultColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: MyVaultColors.metalBlack, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(color: MyVaultColors.metalBlack, fontWeight: FontWeight.bold, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_isDownloading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    value: _downloadProgress > 0 ? _downloadProgress : null,
                    color: MyVaultColors.metalBlack,
                    strokeWidth: 2.5,
                  ),
                ),
              ),
            )
          else if (_isSavedOffline)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Icon(Icons.offline_pin_rounded, color: Colors.green, size: 24),
            )
          else if (remote != null && remote.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.download_for_offline_outlined, color: MyVaultColors.metalBlack),
              tooltip: 'Save to Offline Vault',
              onPressed: _downloadOffline,
            ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: local != null && File(local).existsSync()
          ? SfPdfViewer.file(File(local))
          : (remote != null && remote.isNotEmpty)
              ? SfPdfViewer.network(remote)
              : const Center(child: Text('Document source unavailable.')),
    );
  }
}
