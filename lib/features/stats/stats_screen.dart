import 'package:flutter/material.dart';
import 'package:languagelearner/i18n/context_i18n.dart';

/// Empty statistics screen placeholder; the real content comes with card
/// LL-25.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(context.i18n.navStats)));
  }
}
