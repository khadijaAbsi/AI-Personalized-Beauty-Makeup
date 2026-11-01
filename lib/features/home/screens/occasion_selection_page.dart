import 'package:flutter/material.dart';
import 'package:glowai/features/looks/screens/recommended_looks_gallery.dart';

class OccasionSelectionPage extends StatefulWidget {
  const OccasionSelectionPage({super.key, this.initialOccasion});

  final String? initialOccasion;

  @override
  State<OccasionSelectionPage> createState() => _OccasionSelectionPageState();
}

class _OccasionSelectionPageState extends State<OccasionSelectionPage> {
  static const Color primary = Color(0xFF4A1D3A);
  static const Color accent = Color(0xFFB76E79);
  static const Color background = Color(0xFFFFF9F6);

  late String? selectedOccasion;

  @override
  void initState() {
    super.initState();
    selectedOccasion = widget.initialOccasion;
  }

  final List<Map<String, dynamic>> occasions = [
    {
      'name': 'Casual',
      'subtitle': 'Easy everyday beauty',
      'icon': Icons.wb_sunny_outlined,
      'colors': [Color(0xFFF5E4E8), Color(0xFFE8C8D2)],
    },
    {
      'name': 'Office',
      'subtitle': 'Polished and professional',
      'icon': Icons.work_outline,
      'colors': [Color(0xFFE9E1F0), Color(0xFFD1C0DE)],
    },
    {
      'name': 'Party',
      'subtitle': 'Glam up for the night',
      'icon': Icons.celebration_outlined,
      'colors': [Color(0xFFF4E4D8), Color(0xFFE7C4AD)],
    },
  ];

  void _continue() {
    if (selectedOccasion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an occasion first.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecommendedLooksGallery(occasion: selectedOccasion!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        foregroundColor: primary,
        title: const Text(
          'Choose an Occasion',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'What are you getting ready for?',
                style: TextStyle(
                  color: primary,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Choose your occasion and discover makeup looks '
                'that match your style.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 26),

              ...occasions.map((occasion) {
                final name = occasion['name'] as String;
                final isSelected = selectedOccasion == name;
                final colors = occasion['colors'] as List<Color>;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        selectedOccasion = name;
                      });
                    },
                    borderRadius: BorderRadius.circular(22),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: colors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isSelected ? primary : Colors.transparent,
                          width: isSelected ? 2.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 66,
                            height: 66,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(
                              occasion['icon'] as IconData,
                              color: primary,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    color: primary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  occasion['subtitle'] as String,
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: primary,
                            size: 26,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Explore Makeup Looks',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go Back', style: TextStyle(color: accent)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
