import 'package:flutter/material.dart';
import 'package:glowai/features/my_looks/screens/my_looks_screen.dart';
import 'package:glowai/features/my_looks/services/my_looks_service.dart';
import 'package:glowai/features/products/screens/recommended_products_page.dart';

class FinalMakeupResultsPage extends StatefulWidget {
  const FinalMakeupResultsPage({
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

  @override
  State<FinalMakeupResultsPage> createState() => _FinalMakeupResultsPageState();
}

class _FinalMakeupResultsPageState extends State<FinalMakeupResultsPage> {
  static const Color primary = Color(0xFF4A1D3A);
  static const Color accent = Color(0xFFB76E79);
  static const Color background = Color(0xFFFFF9F6);

  bool _isSaved = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // التحقق مما إذا كان اللوك محفوظاً مسبقاً عند فتح الصفحة
    _isSaved = MyLooksService.myLooks.any(
      (item) => item.title == widget.name && item.occasion == widget.occasion,
    );
  }

  void _saveLook() {
    if (_isSaving) return;

    if (_isSaved) {
      final look = MyLooksService.myLooks.where(
        (item) =>
            item.title == widget.name &&
            item.occasion == widget.occasion,
      );

      if (look.isNotEmpty) {
        MyLooksService.removeLook(look.first);
      }

      setState(() {
        _isSaved = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Look removed from My Looks')),
      );
    } else {
      setState(() {
        _isSaving = true;
      });

      MyLooksService.saveLook(
        title: widget.name,
        description: widget.description,
        tag: widget.tag,
        occasion: widget.occasion,
        colors: widget.colors,
        icon: widget.icon,
      );

      setState(() {
        _isSaved = true;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Look saved to My Looks!')),
      );
    }
  }

  void _viewProducts() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RecommendedProductsPage()),
    );
  }

  void _viewMyLooks() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MyLooksScreen(),
      ),
    );
  }

  Widget _previewCard({
    required String label,
    required Color color,
    required bool isAfter,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 205,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isAfter
                    ? widget.colors
                    : [const Color(0xFFE8DCD7), const Color(0xFFD5C7C2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Icon(
                isAfter ? widget.icon : Icons.face_outlined,
                size: 75,
                color: color.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: primary,
        elevation: 0,
        title: const Text(
          'Your Makeup Results',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          ValueListenableBuilder<int>(
            valueListenable: MyLooksService.changes,
            builder: (context, value, child) {
              final count = MyLooksService.myLooks.length;

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: TextButton.icon(
                  onPressed: _viewMyLooks,
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF1E5E9),
                    foregroundColor: primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: const Icon(
                    Icons.bookmark_rounded,
                    size: 18,
                  ),
                  label: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Icon(Icons.auto_awesome, color: accent, size: 34),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Your Look Is Ready!',
                  style: TextStyle(
                    color: primary,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Here is a preview of your selected makeup look.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // Before and After preview
              Row(
                children: [
                  _previewCard(
                    label: 'Before',
                    color: const Color(0xFF8C7770),
                    isAfter: false,
                  ),
                  const SizedBox(width: 14),
                  _previewCard(label: 'After', color: primary, isAfter: true),
                ],
              ),

              const SizedBox(height: 26),

              // Look information
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: const TextStyle(
                        color: primary,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.description,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [_tag(widget.occasion), _tag(widget.tag)],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveLook,
                  icon: Icon(
                    _isSaved ? Icons.bookmark : Icons.bookmark_border,
                  ),
                  label: Text(
                    _isSaving
                        ? 'Saving...'
                        : _isSaved
                            ? 'Saved to My Looks'
                            : 'Save Look',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isSaved ? accent : primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Products button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _viewProducts,
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: const Text('View Recommended Products'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primary,
                    side: const BorderSide(color: accent),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
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

  Widget _tag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF1E5E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}