import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Clinic Sage Design System — version alpha
/// Clinical calm. Sage greens, paper white, zero alarm.
abstract class ClinicSageColors {
  // Core Palette
  static const Color primary = Color(0xFF1B3A2E);     // Headlines, core text
  static const Color secondary = Color(0xFF7A8F85);   // Borders, captions, metadata
  static const Color tertiary = Color(0xFF4E8B6A);    // Sole interaction driver
  static const Color neutral = Color(0xFFF4F7F4);     // Page foundation background
  static const Color surface = Color(0xFFFFFFFF);     // Cards and component surfaces
  static const Color onPrimary = Color(0xFFFFFFFF);   // Text on primary elements

  // Extended Palette
  static const Color tertiaryLight = Color(0xFFE8F3ED); // Light tertiary tint
  static const Color tertiaryMid = Color(0xFFB8D9C8);   // Mid tertiary tint
  static const Color border = Color(0xFFE5EDE5);         // Structural borders
  static const Color surfaceVariant = Color(0xFFF8FAF8); // Subtle surface variant
  static const Color onSurface = Color(0xFF1B3A2E);      // Text on surface
  static const Color onSecondary = Color(0xFFFFFFFF);    // Text on secondary

  // Status Colors (kept calm — no alarm reds)
  static const Color statusDraft = Color(0xFF7A8F85);
  static const Color statusVetted = Color(0xFF4E8B6A);
  static const Color statusApproved = Color(0xFF1B3A2E);
  static const Color statusDraftBg = Color(0xFFF0F4F1);
  static const Color statusVettedBg = Color(0xFFE8F3ED);
  static const Color statusApprovedBg = Color(0xFFD4E9DC);

  // SWOT Quadrant Colors
  static const Color swotStrengths = Color(0xFFE8F3ED);
  static const Color swotWeaknesses = Color(0xFFF5F0EC);
  static const Color swotOpportunities = Color(0xFFECF3F5);
  static const Color swotThreats = Color(0xFFF5ECF0);

  static const Color swotStrengthsAccent = Color(0xFF4E8B6A);
  static const Color swotWeaknessesAccent = Color(0xFF8B6A4E);
  static const Color swotOpportunitiesAccent = Color(0xFF4E758B);
  static const Color swotThreatsAccent = Color(0xFF8B4E6A);
}

abstract class ClinicSageSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 32.0;
  static const double xl = 48.0;
  static const double xxl = 64.0;
}

abstract class ClinicSageRadius {
  static const double sm = 6.0;
  static const double md = 10.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
}

abstract class AppTheme {
  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    final dmSans = GoogleFonts.dmSansTextTheme();

