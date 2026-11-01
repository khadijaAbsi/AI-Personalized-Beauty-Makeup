import 'package:flutter/material.dart';
import 'package:glowai/features/favorites/services/favorites_service.dart';
import 'package:glowai/features/history/screens/saved_looks_screen.dart';
import 'package:glowai/features/products/screens/product_details_page.dart';
import 'package:glowai/features/home/screens/home_dashboard.dart';

class FavoriteProductsPage extends StatefulWidget {
  const FavoriteProductsPage({super.key});

  @override
  State<FavoriteProductsPage> createState() => _FavoriteProductsPageState();
}

class _FavoriteProductsPageState extends State<FavoriteProductsPage> {
  static const Color primary = Color(0xFF4A1D3A);
  static const Color accent = Color(0xFFB76E79);
  static const Color background = Color(0xFFFFF9F6);
  void _addTestProduct() {
    final service = FavoritesService.instance;

    if (service.products.any((product) => product['name'] == 'Test Lipstick')) {
      return;
    }

    service.toggleFavorite({
      'name': 'Test Lipstick',
      'brand': 'Glow Beauty',
      'price': 19.99,
      'description':
          'This is a test lipstick used to check product details navigation.',
      'category': 'Makeup',
      'color': const Color(0xFFE8C0B8),
      'icon': Icons.spa_outlined,
      'imageUrl': null,
    });
  }

  List<Map<String, dynamic>> get products => FavoritesService.instance.products;

  @override
  void initState() {
    super.initState();
    _addTestProduct();
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

  void _openProduct(Map<String, dynamic> product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailsPage(
          name: product['name'] as String? ?? 'Product',
          brand: product['brand'] as String? ?? '',
          price: (product['price'] as num? ?? 0).toDouble(),
          description:
              product['description'] as String? ?? 'No description available.',
          category: product['category'] as String? ?? 'Beauty',
          imageUrl: product['imageUrl'] as String?,
        ),
      ),
    );
  }

  void _openSavedLooks() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SavedLooksScreen()),
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
    if (index == 4) return;

    if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SavedLooksScreen()),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This section will be connected soon.')),
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
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_ios_new, color: primary),
        ),
        title: const Text(
          'GlowAI',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8D4F5A),
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Saved Looks',
            onPressed: _openSavedLooks,
            icon: const Icon(Icons.bookmark_border, color: primary),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Favorites',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF392D30),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${products.length} products saved for you',
              style: const TextStyle(fontSize: 14, color: Color(0xFF8D7D7D)),
            ),
            const SizedBox(height: 22),
            Expanded(
              child: products.isEmpty
                  ? _buildEmptyState()
                  : GridView.builder(
                      itemCount: products.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 18,
                            childAspectRatio: 0.62,
                          ),
                      itemBuilder: (context, index) {
                        final product = products[index];

                        return _buildProductCard(product, index);
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 4,
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

  Widget _buildProductCard(Map<String, dynamic> product, int index) {
    final productColor = product['color'] as Color? ?? const Color(0xFFE8C0B8);
    final productIcon = product['icon'] as IconData? ?? Icons.spa_outlined;
    final imageUrl = product['imageUrl'] as String?;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openProduct(product),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: productColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                      ),
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(18),
                              ),
                              child: Image.network(
                                imageUrl,
                                width: double.infinity,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    productIcon,
                                    size: 76,
                                    color: const Color(0xFF98636A),
                                  );
                                },
                              ),
                            )
                          : Icon(
                              productIcon,
                              size: 76,
                              color: const Color(0xFF98636A),
                            ),
                    ),
                    Positioned(
                      top: 9,
                      right: 9,
                      child: Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        child: IconButton(
                          constraints: const BoxConstraints(
                            minWidth: 38,
                            minHeight: 38,
                          ),
                          padding: EdgeInsets.zero,
                          tooltip: 'Remove from favorites',
                          icon: const Icon(
                            Icons.favorite,
                            color: accent,
                            size: 20,
                          ),
                          onPressed: () {
                            final productName =
                                product['name'] as String? ?? 'Product';

                            FavoritesService.instance.removeAt(index);

                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '$productName removed from favorites',
                                  ),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(11, 12, 11, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['brand'] as String? ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9A8585),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      product['name'] as String? ?? 'Product',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF392D30),
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      '\$${(product['price'] as num? ?? 0).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 65, color: accent),
          SizedBox(height: 16),
          Text(
            'No favorites yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF392D30),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Your favorite products will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF8D7D7D)),
          ),
        ],
      ),
    );
  }
}
