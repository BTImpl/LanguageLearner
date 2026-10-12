import 'package:flutter/material.dart';

/// Üres kezdőképernyő; a valódi tartalmat az LL-10 kártya adja.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('LanguageLearner')));
  }
}
