import 'package:flutter/material.dart';

/// Brand + status colors are constant across themes; only the neutral
/// surfaces / text / borders flip between light and dark.
class AppColors {
  // Brand
  static const guruPrimary    = Color(0xFF1769E0);
  static const trainerPrimary = Color(0xFFE50914);

  // Status (same in both themes — high contrast against either bg)
  static const success = Color(0xFF12B76A);
  static const warning = Color(0xFFF79009);
  static const error   = Color(0xFFD92D20);

  // ── Light neutrals
  static const bgLight       = Color(0xFFFFFFFF);
  static const bgSurface     = Color(0xFFF9FAFB);
  static const textPrimary   = Color(0xFF101828);
  static const textSecondary = Color(0xFF667085);
  static const borderLight   = Color(0xFFE4E7EC);

  // ── Dark neutrals
  static const bgDark            = Color(0xFF0B0F1A);
  static const bgSurfaceDark     = Color(0xFF111827);
  static const textPrimaryDark   = Color(0xFFF9FAFB);
  static const textSecondaryDark = Color(0xFF9CA3AF);
  static const borderDark        = Color(0xFF1F2937);
}

class AppTypography {
  static const h1        = TextStyle(fontSize: 24, fontWeight: FontWeight.w600);
  static const h2        = TextStyle(fontSize: 20, fontWeight: FontWeight.w600);
  static const body      = TextStyle(fontSize: 16, fontWeight: FontWeight.w400);
  static const bodySmall = TextStyle(fontSize: 14, fontWeight: FontWeight.w400);
  static const label     = TextStyle(fontSize: 12, fontWeight: FontWeight.w500);
}

class AppSpacing {
  static const double xs = 4, sm = 8, md = 16, lg = 24, xl = 32, xxl = 48;
}

/// Builds light + dark [ThemeData] for a given brand seed colour.
/// Pass `AppColors.guruPrimary` from guru_app and `AppColors.trainerPrimary`
/// from trainer_app, then wire into `MaterialApp(theme:, darkTheme:, themeMode: ThemeMode.system)`.
class AppTheme {
  static ThemeData light(Color seed) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
      error: AppColors.error,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bgLight,
      cardColor: AppColors.bgSurface,
      dividerColor: AppColors.borderLight,
      textTheme: const TextTheme(
        headlineLarge: AppTypography.h1,
        headlineMedium: AppTypography.h2,
        bodyLarge: AppTypography.body,
        bodyMedium: AppTypography.bodySmall,
        labelSmall: AppTypography.label,
      ).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      chipTheme: _chipTheme(scheme, AppColors.textPrimary, AppColors.borderLight),
    );
  }

  static ThemeData dark(Color seed) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
      error: AppColors.error,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bgDark,
      cardColor: AppColors.bgSurfaceDark,
      dividerColor: AppColors.borderDark,
      textTheme: const TextTheme(
        headlineLarge: AppTypography.h1,
        headlineMedium: AppTypography.h2,
        bodyLarge: AppTypography.body,
        bodyMedium: AppTypography.bodySmall,
        labelSmall: AppTypography.label,
      ).apply(
        bodyColor: AppColors.textPrimaryDark,
        displayColor: AppColors.textPrimaryDark,
      ),
      chipTheme: _chipTheme(scheme, AppColors.textPrimaryDark, AppColors.borderDark),
    );
  }

  /// Single source of truth for chip styling so ChoiceChips render
  /// identically across both themes and modes. Selected = filled primary
  /// with `onPrimary` text; unselected = transparent + outlined.
  static ChipThemeData _chipTheme(ColorScheme scheme, Color restingText, Color restingBorder) {
    return ChipThemeData(
      backgroundColor: Colors.transparent,
      selectedColor: scheme.primary,
      disabledColor: restingBorder.withValues(alpha: 0.4),
      showCheckmark: false,
      side: BorderSide(color: restingBorder, width: 1),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: 2,
      ),
      // Label colors must be resolved per-state — Material picks
      // `secondaryLabelStyle` for the selected variant. Selected text
      // uses onPrimary (white in both themes against the brand seed),
      // unselected uses the resting text colour for the active theme.
      labelStyle: AppTypography.label.copyWith(color: restingText),
      secondaryLabelStyle: AppTypography.label.copyWith(color: scheme.onPrimary),
    );
  }
}
