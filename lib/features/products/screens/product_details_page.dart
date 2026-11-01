import 'package:flutter/material.dart';
import 'package:glowai/features/favorites/services/favorites_service.dart';

class ProductDetailsPage extends StatefulWidget {
  final String name;
  final String brand;
  final double price;
  final String description;
  final String category;
  final String? imageUrl;

  const ProductDetailsPage({
    super.key,
    this.name = 'Soft Matte Lipstick',
    this.brand = 'Glow Beauty',
    this.price = 24.99,
    this.description = 'A creamy, comfortable lipstick with a beautiful matte finish, designed for a long-lasting and elegant look.',
    this.category = 'Lips',
    this.imageUrl,
  });

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  bool get isFavorite => FavoritesService.instance.isFavorite(widget.name);

  static const Color primary = Color(0xFF4A1D3A);
  static const Color accent = Color(0xFFB76E79);
  static const Color background = Color(0xFFFFF9F7);
  static const Color textColor = Color(0xFF30272B);

  @override
  void initState() {
    super.initState();
    FavoritesService.instance.addListener(_onFavoritesChanged);
  }

  void _onFavoritesChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    FavoritesService.instance.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void _toggleFavorite() {
    final wasFavorite = isFavorite;

    FavoritesService.instance.toggleFavorite({
      'name': widget.name,
      'brand': widget.brand,
      'price': widget.price,
      'color': const Color(0xFFE8C0B8),
      'icon': Icons.brush,
      'category': widget.category,
      'imageUrl': widget.imageUrl,
      'description': widget.description,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasFavorite ? 'Removed from favorites' : 'Added to favorites',
        ),
        duration: const Duration(seconds: 1),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Product Details',
          style: TextStyle(
            fontFamily: 'Playfair Display',
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: primary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _toggleFavorite,
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: accent,
            ),
            tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Container(
              width: double.infinity,
              height: 280,
              decoration: BoxDecoration(
                color: const Color(0xFFF3DDE2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  Center(
                    child:
                        widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              widget.imageUrl!,
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (_, _, _) => _buildPlaceholder(),
                            ),
                          )
                        : _buildPlaceholder(),
                  ),
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.category,
                        style: const TextStyle(
                          color: primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Brand
            Text(
              widget.brand.toUpperCase(),
              style: const TextStyle(
                color: accent,
                fontSize: 12,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            // Product name
            Text(
              widget.name,
              style: const TextStyle(
                fontFamily: 'Playfair Display',
                fontSize: 27,
                fontWeight: FontWeight.w600,
                color: primary,
              ),
            ),

            const SizedBox(height: 12),

            // Rating
            const Row(
              children: [
                Icon(Icons.star, color: Color(0xFFE5A84B), size: 19),
                SizedBox(width: 5),
                Text(
                  '4.8',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                SizedBox(width: 6),
                Text(
                  '(124 reviews)',
                  style: TextStyle(color: Color(0xFF8C8186)),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Price
            Text(
              '\$${widget.price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: primary,
              ),
            ),

            const SizedBox(height: 24),
            const Divider(color: Color(0xFFE8D5DA)),
            const SizedBox(height: 20),

            // Description heading
            const Text(
              'Product Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: primary,
              ),
            ),

            const SizedBox(height: 10),

            // Description text
            Text(
              widget.description,
              style: const TextStyle(
                fontSize: 14,
                height: 1.7,
                color: textColor,
              ),
            ),

            const SizedBox(height: 28),

            // Save to favorites button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _toggleFavorite,
                icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
                label: Text(
                  isFavorite ? 'Remove from Favorites' : 'Save to Favorites',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primary,
                  side: const BorderSide(color: primary),
                  shape: const StadiumBorder(),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Center(
              child: Text(
                'Beauty made personal ✨',
                style: TextStyle(fontSize: 13, color: Color(0xFF8C8186)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return const Center(
      child: Icon(Icons.spa_outlined, size: 100, color: Color(0xFFB76E79)),
    );
  }
}
