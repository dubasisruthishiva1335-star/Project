import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/router.dart';
import 'core/theme/app_themes.dart';
import 'core/theme/theme_provider.dart';
import 'services/crash_telemetry_service.dart';
import 'services/notification_service.dart';
import 'widgets/global_error_boundary.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Bulletproof Zero-Crash Firebase Initialization
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }
  } catch (e) {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
    } catch (e2) {
      debugPrint('Firebase init safe fallback: $e2');
    }
  }

  // 2. Initialize Push & Local Notification Service
  try {
    await NotificationService.instance.initialize();
  } catch (e) {
    debugPrint('Notification service init: $e');
  }

  // 3. Global Crash Telemetry & Error Boundary
  FlutterError.onError = (FlutterErrorDetails details) {
    CrashTelemetryService.instance.logError(
      details.exception,
      details.stack,
      reason: 'Uncaught Flutter Framework Error',
    );
    FlutterError.presentError(details);
  };

  runApp(
    const ProviderScope(
      child: MyVaultApp(),
    ),
  );
}

class MyVaultApp extends ConsumerWidget {
  const MyVaultApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'MyVault',
      debugShowCheckedModeBanner: false,
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
      builder: (context, child) {
        return GlobalErrorBoundary(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
