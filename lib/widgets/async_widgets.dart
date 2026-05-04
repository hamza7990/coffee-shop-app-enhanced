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
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: cs.primary,
            ),
          ),
          if (message != null) ...[
            AppSpacing.h16,
            Text(message!, style: AppTextStyles.muted(context, size: 14)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isDark ? AppColors.errorDarkBg : AppColors.errorLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off_rounded,
                  color: AppColors.error, size: 28),
            ),
            AppSpacing.h16,
            Text('Something went wrong',
                style: AppTextStyles.title(context, size: 18)),
            AppSpacing.h8,
            Text(message,
                textAlign: TextAlign.center,
                style: AppTextStyles.muted(context)),
            if (onRetry != null) ...[
              AppSpacing.h20,
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Try Again'),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.warningDarkBg : AppColors.warningLight,
        border: Border(
            bottom: BorderSide(color: AppColors.warning.withValues(alpha: 0.3))),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 16, color: AppColors.warning),
          AppSpacing.w8,
          Expanded(
            child: Text(message,
                style: AppTextStyles.caption(context, color: AppColors.warning)),
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
              color: Colors.black.withValues(alpha: 0.3),
              child: const LoadingIndicator(message: 'Processing…'),
            ),
          ),
      ],
    );
  }
}
