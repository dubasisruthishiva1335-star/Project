import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/colors.dart';

/// Instant splash screen with robust GoRouter navigation redirect.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();

  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    // Brief delay to allow initial animation
    await Future.delayed(const Duration(milliseconds: 400));
    try {
      final token = await ApiClient.instance.readToken().timeout(
            const Duration(seconds: 2),
            onTimeout: () => null,
          );
      if (!mounted) return;
      if (token != null && token.isNotEmpty) {
        context.go('/home');
      } else {
        context.go('/login');
      }
    } catch (_) {
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyVaultColors.obsidian,
      body: Center(
        child: FadeTransition(
          opacity: _controller,
          child: ShaderMask(
            shaderCallback: (bounds) => MyVaultColors.accentGradient.createShader(bounds),
            child: const Text(
              'MyVault',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
