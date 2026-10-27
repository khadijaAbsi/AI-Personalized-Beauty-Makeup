import 'package:flutter/material.dart';
import 'package:glowai/features/history/screens/saved_looks_screen.dart';
import 'package:glowai/features/history/screens/favorite_products_page.dart';

void main() {
  runApp(const GlowAIApp());
}

class GlowAIApp extends StatelessWidget {
  const GlowAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GlowAI',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFFF9F6),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB76E79)),
        fontFamily: 'Roboto',
      ),
      home: const SavedLooksScreen(),
    );
  }
}
