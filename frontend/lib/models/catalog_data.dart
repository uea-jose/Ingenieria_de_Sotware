import 'brand.dart';
import 'category.dart';
import 'product.dart';

class CatalogData {
  const CatalogData({
    required this.products,
    required this.categories,
    required this.brands,
  });

  final List<Product> products;
  final List<Category> categories;
  final List<Brand> brands;

  factory CatalogData.empty() {
    return const CatalogData(products: [], categories: [], brands: []);
  }
}
