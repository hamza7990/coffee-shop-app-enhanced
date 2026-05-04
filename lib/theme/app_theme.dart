// lib/theme/app_theme.dart
// ─────────────────────────────────────────────────────────────
// Brewhaus Design System v2
//
// Architecture:
//   AppColors     → Semantic color palette (light + dark)
//   AppSpacing    → Consistent spacing scale
//   AppRadius     → Border radius tokens
//   AppShadows    → Elevation shadow tokens
//   AppTextStyles → Typography system (Outfit + Inter)
//   AppTheme      → ThemeData factory (light + dark)
//
// Usage:
//   import '../theme/app_theme.dart';
//   final cs = Theme.of(context).colorScheme;
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ══════════════════════════════════════════════════════════════
// COLORS
// ══════════════════════════════════════════════════════════════
class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────────
  static const primary     = Color(0xFFD4942A); // Rich warm amber
  static const primaryLight= Color(0xFFF5E0BA); // Tinted surface
  static const primaryDark = Color(0xFF9D6C14); // Deep amber

  // ── Neutrals (Light Mode) ──────────────────────────────────
  static const bgLight      = Color(0xFFF6F7F9); // Cool off-white
  static const cardLight    = Color(0xFFFFFFFF);
  static const borderLight  = Color(0xFFE4E7EC);
  static const textLight    = Color(0xFF1A1D26);
  static const mutedLight   = Color(0xFF6B7280);
  static const sidebarLight = Color(0xFFFFFFFF);

  // ── Neutrals (Dark Mode) ───────────────────────────────────
  static const bgDark       = Color(0xFF0E0F13); // Deep dark
  static const cardDark     = Color(0xFF181A20); // Elevated surface
  static const borderDark   = Color(0xFF2A2D36);
  static const textDark     = Color(0xFFF5F5F7);
  static const mutedDark    = Color(0xFF9CA3AF);
  static const sidebarDark  = Color(0xFF141519);

  // ── Semantic ───────────────────────────────────────────────
  static const success        = Color(0xFF22C55E);
  static const successLight   = Color(0xFFDCFCE7);
  static const successDarkBg  = Color(0xFF0F2918);

  static const warning        = Color(0xFFF59E0B);
  static const warningLight   = Color(0xFFFEF3C7);
  static const warningDarkBg  = Color(0xFF2D1F04);

  static const error          = Color(0xFFEF4444);
  static const errorLight     = Color(0xFFFEE2E2);
  static const errorDarkBg    = Color(0xFF2D0F0F);

  static const info           = Color(0xFF3B82F6);
  static const infoLight      = Color(0xFFDBEAFE);
  static const infoDark       = Color(0xFF3B82F6);
  static const infoDarkBg     = Color(0xFF0F1A2D);

  // ── Accent (backward compat) ───────────────────────────────
  static const accentLight    = Color(0xFFF5E0BA);
  static const accentGold     = Color(0xFFD4942A);

  // ── Chart palettes ─────────────────────────────────────────
  static const chartDark  = [Color(0xFFD4942A), Color(0xFF9D6C14), Color(0xFF7A5210), Color(0xFF5C3C08), Color(0xFF3D2804)];
  static const chartLight = [Color(0xFFD4942A), Color(0xFFF5E0BA), Color(0xFFFAEDD4), Color(0xFFFDF4E8), Color(0xFFFEF9F2)];
}

// ══════════════════════════════════════════════════════════════
// SPACING
// ══════════════════════════════════════════════════════════════
class AppSpacing {
  AppSpacing._();
  static const double xs   = 4;
  static const double sm   = 8;
  static const double md   = 12;
  static const double base = 16;
  static const double lg   = 20;
  static const double xl   = 24;
  static const double xxl  = 32;
  static const double xxxl = 48;

  // Quick SizedBox helpers
  static const SizedBox h4  = SizedBox(height: 4);
  static const SizedBox h8  = SizedBox(height: 8);
  static const SizedBox h12 = SizedBox(height: 12);
  static const SizedBox h16 = SizedBox(height: 16);
  static const SizedBox h20 = SizedBox(height: 20);
  static const SizedBox h24 = SizedBox(height: 24);
  static const SizedBox h32 = SizedBox(height: 32);
  static const SizedBox h48 = SizedBox(height: 48);

  static const SizedBox w4  = SizedBox(width: 4);
  static const SizedBox w8  = SizedBox(width: 8);
  static const SizedBox w12 = SizedBox(width: 12);
  static const SizedBox w16 = SizedBox(width: 16);
}

// ══════════════════════════════════════════════════════════════
// RADIUS
// ══════════════════════════════════════════════════════════════
class AppRadius {
  AppRadius._();
  static const double sm  = 8;
  static const double md  = 12;
  static const double lg  = 16;
  static const double xl  = 20;
  static const double xxl = 28;
  static const double pill = 100;

  static BorderRadius get smAll  => BorderRadius.circular(sm);
  static BorderRadius get mdAll  => BorderRadius.circular(md);
  static BorderRadius get lgAll  => BorderRadius.circular(lg);
  static BorderRadius get xlAll  => BorderRadius.circular(xl);
  static BorderRadius get xxlAll => BorderRadius.circular(xxl);
}

// ══════════════════════════════════════════════════════════════
// SHADOWS
// ══════════════════════════════════════════════════════════════
class AppShadows {
  AppShadows._();

  static List<BoxShadow> get sm => [
    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 1)),
  ];

  static List<BoxShadow> get md => [
    BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
  ];

  static List<BoxShadow> get lg => [
    BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 8)),
  ];

  static List<BoxShadow> get glow => [
    BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 6)),
  ];

  // Dark mode variants (stronger)
  static List<BoxShadow> get darkSm => [
    BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 1)),
  ];
  static List<BoxShadow> get darkMd => [
    BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 4)),
  ];
}

