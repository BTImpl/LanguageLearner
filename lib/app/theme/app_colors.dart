import 'package:flutter/material.dart';

/// Color tokens of the design (see `docs/design/README.md`).
///
/// Registered as a [ThemeExtension], so widgets read them with
/// `context.colors` instead of hard-coding hex values.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.line,
    required this.bottomNav,
    required this.text,
    required this.textMuted,
    required this.primary,
    required this.onPrimary,
    required this.indigo,
    required this.highlight,
    required this.accent,
    required this.brandGradient,
    required this.onBrandGradient,
    required this.successBackground,
    required this.successBorder,
    required this.successText,
    required this.successNumber,
    required this.errorBackground,
    required this.errorBorder,
    required this.errorText,
    required this.errorNumber,
  });

  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color line;
  final Color bottomNav;
  final Color text;
  final Color textMuted;
  final Color primary;
  final Color onPrimary;
  final Color indigo;

  /// Icons, selection and active text on the screen background.
  final Color highlight;

  /// The active menu item and the progress indicator: the primary color in
  /// dark mode, indigo in light mode (the primary color is too pale on white).
  final Color accent;

  /// English side of the flashcard and the round-end header card only.
  final LinearGradient brandGradient;
  final Color onBrandGradient;

  final Color successBackground;
  final Color successBorder;
  final Color successText;
  final Color successNumber;

  final Color errorBackground;
  final Color errorBorder;
  final Color errorText;
  final Color errorNumber;

  // CSS `165deg`: the gradient runs almost straight down, slightly to the
  // right. Flutter alignments are the same direction vector, sin/-cos of 165°.
  static const LinearGradient _gradient = LinearGradient(
    begin: Alignment(-0.259, -0.966),
    end: Alignment(0.259, 0.966),
    colors: [Color(0xFF6C7BFF), Color(0xFF4FC3F7)],
  );

  static const AppColors dark = AppColors(
    background: Color(0xFF0A1226),
    surface: Color(0xFF141E3A),
    surfaceRaised: Color(0xFF1C2850),
    line: Color(0xFF26335C),
    bottomNav: Color(0xFF0E1730),
    text: Color(0xFFEEF2FF),
    textMuted: Color(0xFFA3AED0),
    primary: Color(0xFF4FC3F7),
    onPrimary: Color(0xFF0A1226),
    indigo: Color(0xFF5B6CFF),
    highlight: Color(0xFF8C99FF),
    accent: Color(0xFF4FC3F7),
    brandGradient: _gradient,
    onBrandGradient: Color(0xFF0A1226),
    successBackground: Color(0xFF0F3A2C),
    successBorder: Color(0xFF4ADE9B),
    successText: Color(0xFFC8F7DF),
    successNumber: Color(0xFF7FE8B7),
    errorBackground: Color(0xFF4A1620),
    errorBorder: Color(0xFFFF6B7A),
    errorText: Color(0xFFFFD5D9),
    errorNumber: Color(0xFFFF9AA4),
  );

  /// The surface, raised surface, bottom navigation, success and error colors
  /// are not part of the original design; they are derived (see
  /// `docs/design/README.md`).
  static const AppColors light = AppColors(
    background: Color(0xFFF2F4FB),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFE6EAFA),
    line: Color(0xFFD9DFF0),
    bottomNav: Color(0xFFFFFFFF),
    text: Color(0xFF0A1226),
    textMuted: Color(0xFF56607F),
    primary: Color(0xFF4FC3F7),
    onPrimary: Color(0xFF0A1226),
    indigo: Color(0xFF5B6CFF),
    highlight: Color(0xFF4353E0),
    accent: Color(0xFF4353E0),
    brandGradient: _gradient,
    onBrandGradient: Color(0xFF0A1226),
    successBackground: Color(0xFFDDF6E9),
    successBorder: Color(0xFF1FA971),
    successText: Color(0xFF0B4A33),
    successNumber: Color(0xFF12794F),
    errorBackground: Color(0xFFFDE3E6),
    errorBorder: Color(0xFFE5484D),
    errorText: Color(0xFF6B1520),
    errorNumber: Color(0xFFC4293A),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceRaised,
    Color? line,
    Color? bottomNav,
    Color? text,
    Color? textMuted,
    Color? primary,
    Color? onPrimary,
    Color? indigo,
    Color? highlight,
    Color? accent,
    LinearGradient? brandGradient,
    Color? onBrandGradient,
    Color? successBackground,
    Color? successBorder,
    Color? successText,
    Color? successNumber,
    Color? errorBackground,
    Color? errorBorder,
    Color? errorText,
    Color? errorNumber,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      line: line ?? this.line,
      bottomNav: bottomNav ?? this.bottomNav,
      text: text ?? this.text,
      textMuted: textMuted ?? this.textMuted,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      indigo: indigo ?? this.indigo,
      highlight: highlight ?? this.highlight,
      accent: accent ?? this.accent,
      brandGradient: brandGradient ?? this.brandGradient,
      onBrandGradient: onBrandGradient ?? this.onBrandGradient,
      successBackground: successBackground ?? this.successBackground,
      successBorder: successBorder ?? this.successBorder,
      successText: successText ?? this.successText,
      successNumber: successNumber ?? this.successNumber,
      errorBackground: errorBackground ?? this.errorBackground,
      errorBorder: errorBorder ?? this.errorBorder,
      errorText: errorText ?? this.errorText,
      errorNumber: errorNumber ?? this.errorNumber,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) {
      return this;
    }
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      line: Color.lerp(line, other.line, t)!,
      bottomNav: Color.lerp(bottomNav, other.bottomNav, t)!,
      text: Color.lerp(text, other.text, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      indigo: Color.lerp(indigo, other.indigo, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      brandGradient: LinearGradient.lerp(
        brandGradient,
        other.brandGradient,
        t,
      )!,
      onBrandGradient: Color.lerp(onBrandGradient, other.onBrandGradient, t)!,
      successBackground: Color.lerp(
        successBackground,
        other.successBackground,
        t,
      )!,
      successBorder: Color.lerp(successBorder, other.successBorder, t)!,
      successText: Color.lerp(successText, other.successText, t)!,
      successNumber: Color.lerp(successNumber, other.successNumber, t)!,
      errorBackground: Color.lerp(errorBackground, other.errorBackground, t)!,
      errorBorder: Color.lerp(errorBorder, other.errorBorder, t)!,
      errorText: Color.lerp(errorText, other.errorText, t)!,
      errorNumber: Color.lerp(errorNumber, other.errorNumber, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  /// The design color tokens of the current theme.
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
