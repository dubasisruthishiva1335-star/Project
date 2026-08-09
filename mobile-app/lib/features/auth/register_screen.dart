import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _hallTicket = TextEditingController();
  final _fullName = TextEditingController();
  final _branch = TextEditingController();
  String _courseType = 'btech';
  int _year = 1;
  bool _loading = false;
  String? _error;

  Future<void> _register() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dio = ApiClient.instance.dio;
      final res = await dio.post('/auth/register', data: {
        'hallTicket': _hallTicket.text.trim(),
        'fullName': _fullName.text.trim(),
        'courseType': _courseType,
        'branch': _branch.text.trim(),
        'semester': _year,
      });
      await ApiClient.instance.saveToken(res.data['accessToken']);
      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      setState(() => _error = 'Could not create your account. Check your details and try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyVaultColors.obsidian,
      appBar: AppBar(title: const Text('Register')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'btech', label: Text('B.Tech')),
                  ButtonSegment(value: 'degree', label: Text('Degree')),
                ],
                selected: {_courseType},
                onSelectionChanged: (s) => setState(() => _courseType = s.first),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _hallTicket,
                decoration: const InputDecoration(labelText: 'Hall Ticket Number'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _fullName,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  helperText: 'Stored as "Lastname Firstname" automatically',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _branch,
                decoration: const InputDecoration(labelText: 'Branch (e.g. CSE, ECE, MECH)'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _year,
                decoration: const InputDecoration(labelText: 'Year'),
                items: List.generate(4, (i) => i + 1)
                    .map((y) => DropdownMenuItem(value: y, child: Text('Year $y')))
                    .toList(),
                onChanged: (v) => setState(() => _year = v ?? 1),
              ),
              const SizedBox(height: 8),
              Text(
                'Your password defaults to your hall ticket number.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _register,
                child: Text(_loading ? 'Creating account…' : 'Create Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
