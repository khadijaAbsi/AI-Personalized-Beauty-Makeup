import 'package:flutter/material.dart';
import 'package:glowai/features/home/screens/home_dashboard.dart';
import 'package:glowai/features/home/screens/occasion_selection_page.dart';
import 'package:glowai/features/looks/screens/final_makeup_results_page.dart';
import 'package:glowai/features/products/screens/recommended_products_page.dart';

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
home: const FinalMakeupResultsPage(
  name: 'Soft Glam',
  description: 'A soft glam look with warm tones and a subtle glow.',
  tag: 'Recommended',
  colors: [
    Color(0xFFF3DDE2),
    Color(0xFFB76E79),
  ],
  icon: Icons.auto_awesome,
  occasion: 'Party',
),    );
  }
}
