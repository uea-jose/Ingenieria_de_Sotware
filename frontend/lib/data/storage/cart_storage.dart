import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

import '../../config/storage_keys.dart';
import '../../core/utils/parsing_utils.dart';

class CartStorage {
  static Map<int, int> load() {
    final savedCart = html.window.localStorage[cartStorageKey];
    if (savedCart == null || savedCart.isEmpty) return {};

    try {
      final decoded = jsonDecode(savedCart);
      if (decoded is! Map) return {};

      final quantities = <int, int>{};
      for (final entry in decoded.entries) {
        final productId = int.tryParse(entry.key.toString());
        final quantity = asInt(entry.value);
        if (productId != null && quantity > 0) {
          quantities[productId] = quantity;
        }
      }

      return quantities;
    } catch (_) {
      clear();
      return {};
    }
  }

  static void save(Map<int, int> quantities) {
    if (quantities.isEmpty) {
      clear();
      return;
    }

    html.window.localStorage[cartStorageKey] = jsonEncode(
      quantities.map(
        (productId, quantity) => MapEntry('$productId', quantity),
      ),
    );
  }

  static void clear() {
    html.window.localStorage.remove(cartStorageKey);
  }
}
