import 'dart:convert';
import 'package:flutter/services.dart';
import 'aroma_accord.dart';

/// Read-only references from the reviewed catalog export, not store inventory.
class CatalogReference {
  CatalogReference(Map<String, dynamic> json)
    : id = json['id'] as String,
      name = json['name'] as String,
      brand = json['brand'] as String,
      alias = json['catalogAlias'] as String? ?? '',
      gender = json['gender'] as String,
      imageAsset = 'assets/perfumery${json['imagePath']}',
      approved = json['accordsStatus'] == 'approved',
      source = json['sourceCatalog'] as String? ?? '',
      page = json['sourcePage'] as int?,
      brandAliases = List<String>.from(json['brandAliases'] ?? []),
      accords = (json['accords'] as List).map((value) {
        final item = value as Map<String, dynamic>;
        return CatalogAccord(
          slug: item['slug'] as String,
          name: item['name'] as String,
          color: item['color'] as String,
          intensity: (item['intensity'] as num).toInt().clamp(1, 100),
        );
      }).toList()..sort((a, b) => b.intensity.compareTo(a.intensity));

  final String id, name, brand, alias, gender, imageAsset, source;
  final int? page;
  final bool approved;
  final List<String> brandAliases;
  final List<CatalogAccord> accords;

  String get genderLabel => switch (gender) {
    'masculine' => 'Hombre',
    'feminine' => 'Mujer',
    _ => 'Unisex',
  };

  bool matches(String query, String genderFilter, String accordFilter) {
    final text = normalizeCatalogText(
      [name, brand, alias, ...brandAliases].join(' '),
    );
    return text.contains(normalizeCatalogText(query.trim())) &&
        (genderFilter.isEmpty || gender == genderFilter) &&
        (accordFilter.isEmpty ||
            approved && accords.any((a) => a.slug == accordFilter));
  }

  /// Resolve canonical server IDs; never silently discard an unknown accord.
  List<EditableAccord> resolveProfile(List<AromaAccord> master) {
    if (!approved || accords.isEmpty) {
      throw const FormatException('Perfil pendiente de revisión.');
    }
    final bySlug = {for (final item in master) item.slug: item};
    final missing = accords
        .where((a) => !bySlug.containsKey(a.slug))
        .map((a) => a.name)
        .toList();
    if (missing.isNotEmpty) {
      throw FormatException(
        'Faltan acordes en el servidor: ${missing.join(', ')}.',
      );
    }
    return [
      for (var i = 0; i < accords.length; i++)
        EditableAccord(
          accord: bySlug[accords[i].slug]!,
          intensity: accords[i].intensity,
          displayOrder: i + 1,
        ),
    ];
  }

  static Future<List<CatalogReference>> load() async {
    final json =
        jsonDecode(await rootBundle.loadString('assets/perfumery/catalog.json'))
            as Map<String, dynamic>;
    return (json['references'] as List)
        .map((item) => CatalogReference(item as Map<String, dynamic>))
        .toList();
  }
}

class CatalogAccord {
  const CatalogAccord({
    required this.slug,
    required this.name,
    required this.color,
    required this.intensity,
  });
  final String slug, name, color;
  final int intensity;
}

String normalizeCatalogText(String value) {
  var result = value.toLowerCase();
  const accented = 'áéíóúüñ';
  const plain = 'aeiouun';
  for (var i = 0; i < accented.length; i++) {
    result = result.replaceAll(accented[i], plain[i]);
  }
  return result;
}
