import 'package:flutter/material.dart';
import '../../core/colors.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;
  final bool showAppBar;
  final String title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const AppScaffold({
    super.key,
    required this.body,
    this.showAppBar = true,
    this.title = '',
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyVaultColors.obsidian,
      appBar: showAppBar
          ? AppBar(
              backgroundColor: MyVaultColors.obsidian,
              elevation: 0,
              title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              actions: actions,
            )
          : null,
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}
