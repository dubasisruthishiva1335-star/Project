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
      backgroundColor: MyVaultColors.backgroundWhite,
      appBar: showAppBar
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: MyVaultColors.metalBlack),
              title: Text(
                title,
                style: const TextStyle(
                  color: MyVaultColors.metalBlack,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              actions: actions,
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(1),
                child: Divider(height: 1, color: Color(0xFFE2E8F0)),
              ),
            )
          : null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: MyVaultColors.whiteShadingGradient,
        ),
        child: body,
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
