import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        }
      },
      child: Scaffold(
        backgroundColor: MyVaultColors.backgroundWhite,
        appBar: showAppBar
            ? AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: MyVaultColors.metalBlack, size: 20),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                ),
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
      ),
    );
  }
}
