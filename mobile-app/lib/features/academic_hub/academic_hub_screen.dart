import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/colors.dart';

const _branches = ['ECE', 'CSE', 'AI_ML', 'EEE', 'MECH', 'CIVIL', 'GENERAL'];

class AcademicHubScreen extends StatefulWidget {
  const AcademicHubScreen({super.key});

  @override
  State<AcademicHubScreen> createState() => _AcademicHubScreenState();
}

class _AcademicHubScreenState extends State<AcademicHubScreen> {
  String _branch = 'CSE';
  int _year = 1;
  List<dynamic> _subjects = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiClient.instance.dio.get('/subjects', queryParameters: {
        'branch': _branch,
        'year': _year,
      });
      setState(() => _subjects = res.data as List<dynamic>);
    } catch (e) {
      setState(() => _error = "Couldn't load live data — showing cached view.");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyVaultColors.obsidian,
      appBar: AppBar(title: const Text('Academic Hub')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _branch,
                      decoration: const InputDecoration(labelText: 'Branch'),
                      items: _branches.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                      onChanged: (v) {
                        setState(() => _branch = v ?? _branch);
                        _load();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _year,
                      decoration: const InputDecoration(labelText: 'Year'),
                      items: List.generate(4, (i) => i + 1)
                          .map((y) => DropdownMenuItem(value: y, child: Text('Year $y')))
                          .toList(),
                      onChanged: (v) {
                        setState(() => _year = v ?? _year);
                        _load();
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(_error!, style: const TextStyle(color: Colors.orangeAccent, fontSize: 12)),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _subjects.isEmpty
                      ? Center(
                          child: Text('No subjects yet for $_branch, Year $_year',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _subjects.length,
                          itemBuilder: (context, i) {
                            final subject = _subjects[i] as Map<String, dynamic>;
                            final contents = (subject['contents'] as List<dynamic>? ?? []);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: MyVaultColors.glassFill,
                                border: Border.all(color: MyVaultColors.glassBorder),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${subject['code']} — ${subject['name']}',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    children: contents
                                        .map((c) => Chip(label: Text((c as Map)['contentType'] as String)))
                                        .toList(),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
