import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // ── Brand ──────────────────────────────────────────────────
  static const primary = Color(0xFFE5A93C);       // Warm Gold
  static const primaryLight = Color(0xFFF9E7C8);
  static const primaryDark = Color(0xFFB57A18);

  // ── Neutrals (Light Mode) ──────────────────────────────────
  static const bgLight = Color(0xFFF8F9FA); // Very clean off-white
  static const cardLight = Color(0xFFFFFFFF);
  static const borderLight = Color(0xFFE9ECEF);
  static const textLight = Color(0xFF212529);
  static const mutedLight = Color(0xFF868E96);
  static const sidebarLight = Color(0xFFF1F3F5);

  // ── Neutrals (Dark Mode) ───────────────────────────────────
  static const bgDark = Color(0xFF0C0A09);   // Deep obsidian/coffee black
  static const cardDark = Color(0xFF141210); // Slightly lighter for cards
  static const borderDark = Color(0xFF292524);
  static const textDark = Color(0xFFFAFAF9);
  static const mutedDark = Color(0xFFA8A29E);
  static const sidebarDark = Color(0xFF131110);

  // ── Semantic ───────────────────────────────────────────────
  static const success = Color(0xFF28A745);
  static const successLight = Color(0xFFD4EDDA);
  static const successDarkBg = Color(0xFF142B1A);
  
  static const warning = Color(0xFFFFC107);
  static const warningLight = Color(0xFFFFF3CD);
  static const warningDarkBg = Color(0xFF332701);
  
  static const error = Color(0xFFDC3545);
  
  static const info = Color(0xFF17A2B8);
  static const infoLight = Color(0xFFD1ECF1);
  static const infoDark = Color(0xFF17A2B8);
  static const infoDarkBg = Color(0xFF0C2B31);

  static const accentLight = Color(0xFFF9E7C8);
  static const accentGold = Color(0xFFE5A93C);

  static const chartDark = [Color(0xFFE5A93C), Color(0xFFB57A18), Color(0xFF8C5D0E), Color(0xFF6B4508), Color(0xFF4A2D04)];
  static const chartLight = [Color(0xFFE5A93C), Color(0xFFF9E7C8), Color(0xFFFDEFD9), Color(0xFFFEF5E6), Color(0xFFFFF9F2)];
}

class AppTextStyles {
  static TextStyle displayStyle({
    required BuildContext ctx,
    double size = 28,
    FontWeight weight = FontWeight.w700,
    Color? color,
  }) =>
      GoogleFonts.outfit(
        fontSize: size,
        fontWeight: weight,
        color: color ?? Theme.of(ctx).colorScheme.onSurface,
        letterSpacing: -0.5,
      );

  static TextStyle title(BuildContext ctx, {double size = 18}) => GoogleFonts.inter(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: Theme.of(ctx).colorScheme.onSurface,
      );

  static TextStyle body(BuildContext ctx, {double size = 14, FontWeight weight = FontWeight.normal}) => GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: Theme.of(ctx).colorScheme.onSurface,
      );

  static TextStyle muted(BuildContext ctx, {double size = 13}) => GoogleFonts.inter(
        fontSize: size,
        color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.55),
      );

  static TextStyle label(BuildContext ctx) => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.5),
      );
}

class AppTheme {
  // ── Light ──────────────────────────────────────────────────
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.bgLight,
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.primaryDark,
          surface: AppColors.cardLight,
          onSurface: AppColors.textLight,
          outline: AppColors.borderLight,
          error: AppColors.error,
        ),
        cardTheme: CardThemeData(
          color: AppColors.cardLight,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.04),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.borderLight),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: _inputTheme(AppColors.borderLight, AppColors.cardLight, AppColors.textLight),
        elevatedButtonTheme: _btnTheme(),
        dividerColor: AppColors.borderLight,
      );

  // ── Dark ───────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bgDark,
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.primaryLight,
          surface: AppColors.cardDark,
          onSurface: AppColors.textDark,
          outline: AppColors.borderDark,
          error: AppColors.error,
        ),
        cardTheme: CardThemeData(
          color: AppColors.cardDark,
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.borderDark),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: _inputTheme(AppColors.borderDark, AppColors.bgDark, AppColors.textDark),
        elevatedButtonTheme: _btnTheme(),
        dividerColor: AppColors.borderDark,
      );

  static InputDecorationTheme _inputTheme(Color border, Color fill, Color text) =>
      InputDecorationTheme(
        filled: true,
        fillColor: fill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      );

  static ElevatedButtonThemeData _btnTheme() => ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: AppColors.primary.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      );
}
