// lib/widgets/common_widgets.dart
// ─────────────────────────────────────────────────────────────
// Brewhaus Reusable Component Library v2
//
//  AppCard          – styled card with optional padding & hover
//  StatCard         – metric tile (icon + value + label + badge)
//  SectionHeader    – page title + optional action button
//  CategoryChip     – filter pill button with animation
//  AppButton        – primary / outlined / ghost button variants
//  StatusBadge      – coloured pill for table/order status
//  AppTextField     – form input with label + optional prefix
//  ConfirmDialog    – styled confirmation dialog
//  AppDivider       – themed divider
//  EmptyState       – placeholder for empty lists
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ══════════════════════════════════════════════════════════════
// APP CARD
// ══════════════════════════════════════════════════════════════
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final Color? color;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.borderColor,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: color ?? cs.surface,
          borderRadius: AppRadius.xlAll,
          border: Border.all(color: borderColor ?? cs.outline),
          boxShadow: isDark ? AppShadows.darkSm : AppShadows.sm,
        ),
        child: child,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// STAT CARD
// ══════════════════════════════════════════════════════════════
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String badge;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: AppRadius.mdAll,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(badge,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: iconColor),
                ),
              ),
            ],
          ),
          AppSpacing.h16,
          Text(value, style: AppTextStyles.displayStyle(ctx: context, size: 26)),
          AppSpacing.h4,
          Text(label, style: AppTextStyles.muted(context)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SECTION HEADER
// ══════════════════════════════════════════════════════════════
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.displayStyle(ctx: context, size: 28)),
              if (subtitle != null) ...[
                AppSpacing.h4,
                Text(subtitle!, style: AppTextStyles.muted(context, size: 14)),
              ],
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// CATEGORY CHIP
// ══════════════════════════════════════════════════════════════
class CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? cs.primary.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected ? cs.primary : cs.outline,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.55),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// APP BUTTON
// ══════════════════════════════════════════════════════════════
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool outlined;
  final bool small;
  final Color? color;
  final bool loading;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.outlined = false,
    this.small = false,
    this.color,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    final pad = small
        ? const EdgeInsets.symmetric(horizontal: 14, vertical: 8)
        : const EdgeInsets.symmetric(horizontal: 20, vertical: 12);

    final style = outlined
        ? OutlinedButton.styleFrom(
            foregroundColor: c,
            side: BorderSide(color: c),
            padding: pad,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          )
        : ElevatedButton.styleFrom(
            backgroundColor: c,
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            padding: pad,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          );

    final Widget child;
    if (loading) {
      child = SizedBox(
        width: small ? 14 : 18, height: small ? 14 : 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: outlined ? c : Colors.white,
        ),
      );
    } else if (icon != null) {
      child = Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: small ? 16 : 18),
        SizedBox(width: small ? 4 : 6),
        Text(label, style: TextStyle(fontSize: small ? 12 : 14, fontWeight: FontWeight.w600)),
      ]);
    } else {
      child = Text(label, style: TextStyle(fontSize: small ? 12 : 14, fontWeight: FontWeight.w600));
    }

    return outlined
        ? OutlinedButton(onPressed: loading ? null : onPressed, style: style, child: child)
        : ElevatedButton(onPressed: loading ? null : onPressed, style: style, child: child);
  }
}

// ══════════════════════════════════════════════════════════════
// STATUS BADGE
// ══════════════════════════════════════════════════════════════
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// APP TEXT FIELD
// ══════════════════════════════════════════════════════════════
class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int? maxLines;
  final Widget? prefix;
  final Widget? suffix;
  final bool obscureText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    required this.controller,
    this.keyboardType,
    this.maxLines = 1,
    this.prefix,
    this.suffix,
    this.obscureText = false,
    this.validator,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
          style: AppTextStyles.body(context, size: 13, weight: FontWeight.w500),
        ),
        AppSpacing.h8,
        validator != null
          ? TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              maxLines: maxLines,
              obscureText: obscureText,
              validator: validator,
              onFieldSubmitted: onSubmitted,
              decoration: InputDecoration(
                hintText: hint,
                prefixIcon: prefix,
                suffixIcon: suffix,
              ),
            )
          : TextField(
              controller: controller,
              keyboardType: keyboardType,
              maxLines: maxLines,
              obscureText: obscureText,
              onSubmitted: onSubmitted,
              decoration: InputDecoration(
                hintText: hint,
                prefixIcon: prefix,
                suffixIcon: suffix,
              ),
            ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// CONFIRM DIALOG
// ══════════════════════════════════════════════════════════════
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  Color? confirmColor,
}) async {
  final cs = Theme.of(context).colorScheme;

  return await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
      title: Text(title, style: AppTextStyles.title(context, size: 18)),
      content: Text(message, style: AppTextStyles.body(context)),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel',
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.w500),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor ?? cs.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  ) ?? false;
}

// ══════════════════════════════════════════════════════════════
// APP DIVIDER
// ══════════════════════════════════════════════════════════════
class AppDivider extends StatelessWidget {
  final double? indent;
  const AppDivider({super.key, this.indent});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: Theme.of(context).colorScheme.outline,
      indent: indent,
      endIndent: indent,
    );
  }
}

// ══════════════════════════════════════════════════════════════
// EMPTY STATE
// ══════════════════════════════════════════════════════════════
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: cs.primary.withValues(alpha: 0.4)),
            ),
            AppSpacing.h16,
            Text(title, style: AppTextStyles.title(context, size: 18)),
            if (subtitle != null) ...[
              AppSpacing.h8,
              Text(subtitle!,
                textAlign: TextAlign.center,
                style: AppTextStyles.muted(context, size: 14),
              ),
            ],
            if (action != null) ...[
              AppSpacing.h20,
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
