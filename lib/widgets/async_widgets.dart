// lib/widgets/async_widgets.dart
// ─────────────────────────────────────────────────────────────
// Reusable widgets for async state: loading, error, offline.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Centered loading spinner with optional message.
class LoadingIndicator extends StatelessWidget {
  final String? message;
  const LoadingIndicator({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: cs.primary,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!,
                style: TextStyle(
                    fontSize: 14,
                    color: cs.onSurface.withOpacity(0.5),
                    fontFamily: 'Inter')),
          ],
        ],
      ),
    );
  }
}

/// Error display with retry action.
class ErrorDisplay extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorDisplay({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(isDark ? 0.2 : 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.cloud_off_rounded,
                  color: AppColors.error, size: 28),
            ),
            const SizedBox(height: 16),
            Text('Something went wrong',
                style: AppTextStyles.title(context, size: 18)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface.withOpacity(0.5),
                    fontFamily: 'Inter')),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Small banner showing offline / fallback state.
class OfflineBanner extends StatelessWidget {
  final String message;
  const OfflineBanner(
      {super.key, this.message = 'Working offline — using cached data'});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accentGold.withOpacity(0.15),
        border: Border(
            bottom: BorderSide(color: AppColors.accentGold.withOpacity(0.3))),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded,
              size: 16, color: AppColors.accentGold),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.accentGold,
                    fontFamily: 'Inter')),
          ),
        ],
      ),
    );
  }
}

/// Loading overlay shown during async mutations (e.g., placing order).
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  const LoadingOverlay(
      {super.key, required this.isLoading, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: const LoadingIndicator(message: 'Processing…'),
            ),
          ),
      ],
    );
  }
}
