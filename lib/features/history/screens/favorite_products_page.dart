import 'package:flutter/material.dart';

class FavoriteProductsPage extends StatefulWidget {
  const FavoriteProductsPage({super.key});

  @override
  State<FavoriteProductsPage> createState() => _FavoriteProductsPageState();
}

class _FavoriteProductsPageState extends State<FavoriteProductsPage> {
  final List<Map<String, dynamic>> products = [
    {
      'name': 'Soft Matte Lipstick',
      'brand': 'Luxe Beauty',
      'price': 18.0,
      'color': const Color(0xFFE8C0B8),
      'icon': Icons.brush,
    },
    {
      'name': 'Rose Blush',
      'brand': 'Glow Studio',
      'price': 24.0,
      'color': const Color(0xFFF0D1D0),
      'icon': Icons.face_retouching_natural,
    },
    {
      'name': 'Glow Foundation',
      'brand': 'Pure Skin',
      'price': 32.0,
      'color': const Color(0xFFE8D4C0),
      'icon': Icons.water_drop_outlined,
    },
    {
      'name': 'Volume Mascara',
      'brand': 'Lash Lab',
      'price': 16.0,
      'color': const Color(0xFFD8C8C7),
      'icon': Icons.visibility_outlined,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF9F6),
        elevation: 0,
        leading: IconButton(
          onPressed: () {},
          icon: const Icon(Icons.arrow_back_ios_new),
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
            onPressed: () {},
            icon: const Icon(Icons.shopping_bag_outlined),
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
        currentIndex: 3,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF4A1D3A),
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
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
                    color: product['color'] as Color,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                  ),
                  child: Icon(
                    product['icon'] as IconData,
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
                      icon: const Icon(
                        Icons.favorite,
                        color: Color(0xFFB76E79),
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          products.removeAt(index);
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${product['name']} removed from favorites',
                            ),
                            duration: const Duration(seconds: 2),
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
                  product['brand'] as String,
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
                    color: Color(0xFF392D30),
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  '\$${(product['price'] as double).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB76E79),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.favorite_border, size: 65, color: Color(0xFFB76E79)),
          const SizedBox(height: 16),
          const Text(
            'No favorites yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your favorite products will appear here.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              setState(() {
                products.addAll([
                  {
                    'name': 'Soft Matte Lipstick',
                    'brand': 'Luxe Beauty',
                    'price': 18.0,
                    'color': const Color(0xFFE8C0B8),
                    'icon': Icons.brush,
                  },
                  {
                    'name': 'Rose Blush',
                    'brand': 'Glow Studio',
                    'price': 24.0,
                    'color': const Color(0xFFF0D1D0),
                    'icon': Icons.face_retouching_natural,
                  },
                ]);
              });
            },
            child: const Text('Explore favorites'),
          ),
        ],
      ),
    );
  }
}
