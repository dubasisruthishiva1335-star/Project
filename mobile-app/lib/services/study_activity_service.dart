import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyStudyActivity {
  final String dateString; // 'YYYY-MM-DD'
  final int minutesStudied;
  final int sessionsCount;
  final int documentsRead;

  DailyStudyActivity({
    required this.dateString,
    required this.minutesStudied,
    required this.sessionsCount,
    required this.documentsRead,
  });

  Map<String, dynamic> toJson() => {
        'dateString': dateString,
        'minutesStudied': minutesStudied,
        'sessionsCount': sessionsCount,
        'documentsRead': documentsRead,
      };

  factory DailyStudyActivity.fromJson(Map<String, dynamic> json) => DailyStudyActivity(
        dateString: json['dateString'] as String,
        minutesStudied: (json['minutesStudied'] as num?)?.toInt() ?? 0,
        sessionsCount: (json['sessionsCount'] as num?)?.toInt() ?? 0,
        documentsRead: (json['documentsRead'] as num?)?.toInt() ?? 0,
      );
}

class StudyActivityService {
  StudyActivityService._internal();
  static final StudyActivityService instance = StudyActivityService._internal();

  static const _storageKey = 'myvault_study_activity_v1';

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<Map<String, DailyStudyActivity>> getActivityMap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return {};
      final Map<String, dynamic> decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, DailyStudyActivity.fromJson(v as Map<String, dynamic>)));
    } catch (e) {
      debugPrint('[StudyActivity] Error reading activity: $e');
      return {};
    }
  }

  Future<void> recordStudySession({int minutes = 5, bool isDocumentRead = false}) async {
    try {
      final map = await getActivityMap();
      final today = _todayKey();
      final existing = map[today] ?? DailyStudyActivity(
        dateString: today,
        minutesStudied: 0,
        sessionsCount: 0,
        documentsRead: 0,
      );

      final updated = DailyStudyActivity(
        dateString: today,
        minutesStudied: existing.minutesStudied + minutes,
        sessionsCount: existing.sessionsCount + 1,
        documentsRead: existing.documentsRead + (isDocumentRead ? 1 : 0),
      );

      map[today] = updated;

      final prefs = await SharedPreferences.getInstance();
      final jsonMap = map.map((k, v) => MapEntry(k, v.toJson()));
      await prefs.setString(_storageKey, jsonEncode(jsonMap));
    } catch (e) {
      debugPrint('[StudyActivity] Record error: $e');
    }
  }

  Future<int> getCurrentStreakDays() async {
    final map = await getActivityMap();
    int streak = 0;
    DateTime check = DateTime.now();

    while (true) {
      final key = '${check.year}-${check.month.toString().padLeft(2, '0')}-${check.day.toString().padLeft(2, '0')}';
      final act = map[key];
      if (act != null && act.minutesStudied > 0) {
        streak++;
        check = check.subtract(const Duration(days: 1));
      } else {
        // Allow today to be uncompleted if yesterday was completed
        if (streak == 0 && check.day == DateTime.now().day) {
          check = check.subtract(const Duration(days: 1));
          final yKey = '${check.year}-${check.month.toString().padLeft(2, '0')}-${check.day.toString().padLeft(2, '0')}';
          if (map[yKey] != null && map[yKey]!.minutesStudied > 0) {
            streak++;
            check = check.subtract(const Duration(days: 1));
            continue;
          }
        }
        break;
      }
    }
    return streak;
  }

  Future<int> getTotalHoursStudied() async {
    final map = await getActivityMap();
    int totalMins = 0;
    for (final a in map.values) {
      totalMins += a.minutesStudied;
    }
    return (totalMins / 60).round();
  }
}
