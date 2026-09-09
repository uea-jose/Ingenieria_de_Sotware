import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../models/aroma_accord.dart';
import '../../models/brand.dart';
import '../../models/cart_validation.dart';
import '../../models/catalog_data.dart';
import '../../models/category.dart';
import '../../models/product.dart';

class ApiService {
  static Future<CatalogData> loadCatalog() async {
    final responses = await Future.wait([
      _getJson('$apiBaseUrl/productos'),
      _getJson('$apiBaseUrl/categorias'),
      _getJson('$apiBaseUrl/marcas'),
    ]);

    return CatalogData(
      products: _listFrom(responses[0]).map(Product.fromJson).toList(),
      categories: _listFrom(responses[1]).map(Category.fromJson).toList(),
      brands: _listFrom(responses[2]).map(Brand.fromJson).toList(),
    );
  }

  static Future<CartValidation> validateCart(Map<int, int> quantities) async {
    final items = quantities.entries
        .map((entry) => {'productoId': entry.key, 'cantidad': entry.value})
        .toList();
    final json = await _postJson('$apiBaseUrl/carrito/validar', {
      'items': items,
    });
    return CartValidation.fromJson(json);
  }

  static Future<Product> loadProductById(int productId) async {
    final json = await _getJson('$apiBaseUrl/productos/$productId');
    final value = json['dato'] ?? json['data'] ?? json;

    if (value is Map<String, dynamic>) {
      return Product.fromJson(value);
    }

    throw Exception('Producto no encontrado.');
  }

  /// Returns the full master accord catalogue.
  static Future<List<AromaAccord>> loadAccords() async {
    final json = await _getJson('$apiBaseUrl/acordes');
    return _listFrom(json).map(AromaAccord.fromJson).toList();
  }

  /// Returns products whose accord profiles match [accordIntensities].
  /// Falls back to the full product list filtered client-side when the
  /// backend has no dedicated accord-search endpoint.
  static Future<List<Product>> searchByAccords(
    Map<String, int> accordIntensities,
  ) async {
    if (accordIntensities.isEmpty) return const [];
    // Build query string: ?slug1=intensity1&slug2=intensity2…
    final params = accordIntensities.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${e.value}')
        .join('&');
    try {
      final json = await _getJson('$apiBaseUrl/productos?$params');
      return _listFrom(json).map(Product.fromJson).toList();
    } catch (_) {
      // If the backend doesn't support accord filtering, return all products
      // so the page is still useful during development.
      final json = await _getJson('$apiBaseUrl/productos');
      return _listFrom(json).map(Product.fromJson).toList();
    }
  }

  static Future<Map<String, dynamic>> _getJson(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error HTTP ${response.statusCode}: ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> _postJson(
    String url,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      Uri.parse(url),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error HTTP ${response.statusCode}: ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static List<Map<String, dynamic>> _listFrom(Map<String, dynamic> json) {
    final value = json['datos'] ?? json['data'] ?? [];
    if (value is List) {
      return value.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }
}
