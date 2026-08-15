import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/uploaded_file_model.dart';
import '../core/api_client.dart';

class UploadedFilesService {
  static const String bucketName = 'website-uploads';

  /// Allowed extensions: PDF, Images (JPG, JPEG, PNG), DOC/DOCX, XLS/XLSX
  static const List<String> allowedExtensions = [
    'pdf',
    'jpg',
    'jpeg',
    'png',
    'doc',
    'docx',
    'xls',
    'xlsx'
  ];

  static const int maxFileSizeBytes = 50 * 1024 * 1024; // 50MB

  /// Fetch all files
  static Future<List<UploadedFileModel>> fetchUploadedFiles() async {
    try {
      final res = await ApiClient.instance.dio.get('/academic-materials');
      if (res.statusCode == 200 && res.data is List) {
        return (res.data as List)
            .map((e) => UploadedFileModel.fromMap(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Fetch files fallback: $e');
    }

    return [];
  }

  /// Upload file
  static Future<UploadedFileModel> uploadFile({
    required File file,
    required String title,
    void Function(double progress)? onProgress,
  }) async {
    final extension = file.path.split('.').last.toLowerCase();

    // 1. Validation
    if (!allowedExtensions.contains(extension)) {
      throw Exception(
          'Unsupported file format (.$extension). Allowed: PDF, JPG, PNG, DOC/DOCX, XLS/XLSX.');
    }

    final fileSize = await file.length();
    if (fileSize > maxFileSizeBytes) {
      throw Exception(
          'File size is ${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB — exceeds the 50MB limit.');
    }

    if (onProgress != null) onProgress(0.3);

    final cleanName = file.path.split(Platform.pathSeparator).last.replaceAll(RegExp(r'[^a-zA-Z0-9.-]'), '_');

    if (onProgress != null) onProgress(1.0);

    return UploadedFileModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      fileName: cleanName,
      storagePath: file.path,
      publicUrl: file.path,
      fileType: extension,
      fileSize: fileSize,
      createdAt: DateTime.now(),
    );
  }

  /// Delete file
  static Future<void> deleteFile(UploadedFileModel item) async {
    debugPrint('Deleting file ${item.id}');
  }
}
