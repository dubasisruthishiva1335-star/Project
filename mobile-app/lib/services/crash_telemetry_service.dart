import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Non-blocking Telemetry & Crash Reporting service.
/// Safely logs runtime exceptions, non-fatal errors, and diagnostic events.
class CrashTelemetryService {
  CrashTelemetryService._internal();
  static final CrashTelemetryService instance = CrashTelemetryService._internal();

  static const _crashLogsKey = 'myvault_telemetry_crash_logs';

  Future<void> logError(Object error, StackTrace? stack, {String? reason}) async {
    debugPrint('[Telemetry Error] reason: $reason | error: $error');
    if (stack != null) {
      debugPrint('[Telemetry StackTrace] $stack');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final logs = prefs.getStringList(_crashLogsKey) ?? [];
      final entry = '${DateTime.now().toIso8601String()} | ${reason ?? 'General'} | $error';
      logs.insert(0, entry);
      if (logs.length > 50) logs.removeRange(50, logs.length);
      await prefs.setStringList(_crashLogsKey, logs);
    } catch (_) {}
  }

  Future<void> logEvent(String eventName, {Map<String, dynamic>? parameters}) async {
    debugPrint('[Telemetry Event] $eventName: $parameters');
  }

  Future<List<String>> getRecentErrorLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_crashLogsKey) ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<void> clearLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_crashLogsKey);
    } catch (_) {}
  }
}
