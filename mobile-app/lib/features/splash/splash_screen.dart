import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/colors.dart';

/// Instant fade-in with a state redirect to /login or /home, avoiding the
/// "infinite loading hang" the product docs call out.
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
    final token = await ApiClient.instance.readToken();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(token != null ? '/home' : '/login');
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
