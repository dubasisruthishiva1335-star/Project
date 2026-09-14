import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookmarkItem {
  final String id;
  final String title;
  final String subtitle;
  final String hubType; // 'NOTE', 'COURSE', 'EXAM', 'INTERNSHIP'
  final String? fileUrl;
  final String? targetRoute;
  final DateTime bookmarkedAt;
  final String? badgeText;

  BookmarkItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.hubType,
    this.fileUrl,
    this.targetRoute,
    required this.bookmarkedAt,
    this.badgeText,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'hubType': hubType,
        'fileUrl': fileUrl,
        'targetRoute': targetRoute,
        'bookmarkedAt': bookmarkedAt.toIso8601String(),
        'badgeText': badgeText,
      };

  factory BookmarkItem.fromJson(Map<String, dynamic> json) => BookmarkItem(
        id: json['id'] as String,
        title: json['title'] as String,
        subtitle: (json['subtitle'] ?? '') as String,
        hubType: (json['hubType'] ?? 'NOTE') as String,
        fileUrl: json['fileUrl'] as String?,
        targetRoute: json['targetRoute'] as String?,
        bookmarkedAt: DateTime.tryParse(json['bookmarkedAt'] as String? ?? '') ?? DateTime.now(),
        badgeText: json['badgeText'] as String?,
      );
}

class BookmarkService {
  BookmarkService._internal();
  static final BookmarkService instance = BookmarkService._internal();

  static const _storageKey = 'myvault_bookmarks_store_v1';

  Future<List<BookmarkItem>> getBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return [];
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => BookmarkItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('[BookmarkService] Error reading bookmarks: $e');
      return [];
    }
  }

  Future<bool> isBookmarked(String id) async {
    final list = await getBookmarks();
    return list.any((b) => b.id == id);
  }

  Future<bool> toggleBookmark(BookmarkItem item) async {
    try {
      final list = await getBookmarks();
      final exists = list.any((b) => b.id == item.id);
      if (exists) {
        list.removeWhere((b) => b.id == item.id);
      } else {
        list.insert(0, item);
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(list.map((e) => e.toJson()).toList()));
      return !exists;
    } catch (e) {
      debugPrint('[BookmarkService] Toggle error: $e');
      return false;
    }
  }

  Future<void> removeBookmark(String id) async {
    try {
      final list = await getBookmarks();
      list.removeWhere((b) => b.id == id);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(list.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }
}
