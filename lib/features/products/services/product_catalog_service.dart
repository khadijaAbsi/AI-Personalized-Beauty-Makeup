import '../data/mock_product_catalog.dart';
import '../models/product.dart';

/// Where the Explore screen gets its products.
///
/// Today this is [MockProductCatalogService]. When PSGAN is integrated, add a
/// second implementation that returns the products recommended for the user's
/// generated look (for example from a Supabase table or the AI backend) and
/// pass it to `RecommendedProductsPage`. Favorites do not need to change:
/// they only depend on [Product.toFavoriteMap].
abstract interface class ProductCatalogService {
  Future<List<Product>> loadProducts();
}

/// Serves the built-in mock catalog. Holds no user data.
class MockProductCatalogService implements ProductCatalogService {
  const MockProductCatalogService();

  @override
  Future<List<Product>> loadProducts() async => mockProductCatalog;
}
