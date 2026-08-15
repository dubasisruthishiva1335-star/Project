import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../widgets/file_action_handler.dart';
import '../../models/uploaded_file_model.dart';
import '../../services/uploaded_files_service.dart';

class UploadedFilesScreen extends StatefulWidget {
  const UploadedFilesScreen({super.key});

  @override
  State<UploadedFilesScreen> createState() => _UploadedFilesScreenState();
}

class _UploadedFilesScreenState extends State<UploadedFilesScreen> {
  List<UploadedFileModel> _files = [];
  bool _loading = true;
  bool _uploading = false;
  double _uploadProgress = 0.0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final list = await UploadedFilesService.fetchUploadedFiles();
      if (mounted) {
        setState(() {
          _files = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load files: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _pickAndUploadFile() async {
    final titleController = TextEditingController();

    final filePickerResult = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: UploadedFilesService.allowedExtensions,
    );

    if (filePickerResult == null || filePickerResult.files.single.path == null) {
      return;
    }

    final file = File(filePickerResult.files.single.path!);
    final defaultTitle = filePickerResult.files.single.name;
    titleController.text = defaultTitle.split('.').first;

    if (!mounted) return;

    // Show Title Dialog
    final confirmUpload = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Upload File',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Poppins'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selected: $defaultTitle',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'File Title',
                hintText: 'Enter title...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Upload'),
          ),
        ],
      ),
    );

    if (confirmUpload != true) return;

    setState(() {
      _uploading = true;
      _uploadProgress = 0.1;
    });

    try {
      await UploadedFilesService.uploadFile(
        file: file,
        title: titleController.text,
        onProgress: (p) {
          if (mounted) setState(() => _uploadProgress = p);
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File uploaded successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
      await _loadFiles();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  Future<void> _confirmDelete(UploadedFileModel item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete File',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Poppins'),
        ),
        content: Text(
          'Are you sure you want to delete "${item.title}"?',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await UploadedFilesService.deleteFile(item);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File deleted.')),
        );
      }
      await _loadFiles();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  IconData _getFileIcon(String ext) {
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image_outlined;
      case 'doc':
      case 'docx':
        return Icons.description_outlined;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  Color _getFileColor(String ext) {
    switch (ext) {
      case 'pdf':
        return const Color(0xFFFF6B6B);
      case 'jpg':
      case 'jpeg':
      case 'png':
        return const Color(0xFF3B82F6);
      case 'doc':
      case 'docx':
        return const Color(0xFF6C63FF);
      case 'xls':
      case 'xlsx':
        return const Color(0xFF2ECC71);
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showAppBar: true,
      title: 'Uploaded Files',
      actions: [
        IconButton(
          icon: const Icon(Icons.upload_file_rounded, color: AppColors.primary),
          tooltip: 'Upload File',
          onPressed: _uploading ? null : _pickAndUploadFile,
        ),
      ],
      body: Column(
        children: [
          if (_uploading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.primary.withValues(alpha: 0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Uploading file...',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
                      ),
                      Text(
                        '${(_uploadProgress * 100).toInt()}%',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: _uploadProgress,
                    backgroundColor: AppColors.border,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadFiles,
              color: AppColors.primary,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.redAccent, fontFamily: 'Poppins'),
                            ),
                          ),
                        )
                      : _files.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.cloud_upload_outlined,
                                      size: 48,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No uploaded files yet',
                                    style: AppTextStyles.heading3,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Tap the upload button above to add PDF, Images, DOC, or XLS files.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton.icon(
                                    onPressed: _pickAndUploadFile,
                                    icon: const Icon(Icons.add_rounded),
                                    label: const Text('Upload File'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _files.length,
                              itemBuilder: (context, i) {
                                final item = _files[i];
                                final icon = _getFileIcon(item.fileType);
                                final color = _getFileColor(item.fileType);

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(color: color.withValues(alpha: 0.2)),
                                  ),
                                  child: ListTile(
                                    onTap: () => FileActionHandler.handleFileTap(
                                      context: context,
                                      fileUrl: item.publicUrl,
                                      fileName: item.fileName,
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor: color.withValues(alpha: 0.1),
                                      child: Icon(icon, color: color, size: 22),
                                    ),
                                    title: Text(
                                      item.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${item.fileType.toUpperCase()} • ${item.fileSizeFormatted}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove_red_eye_rounded, size: 20, color: AppColors.primary),
                                          onPressed: () => FileActionHandler.handleFileTap(
                                            context: context,
                                            fileUrl: item.publicUrl,
                                            fileName: item.fileName,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                                          onPressed: () => _confirmDelete(item),
                                        ),
                                      ],
                                    ),
                                  ),
                                ).animate(delay: Duration(milliseconds: i * 50)).fadeIn().slideY(begin: 0.1);
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }
}
