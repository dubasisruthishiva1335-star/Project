import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router.dart';
import 'core/colors.dart';
import 'services/push_notification_service.dart';
import 'services/crash_telemetry_service.dart';
import 'widgets/global_error_boundary.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Zero-Crash Global Error Handler
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    CrashTelemetryService.instance.logError(
      details.exception,
      details.stack,
      reason: 'FlutterError Uncaught Exception',
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    CrashTelemetryService.instance.logError(
      error,
      stack,
      reason: 'PlatformDispatcher Uncaught Async Error',
    );
    return true; // Handled safely without process abort
  };

  // Safely initialize push notifications
  try {
    await PushNotificationService.instance.initialize(
      onCircularTapped: (message) {
        appRouter.go('/academic-hub');
      },
    );
  } catch (e) {
    debugPrint('Push notifications setup skipped: $e');
  }

  runApp(
    const ProviderScope(
      child: GlobalErrorBoundary(
        child: MyVaultApp(),
      ),
    ),
  );
}

class MyVaultApp extends StatelessWidget {
  const MyVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MyVault',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: MyVaultColors.backgroundWhite,
        colorScheme: ColorScheme.fromSeed(
          seedColor: MyVaultColors.metalBlack,
          brightness: Brightness.light,
        ),
      ),
      routerConfig: appRouter,
    );
  }
}
