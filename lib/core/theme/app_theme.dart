import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Meet Marketers AI Design System — Premium Edition
/// Dark forest greens + electric accents + glassmorphism
abstract class ClinicSageColors {
  // Core Palette
  static const Color primary = Color(0xFF0F2419);      // Deep forest — headlines, core text
  static const Color secondary = Color(0xFF6B8078);    // Muted sage — borders, captions
  static const Color tertiary = Color(0xFF3D9970);     // Electric sage — sole interaction driver
  static const Color tertiaryVibrant = Color(0xFF2ECC71); // Vibrant emerald — highlights
  static const Color neutral = Color(0xFFF2F5F2);      // Page foundation background
  static const Color surface = Color(0xFFFFFFFF);      // Cards and component surfaces
  static const Color onPrimary = Color(0xFFFFFFFF);    // Text on primary elements

  // Extended Palette
  static const Color tertiaryLight = Color(0xFFE2F5EC); // Light tertiary tint
  static const Color tertiaryMid = Color(0xFFB0DECA);   // Mid tertiary tint
  static const Color border = Color(0xFFE2EAE3);         // Structural borders
  static const Color borderLight = Color(0xFFEDF3EE);    // Subtle borders
  static const Color surfaceVariant = Color(0xFFF7FAF7); // Subtle surface variant
  static const Color onSurface = Color(0xFF0F2419);      // Text on surface
  static const Color onSecondary = Color(0xFFFFFFFF);    // Text on secondary

  // Accent Colors
  static const Color accentBlue = Color(0xFF3B82F6);    // Action blue
  static const Color accentPurple = Color(0xFF8B5CF6);  // AI purple
  static const Color accentAmber = Color(0xFFF59E0B);   // Amber warning

  // Status Colors (premium style)
  static const Color statusDraft = Color(0xFF6B8078);
  static const Color statusVetted = Color(0xFF3D9970);
  static const Color statusApproved = Color(0xFF0F2419);
  static const Color statusInReview = Color(0xFF7C6F4E);
  static const Color statusDraftBg = Color(0xFFF0F4F1);
  static const Color statusVettedBg = Color(0xFFE2F5EC);
  static const Color statusInReviewBg = Color(0xFFF5F1E8);
  static const Color statusApprovedBg = Color(0xFFD2EAD8);

  // SWOT Quadrant Colors — richer
  static const Color swotStrengths = Color(0xFFE2F5EC);
  static const Color swotWeaknesses = Color(0xFFF5F0E8);
  static const Color swotOpportunities = Color(0xFFE8F0F5);
  static const Color swotThreats = Color(0xFFF5E8EF);

  static const Color swotStrengthsAccent = Color(0xFF3D9970);
  static const Color swotWeaknessesAccent = Color(0xFF9B7A4E);
  static const Color swotOpportunitiesAccent = Color(0xFF4E82A8);
  static const Color swotThreatsAccent = Color(0xFFA84E7A);
}

abstract class ClinicSageGradients {
  static const LinearGradient brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F2419), Color(0xFF1B4A32)],
  );

  static const LinearGradient brandVibrant = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F2419), Color(0xFF1A6B4A)],
  );

  static const LinearGradient tertiary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3D9970), Color(0xFF2ECC71)],
  );

  static const LinearGradient tertiarySubtle = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE2F5EC), Color(0xFFD0EFE3)],
  );

  static const LinearGradient aiGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3D9970), Color(0xFF8B5CF6)],
  );

  static const LinearGradient surface = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFF7FAF7)],
  );

  static const LinearGradient neutral = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF2F5F2), Color(0xFFEBF0EB)],
  );

  static const LinearGradient swotStrengths = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE2F5EC), Color(0xFFD5F0E5)],
  );

  static const LinearGradient swotWeaknesses = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF5F0E8), Color(0xFFF0EAE0)],
  );

  static const LinearGradient swotOpportunities = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8F0F5), Color(0xFFE0EAEF)],
  );

  static const LinearGradient swotThreats = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF5E8EF), Color(0xFFF0DFE9)],
  );
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
  static const double xs = 4.0;
  static const double sm = 6.0;
  static const double md = 10.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double full = 999.0;
}

