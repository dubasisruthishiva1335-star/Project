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
        context.go('/home');
      }
    } catch (_) {
      if (!mounted) return;
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyVaultColors.backgroundWhite,
      body: Container(
        decoration: const BoxDecoration(
          gradient: MyVaultColors.whiteShadingGradient,
        ),
        child: Center(
          child: FadeTransition(
            opacity: _controller,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: MyVaultColors.metalGradient,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x18000000),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 42),
                ),
                const SizedBox(height: 16),
                const Text(
                  'MyVault',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: MyVaultColors.metalBlack,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Student Academic & Career OS',
                  style: TextStyle(
                    fontSize: 13,
                    color: MyVaultColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
