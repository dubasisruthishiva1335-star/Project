import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../services/offline_vault_service.dart';
import '../../services/study_activity_service.dart';

enum AnnotationMode { none, highlight, inkPencil, stickyNote }

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
  final PdfViewerController _pdfViewerController = PdfViewerController();
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  bool _isSavedOffline = false;
  DateTime? _openedAt;

  AnnotationMode _activeMode = AnnotationMode.none;
  Color _selectedColor = const Color(0xFFFFD54F); // Highlighting Yellow
  final List<String> _notesList = [];

  @override
  void initState() {
    super.initState();
    _openedAt = DateTime.now();
    _checkOfflineStatus();
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
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

  void _addStickyNote() {
    showDialog(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('Add Sticky Note', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: ctrl,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Type your study note / bookmark...'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (ctrl.text.trim().isNotEmpty) {
                  setState(() => _notesList.add('Page ${_pdfViewerController.pageNumber}: ${ctrl.text.trim()}'));
                }
                Navigator.pop(ctx);
              },
              child: const Text('Save Note'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final local = widget.resolvedLocalPath;
    final remote = widget.resolvedRemoteUrl;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // Annotation Mode Switchers
          IconButton(
            icon: Icon(
              Icons.highlight_rounded,
              color: _activeMode == AnnotationMode.highlight ? Colors.amber : null,
            ),
            tooltip: 'Highlight Tool',
            onPressed: () {
              setState(() {
                _activeMode = _activeMode == AnnotationMode.highlight ? AnnotationMode.none : AnnotationMode.highlight;
              });
            },
          ),
          IconButton(
            icon: Icon(
              Icons.draw_rounded,
              color: _activeMode == AnnotationMode.inkPencil ? const Color(0xFF06B6D4) : null,
            ),
            tooltip: 'Ink Pencil Tool',
            onPressed: () {
              setState(() {
                _activeMode = _activeMode == AnnotationMode.inkPencil ? AnnotationMode.none : AnnotationMode.inkPencil;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.note_add_outlined),
            tooltip: 'Add Note',
            onPressed: _addStickyNote,
          ),
          if (_isDownloading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(value: _downloadProgress > 0 ? _downloadProgress : null, strokeWidth: 2),
                ),
              ),
            )
          else if (_isSavedOffline)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Icon(Icons.offline_pin_rounded, color: Color(0xFF10B981), size: 22),
            )
          else if (remote != null && remote.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.download_for_offline_outlined),
              tooltip: 'Save Offline',
              onPressed: _downloadOffline,
            ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_activeMode != AnnotationMode.none ? 44 : 1),
          child: _activeMode != AnnotationMode.none
              ? Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  color: const Color(0xFF06B6D4).withValues(alpha: 0.1),
                  child: Row(
                    children: [
                      Text(
                        _activeMode == AnnotationMode.highlight ? '🖍️ Highlighting Active' : '✏️ Freehand Drawing Active',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF06B6D4)),
                      ),
                      const Spacer(),
                      _colorDot(const Color(0xFFFFD54F)),
                      const SizedBox(width: 8),
                      _colorDot(const Color(0xFF80D8FF)),
                      const SizedBox(width: 8),
                      _colorDot(const Color(0xFFA7F3D0)),
                      const SizedBox(width: 8),
                      _colorDot(const Color(0xFFFCA5A5)),
                    ],
                  ),
                )
              : const Divider(height: 1),
        ),
      ),
      body: local != null && File(local).existsSync()
          ? SfPdfViewer.file(
              File(local),
              controller: _pdfViewerController,
              enableDoubleTapZooming: true,
            )
          : (remote != null && remote.isNotEmpty)
              ? SfPdfViewer.network(
                  remote,
                  controller: _pdfViewerController,
                  enableDoubleTapZooming: true,
                )
              : const Center(child: Text('Document source unavailable.')),
    );
  }

  Widget _colorDot(Color c) {
    final isSel = _selectedColor == c;
    return GestureDetector(
      onTap: () => setState(() => _selectedColor = c),
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: c,
          shape: BoxShape.circle,
          border: Border.all(color: isSel ? Colors.black : Colors.transparent, width: 2),
        ),
      ),
    );
  }
}