abstract class ClinicSageShadows {
  static List<BoxShadow> get card => [
    BoxShadow(
      color: ClinicSageColors.primary.withOpacity(0.04),
      blurRadius: 12,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: ClinicSageColors.primary.withOpacity(0.02),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get cardHover => [
    BoxShadow(
      color: ClinicSageColors.tertiary.withOpacity(0.10),
      blurRadius: 24,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: ClinicSageColors.primary.withOpacity(0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get modal => [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 40,
      offset: const Offset(0, 16),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get button => [
    BoxShadow(
      color: ClinicSageColors.tertiary.withOpacity(0.30),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get aiGlow => [
    BoxShadow(
      color: ClinicSageColors.tertiary.withOpacity(0.25),
      blurRadius: 20,
      offset: const Offset(0, 4),
      spreadRadius: -2,
    ),
  ];
}

abstract class AppTheme {
  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);

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
          fontWeight: FontWeight.w600,
          letterSpacing: -0.02 * 32,
          color: ClinicSageColors.primary,
        ),
        headlineMedium: GoogleFonts.dmSans(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.01 * 24,
          color: ClinicSageColors.primary,
        ),
        headlineSmall: GoogleFonts.dmSans(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: ClinicSageColors.primary,
        ),
        // Body
        titleLarge: GoogleFonts.dmSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: ClinicSageColors.primary,
        ),
        titleMedium: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: ClinicSageColors.primary,
        ),
        titleSmall: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
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
          fontWeight: FontWeight.w600,
          letterSpacing: 0.06 * 13,
          color: ClinicSageColors.primary,
        ),
        labelMedium: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.04 * 12,
          color: ClinicSageColors.secondary,
        ),
        labelSmall: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.06 * 11,
          color: ClinicSageColors.secondary,
        ),
      ),

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

      // ElevatedButton — tertiary green, premium
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
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // OutlinedButton
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ClinicSageColors.primary,
          side: const BorderSide(color: ClinicSageColors.border, width: 1.5),
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
          borderSide: const BorderSide(color: ClinicSageColors.tertiary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ClinicSageRadius.md),
          borderSide: const BorderSide(color: Color(0xFF7A4E4E)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ClinicSageRadius.md),
          borderSide: const BorderSide(color: Color(0xFF7A4E4E), width: 2),
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
          fontWeight: FontWeight.w600,
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
          fontWeight: FontWeight.w600,
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
          boxShadow: ClinicSageShadows.modal,
        ),
        textStyle: GoogleFonts.dmSans(
          fontSize: 12,
          color: Colors.white,
        ),
      ),

      // ScrollBar
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(ClinicSageColors.secondary.withOpacity(0.35)),
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

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: ClinicSageColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ClinicSageRadius.xl),
          side: const BorderSide(color: ClinicSageColors.border),
        ),
        shadowColor: Colors.black.withOpacity(0.15),
      ),
    );
  }
}

/// Decoration helpers matching Meet Marketers AI spec
abstract class ClinicSageDecorations {
  static BoxDecoration get card => BoxDecoration(
    color: ClinicSageColors.surface,
    borderRadius: BorderRadius.circular(ClinicSageRadius.lg),
    border: Border.all(color: ClinicSageColors.border),
    boxShadow: ClinicSageShadows.card,
  );

  static BoxDecoration get cardElevated => BoxDecoration(
    color: ClinicSageColors.surface,
    borderRadius: BorderRadius.circular(ClinicSageRadius.lg),
    border: Border.all(color: ClinicSageColors.border),
    boxShadow: ClinicSageShadows.cardHover,
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
    ),
  );

  static BoxDecoration get glassmorphism => BoxDecoration(
    color: Colors.white.withOpacity(0.1),
    borderRadius: BorderRadius.circular(ClinicSageRadius.lg),
    border: Border.all(color: Colors.white.withOpacity(0.2)),
  );

  static BoxDecoration get gradientCard => BoxDecoration(
    gradient: ClinicSageGradients.brandVibrant,
    borderRadius: BorderRadius.circular(ClinicSageRadius.lg),
    boxShadow: ClinicSageShadows.cardHover,
  );

  static BoxDecoration aiPanel(Color accentColor) => BoxDecoration(
    color: ClinicSageColors.surface,
    borderRadius: BorderRadius.circular(ClinicSageRadius.lg),
    border: Border.all(color: ClinicSageColors.border),
    boxShadow: [
      BoxShadow(
        color: accentColor.withOpacity(0.08),
        blurRadius: 20,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

/// Reusable gradient icon container
class GradientIconBadge extends StatelessWidget {
  final IconData icon;
  final double size;
  final double iconSize;
  final LinearGradient? gradient;
  final Color? color;
  final double radius;

  const GradientIconBadge({
    super.key,
    required this.icon,
    this.size = 40,
    this.iconSize = 18,
    this.gradient,
    this.color,
    this.radius = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient ?? ClinicSageGradients.tertiary,
        color: gradient == null ? color : null,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: ClinicSageShadows.aiGlow,
      ),
      child: Icon(icon, size: iconSize, color: Colors.white),
    );
  }
}