// ══════════════════════════════════════════════════════════════
// TYPOGRAPHY
// ══════════════════════════════════════════════════════════════
class AppTextStyles {
  AppTextStyles._();

  // ── Display / Hero headings (Outfit) ───────────────────────
  static TextStyle displayStyle({
    required BuildContext ctx,
    double size = 28,
    FontWeight weight = FontWeight.w700,
    Color? color,
  }) => GoogleFonts.outfit(
    fontSize: size,
    fontWeight: weight,
    color: color ?? Theme.of(ctx).colorScheme.onSurface,
    letterSpacing: -0.5,
    height: 1.2,
  );

  // ── Section title (Inter) ──────────────────────────────────
  static TextStyle title(BuildContext ctx, {double size = 18, FontWeight weight = FontWeight.w600, Color? color}) =>
    GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color ?? Theme.of(ctx).colorScheme.onSurface,
      height: 1.3,
    );

  // ── Body text (Inter) ──────────────────────────────────────
  static TextStyle body(BuildContext ctx, {double size = 14, FontWeight weight = FontWeight.normal, Color? color}) =>
    GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color ?? Theme.of(ctx).colorScheme.onSurface,
      height: 1.5,
    );

  // ── Muted / secondary text ─────────────────────────────────
  static TextStyle muted(BuildContext ctx, {double size = 13, Color? color}) =>
    GoogleFonts.inter(
      fontSize: size,
      color: color ?? Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.55),
      height: 1.4,
    );

  // ── Label / overline (uppercase section labels) ────────────
  static TextStyle label(BuildContext ctx, {Color? color}) => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    color: color ?? Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.45),
  );

  // ── Caption / micro text ───────────────────────────────────
  static TextStyle caption(BuildContext ctx, {Color? color}) => GoogleFonts.inter(
    fontSize: 12,
    color: color ?? Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.5),
  );

  // ── Mono (code, prices) ────────────────────────────────────
  static TextStyle mono(BuildContext ctx, {double size = 14, FontWeight weight = FontWeight.w600, Color? color}) =>
    GoogleFonts.jetBrainsMono(
      fontSize: size,
      fontWeight: weight,
      color: color ?? Theme.of(ctx).colorScheme.onSurface,
    );
}

// ══════════════════════════════════════════════════════════════
// THEME DATA
// ══════════════════════════════════════════════════════════════
class AppTheme {
  AppTheme._();

  // ── Light ──────────────────────────────────────────────────
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.bgLight,
    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
    colorScheme: const ColorScheme.light(
      primary:       AppColors.primary,
      primaryContainer: AppColors.primaryLight,
      secondary:     AppColors.primaryDark,
      surface:       AppColors.cardLight,
      onSurface:     AppColors.textLight,
      outline:       AppColors.borderLight,
      error:         AppColors.error,
      onPrimary:     Colors.white,
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardLight,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      margin: EdgeInsets.zero,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.bgLight,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textLight),
      iconTheme: const IconThemeData(color: AppColors.textLight, size: 22),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.cardLight,
      elevation: 0,
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
      backgroundColor: AppColors.cardLight,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
    ),
    inputDecorationTheme: _inputTheme(
      border: AppColors.borderLight,
      fill: AppColors.cardLight,
      text: AppColors.textLight,
    ),
    elevatedButtonTheme: _btnTheme(),
    outlinedButtonTheme: _outlinedBtnTheme(),
    textButtonTheme: _textBtnTheme(),
    dividerColor: AppColors.borderLight,
    dividerTheme: const DividerThemeData(color: AppColors.borderLight, thickness: 1),
  );

  // ── Dark ───────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bgDark,
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    colorScheme: const ColorScheme.dark(
      primary:       AppColors.primary,
      primaryContainer: AppColors.primaryDark,
      secondary:     AppColors.primaryLight,
      surface:       AppColors.cardDark,
      onSurface:     AppColors.textDark,
      outline:       AppColors.borderDark,
      error:         AppColors.error,
      onPrimary:     Colors.white,
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardDark,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: const BorderSide(color: AppColors.borderDark),
      ),
      margin: EdgeInsets.zero,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.bgDark,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textDark),
      iconTheme: const IconThemeData(color: AppColors.textDark, size: 22),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.cardDark,
      elevation: 0,
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
      backgroundColor: AppColors.cardDark,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
    ),
    inputDecorationTheme: _inputTheme(
      border: AppColors.borderDark,
      fill: AppColors.bgDark,
      text: AppColors.textDark,
    ),
    elevatedButtonTheme: _btnTheme(),
    outlinedButtonTheme: _outlinedBtnTheme(),
    textButtonTheme: _textBtnTheme(),
    dividerColor: AppColors.borderDark,
    dividerTheme: const DividerThemeData(color: AppColors.borderDark, thickness: 1),
  );

  // ── Shared Component Themes ────────────────────────────────
  static InputDecorationTheme _inputTheme({
    required Color border,
    required Color fill,
    required Color text,
  }) => InputDecorationTheme(
    filled: true,
    fillColor: fill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(color: AppColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(color: AppColors.error, width: 1.5),
    ),
    hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14),
  );

  static ElevatedButtonThemeData _btnTheme() => ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
    ),
  );

  static OutlinedButtonThemeData _outlinedBtnTheme() => OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      side: const BorderSide(color: AppColors.borderLight),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
    ),
  );

  static TextButtonThemeData _textBtnTheme() => TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
    ),
  );
}
