import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router.dart';
import 'core/colors.dart';
import 'services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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

  runApp(const ProviderScope(child: MyVaultApp()));
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
        brightness: Brightness.dark,
        scaffoldBackgroundColor: MyVaultColors.obsidian,
        colorScheme: ColorScheme.fromSeed(
          seedColor: MyVaultColors.accentBlue,
          brightness: Brightness.dark,
        ),
      ),
      routerConfig: appRouter,
    );
  }
}
