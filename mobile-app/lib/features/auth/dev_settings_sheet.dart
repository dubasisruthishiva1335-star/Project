import 'package:flutter/material.dart';
import '../../core/api_client.dart';

/// Triggered by double-tapping the logo on the Login screen. Lets a
/// developer switch backend URLs on-device without a rebuild.
class DevSettingsSheet extends StatefulWidget {
  const DevSettingsSheet({super.key});

  @override
  State<DevSettingsSheet> createState() => _DevSettingsSheetState();
}

class _DevSettingsSheetState extends State<DevSettingsSheet> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    ApiClient.instance.getBaseUrl().then((url) => _controller.text = url);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Developer Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(labelText: 'Backend API URL'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              await ApiClient.instance.setBaseUrl(_controller.text.trim());
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