    return base.copyWith(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: ClinicSageColors.primary,
        onPrimary: ClinicSageColors.onPrimary,
        secondary: ClinicSageColors.secondary,
        onSecondary: ClinicSageColors.onSecondary,
        tertiary: ClinicSageColors.tertiary,
        onTertiary: ClinicSageColors.onPrimary,
        surface: ClinicSageColors.surface,
        onSurface: ClinicSageColors.onSurface,
        surfaceContainerHighest: ClinicSageColors.neutral,
        outline: ClinicSageColors.border,
        outlineVariant: ClinicSageColors.secondary,
        error: Color(0xFF7A4E4E),
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: ClinicSageColors.neutral,

      // Typography — DM Sans hierarchy
      textTheme: TextTheme(
        // Display
        displayLarge: GoogleFonts.dmSans(
          fontSize: 56,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.02 * 56,
          color: ClinicSageColors.primary,
        ),
        // h1
        headlineLarge: GoogleFonts.dmSans(
          fontSize: 32,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.02 * 32,
          color: ClinicSageColors.primary,
        ),
        headlineMedium: GoogleFonts.dmSans(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.01 * 24,
          color: ClinicSageColors.primary,
        ),
        headlineSmall: GoogleFonts.dmSans(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: ClinicSageColors.primary,
        ),
        // Body
        titleLarge: GoogleFonts.dmSans(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: ClinicSageColors.primary,
        ),
        titleMedium: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: ClinicSageColors.primary,
        ),
        titleSmall: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: ClinicSageColors.primary,
        ),
        bodyLarge: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.65,
          color: ClinicSageColors.primary,
        ),
        bodyMedium: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.65,
          color: ClinicSageColors.primary,
        ),
        bodySmall: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          height: 1.65,
          color: ClinicSageColors.secondary,
        ),
        // Label (small caps)
        labelLarge: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.06 * 13,
          color: ClinicSageColors.primary,
        ),
        labelMedium: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.06 * 12,
          color: ClinicSageColors.secondary,
        ),
        labelSmall: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.06 * 11,
          color: ClinicSageColors.secondary,
        ),
      ).merge(dmSans),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: ClinicSageColors.surface,
        foregroundColor: ClinicSageColors.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: ClinicSageColors.primary,
        ),
        toolbarHeight: 64,
      ),

      // Card — flat, white, 16px radius
      cardTheme: CardThemeData(
        color: ClinicSageColors.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClinicSageRadius.lg),
          side: const BorderSide(color: ClinicSageColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // ElevatedButton — tertiary green, 10px radius
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ClinicSageColors.tertiary,
          foregroundColor: ClinicSageColors.onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ClinicSageRadius.md),
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // OutlinedButton
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ClinicSageColors.primary,
          side: const BorderSide(color: ClinicSageColors.border, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ClinicSageRadius.md),
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ClinicSageColors.tertiary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ClinicSageColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ClinicSageRadius.md),
          borderSide: const BorderSide(color: ClinicSageColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ClinicSageRadius.md),
          borderSide: const BorderSide(color: ClinicSageColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ClinicSageRadius.md),
          borderSide: const BorderSide(color: ClinicSageColors.tertiary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ClinicSageRadius.md),
          borderSide: const BorderSide(color: Color(0xFF7A4E4E)),
        ),
        hintStyle: GoogleFonts.dmSans(
          fontSize: 14,
          color: ClinicSageColors.secondary,
        ),
        labelStyle: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: ClinicSageColors.secondary,
        ),
        floatingLabelStyle: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: ClinicSageColors.tertiary,
        ),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: ClinicSageColors.surfaceVariant,
        labelStyle: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: ClinicSageColors.primary,
        ),
        side: const BorderSide(color: ClinicSageColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClinicSageRadius.sm),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: ClinicSageColors.border,
        thickness: 1,
        space: 0,
      ),

      // NavigationRail
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: ClinicSageColors.surface,
        selectedIconTheme: const IconThemeData(color: ClinicSageColors.tertiary),
        unselectedIconTheme: const IconThemeData(color: ClinicSageColors.secondary),
        selectedLabelTextStyle: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: ClinicSageColors.tertiary,
        ),
        unselectedLabelTextStyle: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: ClinicSageColors.secondary,
        ),
        indicatorColor: ClinicSageColors.tertiaryLight,
        elevation: 0,
      ),

      // Tab Bar
      tabBarTheme: TabBarThemeData(
        labelColor: ClinicSageColors.tertiary,
        unselectedLabelColor: ClinicSageColors.secondary,
        indicatorColor: ClinicSageColors.tertiary,
        labelStyle: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.02,
        ),
        unselectedLabelStyle: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: ClinicSageColors.border,
      ),

      // Tooltip
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: ClinicSageColors.primary,
          borderRadius: BorderRadius.circular(ClinicSageRadius.sm),
        ),
        textStyle: GoogleFonts.dmSans(
          fontSize: 12,
          color: Colors.white,
        ),
      ),

      // ScrollBar
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(ClinicSageColors.secondary.withOpacity(0.4)),
        trackColor: WidgetStateProperty.all(Colors.transparent),
        radius: const Radius.circular(4),
        thickness: WidgetStateProperty.all(4),
      ),

      // Snack Bar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ClinicSageColors.primary,
        contentTextStyle: GoogleFonts.dmSans(
          fontSize: 14,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClinicSageRadius.md),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Decoration helpers matching Clinic Sage spec
abstract class ClinicSageDecorations {
  static BoxDecoration get card => BoxDecoration(
    color: ClinicSageColors.surface,
    borderRadius: BorderRadius.circular(ClinicSageRadius.lg),
    border: Border.all(color: ClinicSageColors.border),
  );

  static BoxDecoration get cardElevated => BoxDecoration(
    color: ClinicSageColors.surface,
    borderRadius: BorderRadius.circular(ClinicSageRadius.lg),
    border: Border.all(color: ClinicSageColors.border),
    boxShadow: [
      BoxShadow(
        color: ClinicSageColors.primary.withOpacity(0.04),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration get sidebar => const BoxDecoration(
    color: ClinicSageColors.surface,
    border: Border(
      right: BorderSide(color: ClinicSageColors.border),
    ),
  );

  static BoxDecoration get inputArea => BoxDecoration(
    color: ClinicSageColors.surface,
    borderRadius: BorderRadius.circular(ClinicSageRadius.md),
    border: Border.all(color: ClinicSageColors.border),
  );

  static BoxDecoration get dropZone => BoxDecoration(
    color: ClinicSageColors.tertiaryLight,
    borderRadius: BorderRadius.circular(ClinicSageRadius.lg),
    border: Border.all(
      color: ClinicSageColors.tertiary,
      width: 1.5,
      style: BorderStyle.none,
    ),
  );
}
