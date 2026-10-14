import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the app is dark or light.
///
/// Fixed to dark for now (the design default). Card LL-08 binds this to the
/// stored `themeMode` setting.
final appThemeModeProvider = Provider<ThemeMode>((ref) => ThemeMode.dark);
