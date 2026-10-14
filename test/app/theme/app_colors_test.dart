import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languagelearner/app/theme/app_colors.dart';

void main() {
  test('accent is cyan in dark mode and indigo in light mode', () {
    expect(AppColors.dark.accent, const Color(0xFF4FC3F7));
    expect(AppColors.light.accent, const Color(0xFF4353E0));
  });

  test('accent is interpolated and copied', () {
    final mid = AppColors.dark.lerp(AppColors.light, 1);
    expect(mid.accent, AppColors.light.accent);
    expect(AppColors.dark.copyWith(accent: Colors.red).accent, Colors.red);
  });
}
