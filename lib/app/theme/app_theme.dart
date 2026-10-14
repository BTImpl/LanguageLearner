import 'package:flutter/material.dart';
import 'package:languagelearner/app/theme/app_colors.dart';

/// Font families bundled in `assets/fonts` (declared in `pubspec.yaml`).
const String bodyFontFamily = 'Figtree';
const String headingFontFamily = 'BricolageGrotesque';

/// The dark and light Material 3 themes built from the design tokens.
abstract final class AppTheme {
  static final ThemeData dark = _build(AppColors.dark, Brightness.dark);
  static final ThemeData light = _build(AppColors.light, Brightness.light);

  static ThemeData _build(AppColors c, Brightness brightness) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      secondary: c.indigo,
      onSecondary: Colors.white,
      error: c.errorBorder,
      onError: c.errorBackground,
      surface: c.surface,
      onSurface: c.text,
      onSurfaceVariant: c.textMuted,
      outline: c.line,
      outlineVariant: c.line,
      surfaceContainerHighest: c.surfaceRaised,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      fontFamily: bodyFontFamily,
      textTheme: _textTheme(c),
      dividerTheme: DividerThemeData(color: c.line, space: 1, thickness: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.text,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.bottomNav,
        indicatorColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? c.primary
                : c.textMuted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: bodyFontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? c.primary
                : c.textMuted,
          ),
        ),
      ),
      extensions: [c],
    );
  }

  /// Figtree for everything, Bricolage Grotesque (700) for headings and large
  /// words.
  static TextTheme _textTheme(AppColors c) {
    final base = Typography.material2021().black.apply(
      fontFamily: bodyFontFamily,
      displayColor: c.text,
      bodyColor: c.text,
    );
    TextStyle? heading(TextStyle? style) => style?.copyWith(
      fontFamily: headingFontFamily,
      fontWeight: FontWeight.w700,
    );
    return base.copyWith(
      displayLarge: heading(base.displayLarge),
      displayMedium: heading(base.displayMedium),
      displaySmall: heading(base.displaySmall),
      headlineLarge: heading(base.headlineLarge),
      headlineMedium: heading(base.headlineMedium),
      headlineSmall: heading(base.headlineSmall),
      titleLarge: heading(base.titleLarge),
    );
  }
}
