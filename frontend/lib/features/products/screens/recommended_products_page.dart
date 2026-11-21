import 'package:flutter/material.dart';
import 'package:glowai/core/routing/main_shell_scope.dart';
import 'package:glowai/core/theme/app_colors.dart';
import 'package:glowai/features/favorites/services/favorites_service.dart';
import 'package:glowai/features/products/models/product.dart';
import 'package:glowai/features/products/screens/product_details_page.dart';
import 'package:glowai/features/products/services/product_catalog_service.dart';

enum _CatalogStatus { loading, loaded, error }

/// Browsable product list.
///
/// It is the Explore tab inside the main shell, and the standalone
/// "Recommended products" page when pushed (for example from the final try-on
/// results). Products come from a [ProductCatalogService] (mock data today).
/// Favorites are real: the heart reads and writes `FavoritesService`, so it
/// stays in sync with the details and Favorites screens.
class RecommendedProductsPage extends StatefulWidget {
  const RecommendedProductsPage({
    super.key,
    this.catalogService = const MockProductCatalogService(),
    this.heading,
    this.subheading,
  });

  /// Where products come from. Swap for PSGAN-based recommendations later.
  final ProductCatalogService catalogService;

  /// Optional overrides. By default the tab says "Explore" and the standalone
  /// page keeps its original "Recommended for You" wording.
  final String? heading;
  final String? subheading;

  @override
  State<RecommendedProductsPage> createState() =>
      _RecommendedProductsPageState();
}

class _RecommendedProductsPageState extends State<RecommendedProductsPage> {
  static const Color primary = AppColors.primary;
  static const Color accent = AppColors.accent;
  static const Color background = AppColors.background;
  static const Color textColor = AppColors.textPrimary;

  /// Preferred chip order; categories not listed here follow alphabetically.
  static const List<String> _categoryOrder = ['Face', 'Cheeks', 'Eyes', 'Lips'];

  _CatalogStatus _status = _CatalogStatus.loading;
  List<Product> _products = const [];
  String _selectedCategory = 'All';
  int _loadId = 0;

  List<String> get _categories {
    final present = _products.map((p) => p.category).toSet();
    final ordered = [
      ..._categoryOrder.where(present.contains),
      ...(present.difference(_categoryOrder.toSet()).toList()..sort()),
    ];
    return ['All', ...ordered];
  }

  List<Product> get _filteredProducts {
    if (_selectedCategory == 'All') return _products;
    return _products.where((p) => p.category == _selectedCategory).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadCatalog();
    FavoritesService.instance.addListener(_onFavoritesChanged);
    FavoritesService.instance.ensureLoaded().catchError((Object _) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load favorites.')),
      );
    });
  }

  Future<void> _loadCatalog() async {
    final loadId = ++_loadId;
    setState(() => _status = _CatalogStatus.loading);
    try {
      final products = await widget.catalogService.loadProducts();
      if (!mounted || loadId != _loadId) return;
      setState(() {
        _products = products;
        if (_selectedCategory != 'All' &&
            !products.any((p) => p.category == _selectedCategory)) {
          _selectedCategory = 'All';
        }
        _status = _CatalogStatus.loaded;
      });
    } catch (_) {
      if (!mounted || loadId != _loadId) return;
      setState(() => _status = _CatalogStatus.error);
    }
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

  Future<void> _toggleFavorite(Product product) async {
    final favorites = FavoritesService.instance;
    try {
      await favorites.ensureLoaded();
      final map = product.toFavoriteMap();
      final wasFavorite = favorites.isFavoriteProduct(map);
      await favorites.toggleFavorite(map);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              wasFavorite
                  ? '${product.name} removed from favorites'
                  : '${product.name} added to favorites',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update favorites. Please retry.'),
        ),
      );
    }
  }

  void _openProduct(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailsPage.fromProduct(product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inShell = MainShellScope.maybeOf(context) != null;
    final back = MainShellScope.backActionOf(context);
    final heading =
        widget.heading ?? (inShell ? 'Explore' : 'Recommended for You');
    final subheading =
        widget.subheading ??
        (inShell
            ? 'Browse makeup you might love ✨'
            : 'Discover beauty products picked for your next look ✨');

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'GlowAI',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: primary,
            letterSpacing: 1.2,
          ),
        ),
        leading: back.visible
            ? IconButton(
                tooltip: 'Back',
                onPressed: back.onPressed,
                icon: const Icon(Icons.arrow_back_ios_new, color: primary),
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Text(
                heading,
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                subheading,
                style: const TextStyle(fontSize: 14, color: Color(0xFF8C8186)),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_status) {
      case _CatalogStatus.loading:
        return const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        );
      case _CatalogStatus.error:
        return _buildMessage(
          icon: Icons.cloud_off_outlined,
          title: 'Could not load products',
          message: 'Please check your connection and try again.',
          actionLabel: 'Try again',
          onAction: _loadCatalog,
        );
      case _CatalogStatus.loaded:
        break;
    }

    if (_products.isEmpty) {
      return _buildMessage(
        icon: Icons.shopping_bag_outlined,
        title: 'No products yet',
        message: 'New makeup products will appear here.',
      );
    }

    final products = _filteredProducts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 42,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = _selectedCategory == category;

              return ChoiceChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (_) {
                  setState(() {
                    _selectedCategory = category;
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
            '${products.length} ${products.length == 1 ? 'product' : 'products'}',
            style: const TextStyle(fontSize: 14, color: Color(0xFF8C8186)),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: products.isEmpty
              ? _buildMessage(
                  icon: Icons.search_off_outlined,
                  title: 'No products in this category',
                  message: 'Try another category.',
                  actionLabel: 'Show all products',
                  onAction: () => setState(() => _selectedCategory = 'All'),
                )
              : _buildGrid(products),
        ),
      ],
    );
  }

  Widget _buildGrid(List<Product> products) {
    // The photo area flexes; the text block grows with the user's text size.
    final double textScale = MediaQuery.textScalerOf(context)
        .scale(1)
        .clamp(1.0, 1.6)
        .toDouble();

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: products.length,
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 240,
        crossAxisSpacing: 14,
        mainAxisSpacing: 16,
        mainAxisExtent: 150 + 130 * textScale,
      ),
      itemBuilder: (context, index) => _buildProductCard(products[index]),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: accent),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF8C8186)),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final favorites = FavoritesService.instance;
    final map = product.toFavoriteMap();
    final isFavorite = favorites.isFavoriteProduct(map);
    final isPending = favorites.isPending(map);
    final imageUrl = product.imageUrl;

    Widget placeholder() => Center(
      child: Icon(
        product.icon,
        size: 64,
        color: primary.withValues(alpha: 0.55),
      ),
    );

    return Material(
      key: ValueKey('product-card-${product.id}'),
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
                  Positioned.fill(
                    child: ColoredBox(
                      color: Color.alphaBlend(
                        Colors.white.withValues(alpha: 0.55),
                        product.color,
                      ),
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => placeholder(),
                            )
                          : placeholder(),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      child: IconButton(
                        key: ValueKey('favorite-button-${product.id}'),
                        onPressed: isPending
                            ? null
                            : () => _toggleFavorite(product),
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
                        product.category,
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
                    product.brand,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9A8585),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  if (product.shade != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: product.color,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFE8D5DA)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            product.shade!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6F6469),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (product.hasPrice) ...[
                    const SizedBox(height: 6),
                    Text(
                      '\$${product.price!.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
