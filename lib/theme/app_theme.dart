import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Themes clair et sombre de l'application.
class AppTheme {
  AppTheme._();

  static ThemeData get light => themeFor(false);
  static ThemeData get dark => themeFor(true);

  /// Construit le theme pour le mode demande. Synchronise aussi les neutres
  /// de [AppColors] (utilises directement par certains widgets).
  static ThemeData themeFor(bool dark) {
    AppColors.setDark(dark);
    final base = ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
    );

    final textTheme = base.textTheme
        .apply(
          fontFamily: AppTypography.family,
          fontFamilyFallback: AppTypography.fallback,
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        )
        .copyWith(
          titleLarge: AppTypography.title.copyWith(color: AppColors.textPrimary),
          titleMedium:
              AppTypography.subtitle.copyWith(color: AppColors.textPrimary),
          bodyMedium: AppTypography.body.copyWith(color: AppColors.textPrimary),
          bodySmall:
              AppTypography.caption.copyWith(color: AppColors.textSecondary),
        );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: dark ? Brightness.dark : Brightness.light,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
      ),
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle:
            AppTypography.subtitle.copyWith(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 2,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogThemeData(backgroundColor: AppColors.surface),
      bottomSheetTheme:
          BottomSheetThemeData(backgroundColor: AppColors.surface),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.background,
        labelStyle: AppTypography.tag.copyWith(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: SmoothPageTransitionsBuilder(),
          TargetPlatform.iOS: SmoothPageTransitionsBuilder(),
          TargetPlatform.macOS: SmoothPageTransitionsBuilder(),
          TargetPlatform.windows: SmoothPageTransitionsBuilder(),
          TargetPlatform.linux: SmoothPageTransitionsBuilder(),
          TargetPlatform.fuchsia: SmoothPageTransitionsBuilder(),
        },
      ),
    );
  }
}

/// Transition de page douce : fondu + glissement vertical leger.
class SmoothPageTransitionsBuilder extends PageTransitionsBuilder {
  const SmoothPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final secondary = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
    );

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.035),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(
          opacity: Tween<double>(begin: 1, end: 0.85).animate(secondary),
          child: child,
        ),
      ),
    );
  }
}
