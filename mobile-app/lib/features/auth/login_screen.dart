import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/colors.dart';
import 'dev_settings_sheet.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _hallTicketController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;
  int _logoTaps = 0;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dio = ApiClient.instance.dio;
      final res = await dio.post('/auth/login', data: {
        'hallTicket': _hallTicketController.text.trim(),
        'password': _passwordController.text,
      });
      await ApiClient.instance.saveToken(res.data['accessToken']);
      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      setState(() => _error = 'Invalid hall ticket or password.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _handleLogoTap() {
    _logoTaps++;
    if (_logoTaps >= 2) {
      _logoTaps = 0;
      showModalBottomSheet(
        context: context,
        backgroundColor: MyVaultColors.obsidian,
        builder: (_) => const DevSettingsSheet(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyVaultColors.obsidian,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GestureDetector(
                    onTap: _handleLogoTap,
                    child: ShaderMask(
                      shaderCallback: (b) => MyVaultColors.accentGradient.createShader(b),
                      child: const Text('MyVault',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _hallTicketController,
                    decoration: const InputDecoration(labelText: 'Hall Ticket Number'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _loading ? null : _login,
                    child: Text(_loading ? 'Signing in…' : 'Log In'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.go('/register'),
                    child: const Text('New student? Register'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
