import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineItem {
  final String id;
  final String title;
  final String subtitle;
  final String hubType;
  final String remoteUrl;
  final String localPath;
  final int fileSizeBytes;
  final DateTime downloadedAt;
  final String? category;
  final int? unit;

  OfflineItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.hubType,
    required this.remoteUrl,
    required this.localPath,
    required this.fileSizeBytes,
    required this.downloadedAt,
    this.category,
    this.unit,
  });

  String get formattedSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'hubType': hubType,
        'remoteUrl': remoteUrl,
        'localPath': localPath,
        'fileSizeBytes': fileSizeBytes,
        'downloadedAt': downloadedAt.toIso8601String(),
        'category': category,
        'unit': unit,
      };

  factory OfflineItem.fromJson(Map<String, dynamic> json) => OfflineItem(
        id: json['id'] as String,
        title: json['title'] as String,
        subtitle: (json['subtitle'] ?? '') as String,
        hubType: (json['hubType'] ?? 'NOTE') as String,
        remoteUrl: json['remoteUrl'] as String,
        localPath: json['localPath'] as String,
        fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
        downloadedAt: DateTime.tryParse(json['downloadedAt'] as String? ?? '') ?? DateTime.now(),
        category: json['category'] as String?,
        unit: (json['unit'] as num?)?.toInt(),
      );
}

class OfflineVaultService {
  OfflineVaultService._internal();
  static final OfflineVaultService instance = OfflineVaultService._internal();

  static const _storageKey = 'myvault_offline_vault_index_v1';
  final Dio _dio = Dio();

  Future<List<OfflineItem>> getOfflineFiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return [];
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      final items = list.map((e) => OfflineItem.fromJson(e as Map<String, dynamic>)).toList();
      
      // Verify physical file existence
      final validItems = <OfflineItem>[];
      for (final it in items) {
        if (File(it.localPath).existsSync()) {
          validItems.add(it);
        }
      }
      return validItems;
    } catch (e) {
      debugPrint('[OfflineVault] Error reading index: $e');
      return [];
    }
  }

  Future<bool> isDownloaded(String remoteUrl) async {
    if (remoteUrl.isEmpty) return false;
    final items = await getOfflineFiles();
    return items.any((it) => it.remoteUrl == remoteUrl && File(it.localPath).existsSync());
  }

  Future<OfflineItem?> getDownloadedItem(String remoteUrl) async {
    final items = await getOfflineFiles();
    try {
      return items.firstWhere((it) => it.remoteUrl == remoteUrl);
    } catch (_) {
      return null;
    }
  }

  Future<OfflineItem?> downloadFile({
    required String id,
    required String title,
    required String subtitle,
    required String hubType,
    required String remoteUrl,
    String? category,
    int? unit,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final vaultDir = Directory('${dir.path}/offline_vault');
      if (!vaultDir.existsSync()) {
        vaultDir.createSync(recursive: true);
      }

      final safeFileName = '${id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}.pdf';
      final localFilePath = '${vaultDir.path}/$safeFileName';

      await _dio.download(
        remoteUrl,
        localFilePath,
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) {
            onProgress(received / total);
          }
        },
      );

      final file = File(localFilePath);
      final size = await file.length();

      final newItem = OfflineItem(
        id: id,
        title: title,
        subtitle: subtitle,
        hubType: hubType,
        remoteUrl: remoteUrl,
        localPath: localFilePath,
        fileSizeBytes: size,
        downloadedAt: DateTime.now(),
        category: category,
        unit: unit,
      );

      final current = await getOfflineFiles();
      current.removeWhere((it) => it.id == id || it.remoteUrl == remoteUrl);
      current.insert(0, newItem);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(current.map((e) => e.toJson()).toList()));

      return newItem;
    } catch (e) {
      debugPrint('[OfflineVault] Download failed: $e');
      return null;
    }
  }

  Future<bool> deleteOfflineFile(String id) async {
    try {
      final current = await getOfflineFiles();
      final target = current.firstWhere((it) => it.id == id);
      final file = File(target.localPath);
      if (file.existsSync()) {
        file.deleteSync();
      }
      current.removeWhere((it) => it.id == id);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(current.map((e) => e.toJson()).toList()));
      return true;
    } catch (e) {
      debugPrint('[OfflineVault] Delete error: $e');
      return false;
    }
  }

  Future<int> getTotalStorageUsedBytes() async {
    final items = await getOfflineFiles();
    int total = 0;
    for (final it in items) {
      total += it.fileSizeBytes;
    }
    return total;
  }

  Future<void> clearAllDownloads() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final vaultDir = Directory('${dir.path}/offline_vault');
      if (vaultDir.existsSync()) {
        vaultDir.deleteSync(recursive: true);
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (_) {}
  }
}
