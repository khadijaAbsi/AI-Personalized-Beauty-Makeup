import 'package:flutter/material.dart';
import 'package:glowai/features/looks/screens/makeup_look_details_page.dart';
import 'package:glowai/features/history/services/mock_saved_looks_service.dart';

class RecommendedLooksGallery extends StatelessWidget {
  const RecommendedLooksGallery({super.key, required this.occasion});

  final String occasion;

  static const Color primary = Color(0xFF4A1D3A);
  static const Color accent = Color(0xFFB76E79);
  static const Color background = Color(0xFFFFF9F6);
 
Future<void> _toggleLook(
  BuildContext context,
  Map<String, dynamic> look,
) async {
  final colors = look['colors'] as List<Color>;
  final title = look['name'] as String;

  final wasSaved = MockSavedLooksService.isSaved(title, occasion);

  await MockSavedLooksService.toggleSaveLook(
    title: title,
    occasion: occasion,
    description: look['description'] as String,
    previewColor: colors.first,
    previewIcon: look['icon'] as IconData,
  );

  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        wasSaved
            ? '$title removed from Saved Looks'
            : '$title saved to Saved Looks',
      ),
    ),
  );
}

  List<Map<String, dynamic>> get looks {
    switch (occasion.toLowerCase()) {
      case 'office':
        return [
          {
            'name': 'Soft Elegance',
            'description': 'A polished everyday look',
            'icon': Icons.face_retouching_natural,
            'colors': [Color(0xFFE8DCE8), Color(0xFFCDB8CE)],
            'tag': 'Natural',
          },
          {
            'name': 'Classic Nude',
            'description': 'Simple and professional',
            'icon': Icons.spa_outlined,
            'colors': [Color(0xFFF0DFD2), Color(0xFFD9BDAA)],
            'tag': 'Minimal',
          },
          {
            'name': 'Rose Office',
            'description': 'A touch of rosy elegance',
            'icon': Icons.auto_awesome,
            'colors': [Color(0xFFF0D9DE), Color(0xFFD9ADB9)],
            'tag': 'Soft Glam',
          },
        ];

      case 'party':
        return [
          {
            'name': 'Plum Hour',
            'description': 'Bold eyes and berry tones',
            'icon': Icons.auto_awesome,
            'colors': [Color(0xFFDBC1D5), Color(0xFF9E718F)],
            'tag': 'Glam',
          },
          {
            'name': 'Golden Glow',
            'description': 'A radiant evening look',
            'icon': Icons.wb_sunny_outlined,
            'colors': [Color(0xFFF2D9B8), Color(0xFFD3A36D)],
            'tag': 'Glowing',
          },
          {
            'name': 'Velvet Night',
            'description': 'Elegant and dramatic',
            'icon': Icons.nightlight_round,
            'colors': [Color(0xFFBDA7BC), Color(0xFF70516E)],
            'tag': 'Bold',
          },
        ];

      default:
        return [
          {
            'name': 'Soft Dawn',
            'description': 'Fresh and effortless beauty',
            'icon': Icons.wb_sunny_outlined,
            'colors': [Color(0xFFF3DED4), Color(0xFFD8B5AA)],
            'tag': 'Natural',
          },
          {
            'name': 'Rosy Glow',
            'description': 'A soft rosy everyday look',
            'icon': Icons.spa_outlined,
            'colors': [Color(0xFFF1D9E0), Color(0xFFD8AEBB)],
            'tag': 'Soft Glam',
          },
          {
            'name': 'Fresh Bloom',
            'description': 'Light colors and fresh skin',
            'icon': Icons.local_florist_outlined,
            'colors': [Color(0xFFE7E5D7), Color(0xFFC4C7A9)],
            'tag': 'Fresh',
          },
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = looks;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: primary,
        elevation: 0,
        title: const Text(
          'Recommended Looks',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 750 ? 3 : 2;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Find Your Perfect Look',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Explore makeup looks selected for your '
                    '${occasion.toLowerCase()} occasion.',
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1E5E9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: primary,
                          size: 19,
                        ),
                        const SizedBox(width: 9),
                        Text(
                          '$occasion Looks',
                          style: const TextStyle(
                            color: primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Recommended for You',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.72,
                    ),
                    itemBuilder: (context, index) {
                      final look = items[index];
                      final colors = look['colors'] as List<Color>;

                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MakeupLookDetailsPage(
                                  name: look['name'] as String,
                                  description: look['description'] as String,
                                  tag: look['tag'] as String,
                                  colors: look['colors'] as List<Color>,
                                  icon: look['icon'] as IconData,
                                  occasion: occasion,
                                ),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: colors,
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: Stack(
                                    children: [

                                      Positioned(
                                        top: 10,
                                        right: 10,
                                        child: ValueListenableBuilder<int>(
                                          valueListenable: MockSavedLooksService.changes,
                                          builder: (context, version, child) {
                                            final isSaved = MockSavedLooksService.isSaved(
                                              look['name'] as String,
                                              occasion,
                                            );

                                            return IconButton(
                                              tooltip: isSaved ? 'Remove from Saved Looks' : 'Save look',
                                              onPressed: () => _toggleLook(context, look),
                                              icon: Icon(
                                                isSaved ? Icons.bookmark : Icons.bookmark_border,
                                              ),
                                              style: IconButton.styleFrom(
                                                backgroundColor: Colors.white,
                                                foregroundColor: primary,
                                              ),
                                            );
                                          },
                                        ),
                                      ),

                                      Center(
                                        child: Icon(
                                          look['icon'] as IconData,
                                          size: 68,
                                          color: primary.withValues(
                                            alpha: 0.65,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 10,
                                        left: 10,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 9,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.85,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            look['tag'] as String,
                                            style: const TextStyle(
                                              color: primary,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      look['name'] as String,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: primary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      look['description'] as String,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 11,
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 9),
                                    const Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          'View Details',
                                          style: TextStyle(
                                            color: accent,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(
                                          Icons.arrow_forward,
                                          size: 14,
                                          color: accent,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
