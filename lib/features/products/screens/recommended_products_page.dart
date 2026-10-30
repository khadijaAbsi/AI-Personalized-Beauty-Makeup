import 'package:flutter/material.dart';
import 'package:glowai/features/favorites/services/favorites_service.dart';
import 'package:glowai/features/products/screens/product_details_page.dart';
import 'package:glowai/features/history/screens/favorite_products_page.dart';
import 'package:glowai/features/history/screens/saved_looks_screen.dart';
import 'package:glowai/features/home/screens/home_dashboard.dart';

class RecommendedProductsPage extends StatefulWidget {
  const RecommendedProductsPage({super.key});

  @override
  State<RecommendedProductsPage> createState() =>
      _RecommendedProductsPageState();
}

class _RecommendedProductsPageState extends State<RecommendedProductsPage> {
  static const Color primary = Color(0xFF4A1D3A);
  static const Color accent = Color(0xFFB76E79);
  static const Color background = Color(0xFFFFF9F7);
  static const Color textColor = Color(0xFF30272B);

  String selectedCategory = 'All';

  final List<Map<String, dynamic>> _products = [
    {
      'name': 'Soft Matte Lipstick',
      'brand': 'Glow Beauty',
      'price': 24.99,
      'category': 'Lips',
      'description': 'A creamy, comfortable lipstick with a beautiful matte finish for an elegant look.',
      'color': Color(0xFFF3DDE2),
      'icon': Icons.brush,
    },
    {
      'name': 'Rose Blush',
      'brand': 'Blush Studio',
      'price': 18.50,
      'category': 'Face',
      'description': 'A soft rose blush that adds a natural flush and a fresh glow to your cheeks.',
      'color': Color(0xFFF5E0DC),
      'icon': Icons.circle,
    },
    {
      'name': 'Luminous Foundation',
      'brand': 'Glow Beauty',
      'price': 32.00,
      'category': 'Face',
      'description': 'A lightweight foundation designed to create a smooth, radiant-looking complexion.',
      'color': Color(0xFFEAD4C1),
      'icon': Icons.face_retouching_natural,
    },
    {
      'name': 'Volume Mascara',
      'brand': 'Lash & Co.',
      'price': 21.99,
      'category': 'Eyes',
      'description': 'A defining mascara that gives lashes a fuller and more dramatic appearance.',
      'color': Color(0xFFE4DCE8),
      'icon': Icons.remove_red_eye_outlined,
    },
    {
      'name': 'Nude Lip Gloss',
      'brand': 'Blush Studio',
      'price': 16.99,
      'category': 'Lips',
      'description': 'A glossy nude lip finish that gives your lips a soft, luminous appearance.',
      'color': Color(0xFFF0D9D0),
      'icon': Icons.water_drop_outlined,
    },
    {
      'name': 'Eyeshadow Palette',
      'brand': 'Velvet Touch',
      'price': 39.99,
      'category': 'Eyes',
      'description': 'A versatile palette of wearable shades for everyday makeup and special occasions.',
      'color': Color(0xFFE8DCE0),
      'icon': Icons.palette_outlined,
    },
    {
      'name': 'Setting Powder',
      'brand': 'Glow Beauty',
      'price': 22.50,
      'category': 'Face',
      'description': 'A lightweight finishing powder to help your makeup look smooth and polished.',
      'color': Color(0xFFEDE2D5),
      'icon': Icons.blur_on,
    },
    {
      'name': 'Brow Definer',
      'brand': 'Lash & Co.',
      'price': 14.99,
      'category': 'Eyes',
      'description': 'A precise brow product for defining and shaping your brows with a natural finish.',
      'color': Color(0xFFE5D8D1),
      'icon': Icons.edit_outlined,
    },
  ];

  final List<String> _categories = ['All', 'Face', 'Eyes', 'Lips'];

  List<Map<String, dynamic>> get _filteredProducts {
    if (selectedCategory == 'All') {
      return _products;
    }

    return _products
        .where((product) => product['category'] == selectedCategory)
        .toList();
  }

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

  bool _isFavorite(Map<String, dynamic> product) {
    return FavoritesService.instance.isFavorite(product['name'] as String);
  }

  void _toggleFavorite(Map<String, dynamic> product) {
    final wasFavorite = _isFavorite(product);

    FavoritesService.instance.toggleFavorite({
      ...product,
      'imageUrl': product['imageUrl'],
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            wasFavorite
                ? '${product['name']} removed from favorites'
                : '${product['name']} added to favorites',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
  }

  void _openProduct(Map<String, dynamic> product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailsPage(
          name: product['name'] as String,
          brand: product['brand'] as String,
          price: (product['price'] as num).toDouble(),
          description: product['description'] as String,
          category: product['category'] as String,
          imageUrl: product['imageUrl'] as String?,
        ),
      ),
    );
  }

  void _handleNavigation(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeDashboard()),
      );
      return;
    }
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeDashboard()),
      );
      return;
    }
    // Discover is the current page.
    if (index == 1) return;

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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This section will be connected soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = _filteredProducts;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'GlowAI',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: primary,
            letterSpacing: 1.2,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_ios_new, color: primary),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Text(
                'Recommended for You',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Discover beauty products picked for your next look ✨',
                style: TextStyle(fontSize: 14, color: Color(0xFF8C8186)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 42,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = selectedCategory == category;

                  return ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        selectedCategory = category;
                      });
                    },
                    selectedColor: primary,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : primary,
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide(
                      color: isSelected ? primary : const Color(0xFFE8D5DA),
                    ),
                    shape: const StadiumBorder(),
                    showCheckmark: false,
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '${products.length} products',
                style: const TextStyle(fontSize: 14, color: Color(0xFF8C8186)),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                itemCount: products.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.58,
                ),
                itemBuilder: (context, index) {
                  return _buildProductCard(products[index]);
                },
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: _handleNavigation,
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

  Widget _buildProductCard(Map<String, dynamic> product) {
    final isFavorite = _isFavorite(product);
    final productColor = product['color'] as Color;
    final productIcon = product['icon'] as IconData;
    final imageUrl = product['imageUrl'] as String?;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openProduct(product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color: productColor,
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) {
                              return Icon(productIcon, size: 70, color: accent);
                            },
                          )
                        : Center(
                            child: Icon(productIcon, size: 70, color: accent),
                          ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      child: IconButton(
                        onPressed: () => _toggleFavorite(product),
                        tooltip: isFavorite
                            ? 'Remove from favorites'
                            : 'Add to favorites',
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: accent,
                          size: 21,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 38,
                          minHeight: 38,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        product['category'] as String,
                        style: const TextStyle(
                          fontSize: 10,
                          color: primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 10, 11, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['brand'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9A8585),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    product['name'] as String,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${(product['price'] as num).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.star, size: 16, color: Color(0xFFE5A84B)),
                      SizedBox(width: 4),
                      Text(
                        '4.8',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Recommended',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF8C8186),
                        ),
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
  }
}
