import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/colors.dart';

class PdfViewerScreen extends StatefulWidget {
  final String title;
  final String pdfUrl;

  const PdfViewerScreen({
    super.key,
    required this.title,
    required this.pdfUrl,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final PdfViewerController _pdfController = PdfViewerController();
  bool _loading = true;
  String? _error;

  Future<void> _downloadExternal() async {
    final uri = Uri.tryParse(widget.pdfUrl);
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to open download link: $e')),
          );
        }
      }
    }
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: MyVaultColors.metalBlack),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: MyVaultColors.metalBlack),
            tooltip: 'Download PDF',
            onPressed: _downloadExternal,
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: Stack(
        children: [
          if (widget.pdfUrl.isNotEmpty)
            SfPdfViewer.network(
              widget.pdfUrl,
              controller: _pdfController,
              onDocumentLoaded: (details) {
                setState(() => _loading = false);
              },
              onDocumentLoadFailed: (details) {
                setState(() {
                  _loading = false;
                  _error = 'Failed to load PDF document: ${details.description}';
                });
              },
            ),
          if (_loading)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: MyVaultColors.metalBlack),
                    SizedBox(height: 16),
                    Text('Loading PDF Document...', style: TextStyle(color: MyVaultColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
            ),
          if (_error != null)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 14), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _downloadExternal,
                      icon: const Icon(Icons.open_in_browser_rounded),
                      label: const Text('Open Externally'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MyVaultColors.metalBlack,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
