import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../models/accord_profile.dart';
import '../../models/aroma_accord.dart';
import '../../models/brand.dart';
import '../../models/perfume_reference.dart';
import '../../models/product.dart';

class CatalogApiException implements Exception {
  const CatalogApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CatalogAdminApi {
  String? _token;

  bool get isAuthenticated => _token != null;

  Future<void> login({required String email, required String password}) async {
    final json = await _request(
      '/auth/login',
      method: 'POST',
      body: {'correo': email.trim(), 'contrasena': password},
      authenticated: false,
    );
    final token = json['token']?.toString();

    if (token == null || token.isEmpty) {
      throw const CatalogApiException(
        'El servidor no devolvió un token de acceso.',
      );
    }

    _token = token;
  }

  void logout() {
    _token = null;
  }

  Future<List<AromaAccord>> loadAccords() async {
    final json = await _request('/acordes', authenticated: false);
    return _list(json).map(AromaAccord.fromJson).toList(growable: false);
  }

  Future<List<Brand>> loadBrands() async {
    final json = await _request('/marcas', authenticated: false);
    return _list(json).map(Brand.fromJson).toList(growable: false);
  }

  Future<List<Product>> loadProducts() async {
    final json = await _request('/productos', authenticated: false);
    return _list(json).map(Product.fromJson).toList(growable: false);
  }

  Future<List<PerfumeReference>> loadReferences(int brandId) async {
    final json = await _request(
      '/marcas/$brandId/referencias',
      authenticated: false,
    );
    return _list(json).map(PerfumeReference.fromJson).toList(growable: false);
  }

  Future<AccordProfile> loadReferenceProfile(int referenceId) async {
    final json = await _request(
      '/referencias/$referenceId/acordes',
      authenticated: false,
    );
    return AccordProfile.fromReferenceResponse(json);
  }

  Future<AccordProfile> loadProductProfile(int productId) async {
    final json = await _request(
      '/productos/$productId/acordes',
      authenticated: false,
    );
    return AccordProfile.fromProductResponse(json);
  }

  Future<AccordProfile> assignReference({
    required int productId,
    required int referenceId,
  }) async {
    await _request(
      '/productos/$productId',
      method: 'PUT',
      body: {'referenciaId': referenceId},
    );
    return loadProductProfile(productId);
  }

  Future<AccordProfile> saveProductProfile({
    required int productId,
    required List<EditableAccord> accords,
  }) async {
    final json = await _request(
      '/productos/$productId/acordes',
      method: 'PUT',
      body: {'acordes': accords.map((item) => item.toJson()).toList()},
    );
    return AccordProfile.fromProductResponse(json);
  }

  Future<AccordProfile> restoreProductProfile(int productId) async {
    final json = await _request(
      '/productos/$productId/restaurar-acordes',
      method: 'POST',
      body: const {},
    );
    return AccordProfile.fromProductResponse(json);
  }

  Future<Map<String, dynamic>> _request(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    if (authenticated && _token == null) {
      throw const CatalogApiException(
        'Inicia sesión para modificar el catálogo.',
      );
    }

    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (authenticated) 'Authorization': 'Bearer $_token',
    };
    final uri = Uri.parse('$apiBaseUrl$path');
    late http.Response response;

    switch (method) {
      case 'POST':
        response = await http.post(
          uri,
          headers: headers,
          body: jsonEncode(body),
        );
      case 'PUT':
        response = await http.put(
          uri,
          headers: headers,
          body: jsonEncode(body),
        );
      default:
        response = await http.get(uri, headers: headers);
    }

    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);
    final json = decoded is Map
        ? decoded.cast<String, dynamic>()
        : <String, dynamic>{};

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = json['error'];
      final message = error is Map
          ? error['mensaje']?.toString() ?? error['message']?.toString()
          : error?.toString();
      throw CatalogApiException(
        message ?? 'Error HTTP ${response.statusCode}.',
      );
    }

    return json;
  }

  static List<Map<String, dynamic>> _list(Map<String, dynamic> json) {
    final value = json['datos'];
    if (value is! List) return const [];

    return value
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }
}
