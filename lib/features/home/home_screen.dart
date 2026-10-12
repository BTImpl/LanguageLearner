import 'package:flutter/material.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

/// Empty home screen placeholder; the real content comes with card LL-10.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [Text(i18n.appTitle), Text(i18n.wordCount(0))],
        ),
      ),
    );
  }
}
