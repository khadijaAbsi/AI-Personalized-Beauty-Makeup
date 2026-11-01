import 'package:flutter/material.dart';
import 'package:glowai/features/history/screens/favorite_products_page.dart';
import 'package:glowai/features/history/screens/saved_looks_screen.dart';
import 'package:glowai/features/home/screens/occasion_selection_page.dart';
import 'package:glowai/features/looks/screens/makeup_look_details_page.dart';
import 'package:glowai/features/history/services/mock_saved_looks_service.dart';

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

  static const Color primary = Color(0xFF4A1D3A);
  static const Color accent = Color(0xFFB76E79);
  static const Color background = Color(0xFFFFF9F7);
  static const Color textColor = Color(0xFF30272B);

  void _showComingSoon(BuildContext context, String page) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$page will be connected soon.')));
  }

  Future<void> _toggleLook(
    BuildContext context, {
    required String title,
    required String description,
    required Color color,
    required IconData icon,
  }) async {
    final wasSaved = MockSavedLooksService.isSaved(title, 'Everyday');

    await MockSavedLooksService.toggleSaveLook(
      title: title,
      occasion: 'Everyday',
      description: description,
      previewColor: color,
      previewIcon: icon,
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

  void _handleNavigation(BuildContext context, int index) {
    if (index == 0) return;

    if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SavedLooksScreen()),
      );
      return;
    }

    if (index == 4) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FavoriteProductsPage()),
      );
      return;
    }

    final pages = {1: 'Discover', 2: 'Try-On', 5: 'Profile'};

    _showComingSoon(context, pages[index] ?? 'This section');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Good morning',
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF8C8186),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Layla',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0DDE3),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE8CBD5)),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'L',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: primary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 26),

                  // Face analysis card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF4A1D3A), Color(0xFF75445D)],
                      ),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withOpacity(0.16),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.13),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.face_retouching_natural,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Find your perfect look',
                          style: TextStyle(
                            fontSize: 25,
                            height: 1.2,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Upload a portrait and let AI estimate your '
                          'face shape and skin tone.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _showComingSoon(context, 'Face analysis'),
                            icon: const Icon(Icons.auto_awesome),
                            label: const Text('Analyze My Face'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: primary,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Shop by occasion
                  _sectionHeader(
                    title: 'Shop by occasion',
                    subtitle: 'Find a look for every moment',
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _occasionCard(
                          context,
                          title: 'Casual',
                          icon: Icons.wb_sunny_outlined,
                          color: const Color(0xFFF4E5D8),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _occasionCard(
                          context,
                          title: 'Office',
                          icon: Icons.work_outline,
                          color: const Color(0xFFE9E1EF),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _occasionCard(
                          context,
                          title: 'Party',
                          icon: Icons.celebration_outlined,
                          color: const Color(0xFFF4DDE3),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Recommended looks
                  _sectionHeader(
                    title: 'Recommended looks',
                    subtitle: 'A little inspiration for your next look',
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _lookCard(
                          context,
                          title: 'Soft Dawn',
                          subtitle: 'Soft & natural',
                          colors: const [Color(0xFFF3E2DC), Color(0xFFE6C6CB)],
                          icon: Icons.wb_twilight,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _lookCard(
                          context,
                          title: 'Plum Hour',
                          subtitle: 'Elegant & bold',
                          colors: const [Color(0xFFE6D7E5), Color(0xFFB69AB8)],
                          icon: Icons.auto_awesome,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      // Bottom navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) => _handleNavigation(context, index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: primary,
        unselectedItemColor: const Color(0xFF9A9090),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Discover',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.face_retouching_natural_outlined),
            activeIcon: Icon(Icons.face_retouching_natural),
            label: 'Try-On',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_border),
            activeIcon: Icon(Icons.bookmark),
            label: 'Saved',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            activeIcon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: primary,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 13, color: Color(0xFF8C8186)),
        ),
      ],
    );
  }

  Widget _occasionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OccasionSelectionPage(initialOccasion: title),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 19, horizontal: 4),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(icon, color: primary, size: 24),
              ),
              const SizedBox(height: 11),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lookCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<Color> colors,
    required IconData icon,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MakeupLookDetailsPage(
                name: title,
                description: subtitle,
                tag: 'Recommended',
                colors: colors,
                icon: icon,
                occasion: 'Everyday',
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 145,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 10,
                    left: 10,
                    child: ValueListenableBuilder<int>(
                      valueListenable: MockSavedLooksService.changes,
                      builder: (context, version, child) {
                        final isSaved = MockSavedLooksService.isSaved(
                          title,
                          'Everyday',
                        );

                        return IconButton(
                          tooltip: isSaved ? 'Remove from Saved Looks' : 'Save look',
                          onPressed: () {
                            _toggleLook(
                              context,
                              title: title,
                              description: subtitle,
                              color: colors.first,
                              icon: icon,
                            );
                          },
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
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Demo',
                        style: TextStyle(
                          color: primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Icon(
                      icon,
                      size: 58,
                      color: primary.withOpacity(0.7),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Icon(
                      Icons.arrow_outward,
                      size: 19,
                      color: primary.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8C8186),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}