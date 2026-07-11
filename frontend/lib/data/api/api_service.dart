import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
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
