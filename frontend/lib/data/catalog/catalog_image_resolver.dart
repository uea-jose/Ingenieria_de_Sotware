import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Singleton that loads the bundled perfumery catalog once and answers
/// "give me an image asset path for a product named X of brand Y".
///
/// The catalog ships with 634 references and each has a real perfume photo
/// under `assets/perfumery/catalog-suggestions/...`. When one of our own
/// products lacks an `imagenUrl` we try to match it against the catalog by
/// normalised name + brand so the storefront never shows an empty card.
///
/// Usage:
/// ```dart
/// await CatalogImageResolver.instance.ensureLoaded();
/// final path = CatalogImageResolver.instance.findAsset(
///   name: 'Bleu de Chanel',
///   brand: 'Chanel',
/// );
/// ```
class CatalogImageResolver {
  CatalogImageResolver._();
  static final CatalogImageResolver instance = CatalogImageResolver._();

  static const _catalogAsset = 'assets/perfumery/catalog.json';

  bool _loaded = false;
  Future<void>? _loading;

  /// name+brand key → asset path. Populated on first load, then read O(1).
  final Map<String, String> _byNameAndBrand = <String, String>{};

  /// name-only key → asset path (used as a weaker second-chance match).
  final Map<String, String> _byName = <String, String>{};

  /// Kicks off the one-time load. Safe to call many times.
  Future<void> ensureLoaded() {
    if (_loaded) return Future.value();
    return _loading ??= _load();
  }

  Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString(_catalogAsset);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final refs = (json['references'] as List?) ?? const [];

      for (final entry in refs) {
        if (entry is! Map) continue;
        final ref = entry.cast<String, dynamic>();
        final rawName = ref['name'] as String?;
        final alias = ref['catalogAlias'] as String?;
        final brand = ref['brand'] as String?;
        final imagePath = ref['imagePath'] as String?;
        if (rawName == null || brand == null || imagePath == null) continue;

        final asset = 'assets/perfumery$imagePath';
        final names = <String>{
          rawName,
          if (alias != null && alias.isNotEmpty) alias,
        };

        for (final n in names) {
          final normName = _normalize(n);
          final normBrand = _normalize(brand);
          if (normName.isEmpty || normBrand.isEmpty) continue;

          // Prefer the FIRST occurrence per key (do not overwrite).
          _byNameAndBrand.putIfAbsent('$normName|$normBrand', () => asset);
          _byName.putIfAbsent(normName, () => asset);
        }
      }
      _loaded = true;
    } catch (_) {
      // Silent — resolver simply returns null and callers show the logo
      // placeholder. Never crash the storefront over a missing catalog.
      _loaded = true;
    } finally {
      _loading = null;
    }
  }

  /// Returns an `assets/perfumery/...` path if the product can be matched
  /// against the reference catalog, otherwise `null`. Cheap and synchronous;
  /// call [ensureLoaded] once before the first paint.
  String? findAsset({required String name, required String brand}) {
    if (!_loaded) return null;
    final normName = _normalize(name);
    final normBrand = _normalize(brand);
    if (normName.isEmpty) return null;

    // 1) Exact match by name + brand.
    final combo = _byNameAndBrand['$normName|$normBrand'];
    if (combo != null) return combo;

    // 2) Try trimming common perfume suffixes ("eau de parfum", "edt", …)
    //    off the product name and retry.
    final trimmed = _stripCommonSuffixes(normName);
    if (trimmed != normName) {
      final combo2 = _byNameAndBrand['$trimmed|$normBrand'];
      if (combo2 != null) return combo2;
      final nameOnly2 = _byName[trimmed];
      if (nameOnly2 != null) return nameOnly2;
    }

    // 3) Weakest: name-only match (ignoring brand). Better than empty card.
    return _byName[normName];
  }

  // ── Normalisation helpers ───────────────────────────────────────────────

  static String _normalize(String value) {
    var r = value.toLowerCase().trim();
    const accented = 'áéíóúüñàèìòùâêîôûäëïöç';
    const plain = 'aeiouunaeiouaeiouaeioc';
    for (var i = 0; i < accented.length; i++) {
      r = r.replaceAll(accented[i], plain[i]);
    }
    // Collapse everything non-alphanumeric to a single space, then trim.
    r = r.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
    r = r.replaceAll(RegExp(r'\s+'), ' ');
    return r;
  }

  static String _stripCommonSuffixes(String normalized) {
    const suffixes = [
      ' eau de parfum intense',
      ' eau de parfum',
      ' eau de toilette',
      ' eau de cologne',
      ' eau fraiche',
      ' parfum intense',
      ' parfum',
      ' extrait',
      ' intense',
      ' edp',
      ' edt',
    ];
    var out = normalized;
    for (final s in suffixes) {
      if (out.endsWith(s)) {
        out = out.substring(0, out.length - s.length).trim();
        break;
      }
    }
    return out;
  }
}
