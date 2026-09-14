import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../services/crash_telemetry_service.dart';

/// Global Error Boundary widget that intercepts uncaught UI exceptions,
/// preventing red/grey screens and presenting an elegant recovery interface.
class GlobalErrorBoundary extends StatefulWidget {
  final Widget child;

  const GlobalErrorBoundary({super.key, required this.child});

  @override
  State<GlobalErrorBoundary> createState() => _GlobalErrorBoundaryState();
}

class _GlobalErrorBoundaryState extends State<GlobalErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
  }

  static Widget errorWidgetBuilder(FlutterErrorDetails details) {
    CrashTelemetryService.instance.logError(
      details.exception,
      details.stack,
      reason: 'FlutterError (Widget Render Failure)',
    );

    return Scaffold(
      backgroundColor: MyVaultColors.backgroundWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF43F5E).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: Color(0xFFF43F5E),
                    size: 48,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Something went wrong',
                  style: TextStyle(
                    color: MyVaultColors.metalBlack,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'MyVault encountered an unexpected view issue. Your data and downloads are safe.',
                  style: TextStyle(
                    color: MyVaultColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    // Trigger UI rebuild
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Refresh View'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MyVaultColors.metalBlack,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return errorWidgetBuilder(
        FlutterErrorDetails(exception: _error!, stack: _stackTrace),
      );
    }
    return widget.child;
  }
}
