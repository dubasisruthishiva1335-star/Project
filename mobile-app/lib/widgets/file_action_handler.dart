import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import '../features/academic_hub/pdf_viewer_screen.dart';

class FileActionHandler {
  static Future<void> handleFileTap({
    required BuildContext context,
    required String fileUrl,
    required String fileName,
  }) async {
    if (fileUrl.isEmpty) return;

    if (fileUrl.toLowerCase().endsWith('.pdf') || fileName.toLowerCase().endsWith('.pdf')) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PdfViewerScreen(title: fileName, pdfUrl: fileUrl),
        ),
      );
      return;
    }

    final uri = Uri.tryParse(fileUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await OpenFilex.open(fileUrl);
    }
  }
}
