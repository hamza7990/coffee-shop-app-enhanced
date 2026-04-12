// lib/widgets/common_widgets.dart
// ─────────────────────────────────────────────────────────────
// Reusable building blocks used across multiple screens.
//
//  AppCard          – styled Card with optional padding
//  StatCard         – metric tile (icon + value + label + badge)
//  SectionHeader    – page title + optional action button
//  CategoryChip     – filter pill button
//  AppButton        – primary / outlined button variants
//  StatusBadge      – coloured pill for table/order status
//  AppTextField     – styled text input wrapper
//  ConfirmDialog    – simple yes/no dialog
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ── AppCard ───────────────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  const AppCard({super.key, required this.child, this.padding, this.borderColor});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor ?? cs.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: child,
    );
  }
}

// ── StatCard ──────────────────────────────────────────────────
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
    final cs = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(13)),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(badge, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: iconColor)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(value,
              style: AppTextStyles.displayStyle(ctx: context, size: 26)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.5))),
        ],
      ),
    );
  }
}

// ── SectionHeader ─────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  const SectionHeader({super.key, required this.title, this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.displayStyle(ctx: context, size: 28)),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.5))),
              ],
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

// ── CategoryChip ──────────────────────────────────────────────
class CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const CategoryChip({super.key, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentLight : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? primary : Theme.of(context).colorScheme.outline),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? primary : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            )),
      ),
    );
  }
}

// ── AppButton ─────────────────────────────────────────────────
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool outlined;
  final bool small;
  final Color? color;
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.outlined = false,
    this.small = false,
    this.color,
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          )
        : ElevatedButton.styleFrom(
            backgroundColor: c,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: pad,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          );

    final child = icon != null
        ? Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: small ? 16 : 18),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: small ? 12 : 14, fontWeight: FontWeight.w600)),
          ])
        : Text(label, style: TextStyle(fontSize: small ? 12 : 14, fontWeight: FontWeight.w600));

    return outlined
        ? OutlinedButton(onPressed: onPressed, style: style, child: child)
        : ElevatedButton(onPressed: onPressed, style: style, child: child);
  }
}

// ── StatusBadge ───────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  const StatusBadge({super.key, required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

// ── AppTextField ──────────────────────────────────────────────
class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int? maxLines;
  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    required this.controller,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}

// ── ConfirmDialog ─────────────────────────────────────────────
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  Color? confirmColor,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(title),
          content: Text(message),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(confirmLabel,
                  style: TextStyle(color: confirmColor ?? Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ) ??
      false;
}
