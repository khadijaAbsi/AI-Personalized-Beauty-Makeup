import 'package:flutter/material.dart';
import 'package:glowai/core/routing/main_shell_scope.dart';
import 'package:glowai/features/favorites/services/favorites_service.dart';
import 'package:glowai/features/history/screens/saved_looks_screen.dart';
import 'package:glowai/features/products/models/product.dart';
import 'package:glowai/features/products/screens/product_details_page.dart';

class FavoriteProductsPage extends StatefulWidget {
  const FavoriteProductsPage({super.key});

  @override
  State<FavoriteProductsPage> createState() => _FavoriteProductsPageState();
}

class _FavoriteProductsPageState extends State<FavoriteProductsPage> {
  static const Color primary = Color(0xFF4A1D3A);
  static const Color accent = Color(0xFFB76E79);
  static const Color background = Color(0xFFFFF9F6);
  bool _isLoading = true;
  String? _errorMessage;

  Future<void> _loadFavorites({bool showSpinner = false}) async {
    if (showSpinner && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      await FavoritesService.instance.ensureLoaded(refresh: true);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not load your favorite products.';
      });
    }
  }

  List<Map<String, dynamic>> get products => FavoritesService.instance.products;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
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
        builder: (_) =>
            ProductDetailsPage.fromProduct(Product.fromFavoriteMap(product)),
      ),
    );
  }

  /// Inside the shell this switches to the Saved Looks tab instead of
  /// stacking a second Saved Looks screen on top of it.
  void _openSavedLooks() {
    final shell = MainShellScope.peek(context);
    if (shell != null) {
      shell.select(MainTab.savedLooks);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SavedLooksScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Standalone: Back pops the route. In the shell: Back goes to the tab the
    // user came from (for example Profile), and is hidden when there is none.
    final back = MainShellScope.backActionOf(context);

    return TabActivationListener(
      tab: MainTab.favorites,
      // Another screen may have added or removed favorites meanwhile.
      onActivated: _loadFavorites,
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: background,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: back.visible
              ? IconButton(
                  tooltip: 'Back',
                  onPressed: back.onPressed,
                  icon: const Icon(Icons.arrow_back_ios_new, color: primary),
                )
              : null,
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
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_errorMessage!),
                            TextButton(
                              onPressed: () =>
                                  _loadFavorites(showSpinner: true),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : products.isEmpty
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
                          key: ValueKey(
                            'remove-favorite-${FavoritesService.productKey(product)}',
                          ),
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
                          onPressed:
                              FavoritesService.instance.isPending(product)
                              ? null
                              : () async {
                                  final productName =
                                      product['name'] as String? ?? 'Product';
                                  try {
                                    await FavoritesService.instance.removeAt(
                                      index,
                                    );
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '$productName removed from favorites',
                                        ),
                                      ),
                                    );
                                  } catch (_) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Could not remove favorite.',
                                        ),
                                      ),
                                    );
                                  }
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
                    if ((product['shade'] as String?)?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 5),
                      Text(
                        product['shade'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6F6469),
                        ),
                      ),
                    ],
                    if ((product['price'] as num? ?? 0) > 0) ...[
                      const SizedBox(height: 9),
                      Text(
                        '\$${(product['price'] as num).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: accent,
                        ),
                      ),
                    ],
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
