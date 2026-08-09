import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _HomeTile('Academic Hub', Icons.menu_book_rounded, () => context.go('/academic-hub')),
      _HomeTile('Internships', Icons.work_outline_rounded, () {}),
      _HomeTile('Placements', Icons.business_center_outlined, () {}),
      _HomeTile('Results', Icons.grade_outlined, () {}),
      _HomeTile('Govt Jobs', Icons.account_balance_outlined, () {}),
      _HomeTile('Aptitude', Icons.psychology_outlined, () {}),
    ];

    return Scaffold(
      backgroundColor: MyVaultColors.obsidian,
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (b) => MyVaultColors.accentGradient.createShader(b),
          child: const Text('MyVault', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
      body: SafeArea(
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
          ),
          itemCount: tiles.length,
          itemBuilder: (context, i) => tiles[i],
        ),
      ),
    );
  }
}

class _HomeTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _HomeTile(this.label, this.icon, this.onTap);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: MyVaultColors.glassFill,
          border: Border.all(color: MyVaultColors.glassBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: MyVaultColors.accentCyan, size: 32),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
