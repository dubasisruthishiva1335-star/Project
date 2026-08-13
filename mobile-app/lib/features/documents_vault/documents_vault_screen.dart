import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/colors.dart';
import '../academic_hub/pdf_viewer_screen.dart';

class DocumentItem {
  final String id;
  final String title;
  final String category; // 'Certificates' | 'ID Cards' | 'Resumes' | 'Marksheets'
  final String fileUrl;
  final String addedDate;

  DocumentItem({
    required this.id,
    required this.title,
    required this.category,
    required this.fileUrl,
    required this.addedDate,
  });
}

class DocumentsVaultScreen extends StatefulWidget {
  const DocumentsVaultScreen({super.key});

  @override
  State<DocumentsVaultScreen> createState() => _DocumentsVaultScreenState();
}

class _DocumentsVaultScreenState extends State<DocumentsVaultScreen> {
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Certificates', 'ID Cards', 'Resumes', 'Marksheets'];

  final List<DocumentItem> _documents = [
    DocumentItem(
      id: 'doc-1',
      title: 'B.Tech Provisional Degree Certificate',
      category: 'Certificates',
      fileUrl: 'https://myvault-files-app.s3.eu-north-1.amazonaws.com/notes/1786544055523-478f14f9-ade1-411b-882d-5124b5b84967-RADAR_Ashok.pdf',
      addedDate: '2026-08-10',
    ),
    DocumentItem(
      id: 'doc-2',
      title: 'College Student ID Card',
      category: 'ID Cards',
      fileUrl: 'https://myvault-files-app.s3.eu-north-1.amazonaws.com/notes/1786502805860-3fb25413-0cae-4cce-84e5-9b2d2fc2ea69-Application_form_HCLTFP2247596.pdf',
      addedDate: '2026-08-12',
    ),
    DocumentItem(
      id: 'doc-3',
      title: 'Software Engineer Resume 2026',
      category: 'Resumes',
      fileUrl: 'https://myvault-files-app.s3.eu-north-1.amazonaws.com/notes/1786543997076-1cf0c517-9f51-4500-8721-f548799cd489-single_mode.pdf',
      addedDate: '2026-08-13',
    ),
  ];

  void _showAddDocumentDialog() {
    final titleController = TextEditingController();
    final urlController = TextEditingController();
    String category = 'Certificates';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141722),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Document to Vault', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Document Title',
                labelStyle: TextStyle(color: Colors.white60),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: MyVaultColors.glassBorder)),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: category,
              dropdownColor: const Color(0xFF141722),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Category', labelStyle: TextStyle(color: Colors.white60)),
              items: ['Certificates', 'ID Cards', 'Resumes', 'Marksheets']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => category = v ?? category,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Document URL / Link',
                labelStyle: TextStyle(color: Colors.white60),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: MyVaultColors.glassBorder)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: MyVaultColors.accentBlue),
            onPressed: () {
              if (titleController.text.trim().isEmpty) return;
              final newDoc = DocumentItem(
                id: 'doc-${DateTime.now().millisecondsSinceEpoch}',
                title: titleController.text.trim(),
                category: category,
                fileUrl: urlController.text.trim().isNotEmpty
                    ? urlController.text.trim()
                    : 'https://myvault-files-app.s3.eu-north-1.amazonaws.com/notes/1786544055523-478f14f9-ade1-411b-882d-5124b5b84967-RADAR_Ashok.pdf',
                addedDate: DateTime.now().toString().split(' ')[0],
              );
              setState(() => _documents.insert(0, newDoc));
              Navigator.of(ctx).pop();
            },
            child: const Text('Save to Vault'),
          ),
        ],
      ),
    );
  }

  void _viewDocument(DocumentItem doc) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(title: doc.title, pdfUrl: doc.fileUrl),
      ),
    );
  }

  Future<void> _downloadDocument(DocumentItem doc) async {
    final uri = Uri.tryParse(doc.fileUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _deleteDocument(String id) {
    setState(() => _documents.removeWhere((d) => d.id == id));
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case 'Certificates':
        return Icons.verified_user_rounded;
      case 'ID Cards':
        return Icons.badge_rounded;
      case 'Resumes':
        return Icons.description_rounded;
      case 'Marksheets':
        return Icons.grade_rounded;
      default:
        return Icons.folder_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedCategory == 'All'
        ? _documents
        : _documents.where((d) => d.category == _selectedCategory).toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) context.go('/home');
      },
      child: Scaffold(
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
              'My Documents Vault',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, color: MyVaultColors.accentCyan, size: 26),
              onPressed: _showAddDocumentDialog,
            ),
          ],
        ),
        body: Column(
          children: [
            // Category Filter Chips
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _categories.map((cat) {
                  final selected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(cat),
                      selected: selected,
                      onSelected: (_) => setState(() => _selectedCategory = cat),
                      selectedColor: MyVaultColors.accentBlue.withValues(alpha: 0.3),
                      backgroundColor: MyVaultColors.glassFill,
                      side: BorderSide(color: selected ? MyVaultColors.accentBlue : MyVaultColors.glassBorder),
                      labelStyle: TextStyle(
                        color: selected ? MyVaultColors.accentCyan : Colors.white60,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      ),
                      checkmarkColor: MyVaultColors.accentCyan,
                    ),
                  );
                }).toList(),
              ),
            ),

            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.folder_open_rounded, color: Colors.white12, size: 64),
                          const SizedBox(height: 16),
                          Text('No $_selectedCategory in your vault yet',
                              style: const TextStyle(color: Colors.white38, fontSize: 14)),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _showAddDocumentDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Document'),
                            style: ElevatedButton.styleFrom(backgroundColor: MyVaultColors.accentBlue),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final doc = filtered[i];
                        final icon = _getCategoryIcon(doc.category);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: MyVaultColors.glassFill,
                            border: Border.all(color: MyVaultColors.glassBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: MyVaultColors.accentBlue.withValues(alpha: 0.15),
                                    ),
                                    child: Icon(icon, color: MyVaultColors.accentCyan, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          doc.title,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${doc.category} • Added ${doc.addedDate}',
                                          style: const TextStyle(color: Colors.white38, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                    onPressed: () => _deleteDocument(doc.id),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _viewDocument(doc),
                                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 14),
                                      label: const Text('View Document'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: MyVaultColors.accentBlue,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _downloadDocument(doc),
                                      icon: const Icon(Icons.download_rounded, size: 14),
                                      label: const Text('Download'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: MyVaultColors.accentCyan,
                                        side: BorderSide(color: MyVaultColors.accentCyan.withValues(alpha: 0.5)),
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
