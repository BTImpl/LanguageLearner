import 'package:flutter/material.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

/// Empty settings screen placeholder; the real content comes with card LL-09.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(context.i18n.navSettings)));
  }
}
