import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central design-token file for the DrawForFun Claymorphism theme.
/// All colour, typography, shadow, and radius constants live here.
/// Never hard-code these values in individual widgets.

// ── Colours ──────────────────────────────────────────────────────────────────

abstract class AppColors {
  // ── Magical Sky gradient triad ──────────────────────────────────────────
  static const gradientStart  = Color(0xFFAAFFD4); // mint
  static const gradientMid    = Color(0xFFC8F0FF); // ice-blue
  static const gradientEnd    = Color(0xFFFFD6F5); // candy-pink

  // ── Accent colours ──────────────────────────────────────────────────────
  static const accentPrimary   = Color(0xFF7C6FF7); // soft indigo-violet
  static const accentSecondary = Color(0xFFF472B6); // soft candy-pink
  static const accentMint      = Color(0xFF34D399); // mint actions
  static const accentPeach     = Color(0xFFFDBA74); // warm peach
  static const accentMintLight = Color(0xFFA5F3D0); // button gradient start

  // ── Surface (frosted glass) ──────────────────────────────────────────────
  // Use Color.fromRGBO for alpha — never CSS rgba strings in Dart
  static const surface = Color.fromRGBO(255, 255, 255, 0.72);

  // ── Text ────────────────────────────────────────────────────────────────
  static const textPrimary = Color(0xFF2D2640); // was 0xFF332F3A
  static const textMuted   = Color(0xFF7C7490); // was 0xFF635F69

  // ── Semantic ────────────────────────────────────────────────────────────
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const danger  = Color(0xFFEF4444);
}

// ── Radius ────────────────────────────────────────────────────────────────────

abstract class AppRadius {
  static const outer  = 50.0; // pill-shaped panels / modals
  static const card   = 32.0; // cards, menu tiles
  static const button = 20.0; // buttons, toolbar tiles
  static const small  = 12.0; // chips, small surfaces
}

// ── Shadows ───────────────────────────────────────────────────────────────────

abstract class AppShadows {
  /// 4-layer clay shadow. Use on interactive cards & primary CTA buttons.
  static List<BoxShadow> clay(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.35),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: color.withValues(alpha: 0.18),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
    // Inner gloss highlight — simulates clay elevation
    BoxShadow(
      color: Colors.white.withValues(alpha: 0.7),
      blurRadius: 4,
      offset: const Offset(-2, -2),
      spreadRadius: -1,
    ),
    // Candy-pink ambient glow (new)
    const BoxShadow(
      color: Color.fromRGBO(255, 182, 213, 0.18),
      blurRadius: 32,
      offset: Offset(0, 12),
    ),
  ];

  /// Soft lift — for passive containers.
  static List<BoxShadow> soft(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.15),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.white.withValues(alpha: 0.6),
      blurRadius: 3,
      offset: const Offset(-1, -1),
      spreadRadius: -1,
    ),
  ];

  /// Frosted-glass panel shadow. Use on DraggableScrollableSheet and floating buttons.
  static const List<BoxShadow> frosted = [
    BoxShadow(
      color: Color.fromRGBO(180, 200, 255, 0.20),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];
}

// ── Gradients ─────────────────────────────────────────────────────────────────

abstract class AppGradients {
  // Global app background — 3-stop mint → ice-blue → candy-pink
  static const magicalSky = LinearGradient(
    colors: [
      AppColors.gradientStart,
      AppColors.gradientMid,
      AppColors.gradientEnd,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Primary CTA buttons
  static const primaryButton = LinearGradient(
    colors: [AppColors.accentMintLight, AppColors.accentPrimary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // appBar gradient intentionally kept for now — removed in Phase 3
  static const appBar = LinearGradient(
    colors: [Color(0xFF9333EA), Color(0xFFDB2777)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

// ── Theme builder ─────────────────────────────────────────────────────────────

abstract class AppTheme {
  static ThemeData build() {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accentPrimary,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.transparent,
    );

    // Nunito for all body/UI copy; Fredoka for display and headline roles.
    final textTheme = GoogleFonts.nunitoTextTheme(base.textTheme).copyWith(
      displayLarge:   GoogleFonts.fredoka(fontSize: 40, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      displayMedium:  GoogleFonts.fredoka(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      displaySmall:   GoogleFonts.fredoka(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      headlineLarge:  GoogleFonts.fredoka(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      headlineMedium: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      headlineSmall:  GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        backgroundColor: Colors.white,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.accentPrimary,
        contentTextStyle: GoogleFonts.nunito(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // TODO Phase 3: remove this method and switch callers to floating buttons
  /// Returns a branded gradient [AppBar]. Use on every screen for consistency.
  static AppBar gradientAppBar({
    required String title,
    List<Widget>? actions,
    bool automaticallyImplyLeading = true,
  }) {
    return AppBar(
      automaticallyImplyLeading: automaticallyImplyLeading,
      title: Text(
        title,
        style: GoogleFonts.fredoka(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      actions: actions,
      flexibleSpace: Container(
        decoration: const BoxDecoration(gradient: AppGradients.appBar),
      ),
    );
  }
}
