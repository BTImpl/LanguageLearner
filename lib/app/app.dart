import 'package:flutter/material.dart';
import 'package:languagelearner/features/home/home_screen.dart';

class LanguageLearnerApp extends StatelessWidget {
  const LanguageLearnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LanguageLearner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
      home: const HomeScreen(),
    );
  }
}
