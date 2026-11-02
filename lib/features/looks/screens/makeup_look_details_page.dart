
import 'package:flutter/material.dart';
import 'package:glowai/features/history/services/mock_saved_looks_service.dart';

class MakeupLookDetailsPage extends StatelessWidget {
  const MakeupLookDetailsPage({
    super.key,
    required this.name,
    required this.description,
    required this.tag,
    required this.colors,
    required this.icon,
    required this.occasion,
  });

  final String name;
  final String description;
  final String tag;
  final List<Color> colors;
  final IconData icon;
  final String occasion;

  static const Color primary = Color(0xFF4A1D3A);
  static const Color accent = Color(0xFFB76E79);
  static const Color background = Color(0xFFFFF9F6);

  Future<void> _toggleSaveLook(BuildContext context) async {
    final wasSaved = MockSavedLooksService.isSaved(name, occasion);

    await MockSavedLooksService.toggleSaveLook(
      title: name,
      occasion: occasion,
      description: description,
      previewColor: colors.first,
      previewIcon: icon,
    );

    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          wasSaved ? 'Removed from Saved Looks' : 'Look saved successfully',
        ),
        duration: const Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
        backgroundColor: primary,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _tryLook(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Try-On feature will be connected soon.'),
        duration: Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: primary,
        elevation: 0,
        title: const Text(
          'Look Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Look preview
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        icon,
                        size: 115,
                        color: primary.withValues(alpha: 0.65),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            color: primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Title and description
              Text(
                name,
                style: const TextStyle(
                  color: primary,
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 22),

              // Occasion and style
              Row(
                children: [
                  Expanded(
                    child: _infoCard(
                      icon: Icons.event_outlined,
                      title: 'Occasion',
                      value: occasion,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _infoCard(
                      icon: Icons.auto_awesome_outlined,
                      title: 'Style',
                      value: tag,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              const Text(
                'Look Color Palette',
                style: TextStyle(
                  color: primary,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),

              Row(
                children: List.generate(
                  colors.length,
                  (index) => Expanded(
                    child: Container(
                      height: 58,
                      margin: EdgeInsets.only(
                        right: index == colors.length - 1 ? 0 : 10,
                      ),
                      decoration: BoxDecoration(
                        color: colors[index],
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: primary.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Dynamic Save Button
              SizedBox(
                width: double.infinity,
                child: ValueListenableBuilder<int>(
                  valueListenable: MockSavedLooksService.changes,
                  builder: (context, version, child) {
                    final isSaved =
                        MockSavedLooksService.isSaved(name, occasion);

                    return OutlinedButton.icon(
                      onPressed: () => _toggleSaveLook(context),
                      icon: Icon(
                        isSaved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                      ),
                      label: Text(
                        isSaved ? 'Saved' : 'Save This Look',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isSaved ? accent : primary,
                        side: BorderSide(
                          color: isSaved ? accent : primary,
                        ),
                        backgroundColor: isSaved
                            ? accent.withValues(alpha: 0.08)
                            : Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 17),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Try-on button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _tryLook(context),
                  icon: const Icon(Icons.face_retouching_natural),
                  label: const Text('Try This Look'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.black45,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: primary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
