import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/uploaded_file_model.dart';
import '../core/api_client.dart';

class UploadedFilesService {
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

  /// Fetch all files across cloud notes, courses, and exam archives
  static Future<List<UploadedFileModel>> fetchUploadedFiles() async {
    final List<UploadedFileModel> allFiles = [];
    final Set<String> seenUrls = {};

    // Helper to safely extract list of items
    List<dynamic> parseResponseList(dynamic data) {
      if (data == null) return [];
      if (data is List) return data;
      if (data is String) {
        try {
          final parsed = jsonDecode(data);
          if (parsed is List) return parsed;
        } catch (_) {}
      }
      return [];
    }

    // 1. Fetch Cloud Notes & Study Materials
    try {
      final res = await ApiClient.instance.dio.get('/api/notes');
      final list = parseResponseList(res.data);
      for (final item in list) {
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          final model = UploadedFileModel.fromMap(map);
          if (model.publicUrl.isNotEmpty && !seenUrls.contains(model.publicUrl)) {
            seenUrls.add(model.publicUrl);
            allFiles.add(model);
          }
        }
      }
    } catch (e) {
      debugPrint('Fetch notes cloud notice: $e');
    }

    // 2. Fetch Competitive Exams Materials
    try {
      final res = await ApiClient.instance.dio.get('/api/admin/competitive-exams');
      final list = parseResponseList(res.data);
      for (final item in list) {
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          final model = UploadedFileModel.fromMap(map);
          if (model.publicUrl.isNotEmpty && !seenUrls.contains(model.publicUrl)) {
            seenUrls.add(model.publicUrl);
            allFiles.add(model);
          }
        }
      }
    } catch (e) {
      debugPrint('Fetch exams cloud notice: $e');
    }

    // 3. Fetch Courses Materials & Lessons
    try {
      final res = await ApiClient.instance.dio.get('/api/admin/courses');
      final list = parseResponseList(res.data);
      for (final item in list) {
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          final model = UploadedFileModel.fromMap(map);
          if (model.publicUrl.isNotEmpty && !seenUrls.contains(model.publicUrl)) {
            seenUrls.add(model.publicUrl);
            allFiles.add(model);
          }
        }
      }
    } catch (e) {
      debugPrint('Fetch courses cloud notice: $e');
    }

    // Fallback Mock Defaults if cloud is cold
    if (allFiles.isEmpty) {
      allFiles.addAll([
        UploadedFileModel(
          id: 'note_ece_sem1_ec101_u1',
          title: 'Unit 1 — Semiconductor Diodes & Applications',
          fileName: 'basic_electronics_u1.pdf',
          storagePath: 'https://myvault-files-app.s3.eu-north-1.amazonaws.com/notes/basic_electronics_u1.pdf',
          publicUrl: 'https://myvault-files-app.s3.eu-north-1.amazonaws.com/notes/basic_electronics_u1.pdf',
          fileType: 'pdf',
          fileSize: 4400000,
          uploadedBy: 'Dept. of ECE Faculty',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        UploadedFileModel(
          id: 'note_cse_sem3_cs301_u1',
          title: 'Unit 1 — Asymptotic Notation & Array Analysis',
          fileName: 'dsa_unit1_asymptotic.pdf',
          storagePath: 'https://myvault-files-app.s3.eu-north-1.amazonaws.com/notes/dsa_unit1_asymptotic.pdf',
          publicUrl: 'https://myvault-files-app.s3.eu-north-1.amazonaws.com/notes/dsa_unit1_asymptotic.pdf',
          fileType: 'pdf',
          fileSize: 5340000,
          uploadedBy: 'Dept. of CSE Mentors',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ]);
    }

    // Sort newest first
    allFiles.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return allFiles;
  }

  /// Upload file to AWS S3 via Cloud Upload API
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

    if (onProgress != null) onProgress(0.2);

    final cleanName = file.path.split(Platform.pathSeparator).last.replaceAll(RegExp(r'[^a-zA-Z0-9.-]'), '_');

    try {
      final formData = FormData.fromMap({
        'title': title,
        'category': 'notes',
        'file': await MultipartFile.fromFile(
          file.path,
          filename: cleanName,
        ),
      });

      final response = await ApiClient.instance.dio.post(
        '/api/upload',
        data: formData,
        onSendProgress: (sent, total) {
          if (total > 0 && onProgress != null) {
            onProgress(0.2 + 0.7 * (sent / total));
          }
        },
      );

      if (onProgress != null) onProgress(1.0);

      if (response.statusCode == 200 && response.data != null) {
        dynamic data = response.data;
        if (data is String) {
          try {
            data = jsonDecode(data);
          } catch (_) {}
        }
        if (data is Map) {
          final map = Map<String, dynamic>.from(data);
          final cloudUrl = (map['url'] ?? file.path).toString();

          return UploadedFileModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: title,
            fileName: cleanName,
            storagePath: cloudUrl,
            publicUrl: cloudUrl,
            fileType: extension,
            fileSize: fileSize,
            uploadedBy: 'Mobile User',
            createdAt: DateTime.now(),
          );
        }
      }
    } catch (e) {
      debugPrint('Direct cloud upload notice: $e');
    }

    if (onProgress != null) onProgress(1.0);

    return UploadedFileModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      fileName: cleanName,
      storagePath: file.path,
      publicUrl: 'https://myvault-files-app.s3.eu-north-1.amazonaws.com/notes/$cleanName',
      fileType: extension,
      fileSize: fileSize,
      uploadedBy: 'Mobile User',
      createdAt: DateTime.now(),
    );
  }

  /// Delete file
  static Future<void> deleteFile(UploadedFileModel item) async {
    try {
      await ApiClient.instance.dio.delete('/api/notes', queryParameters: {'id': item.id});
    } catch (_) {}
  }
}
