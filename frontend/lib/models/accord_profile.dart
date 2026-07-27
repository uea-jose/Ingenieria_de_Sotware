import '../core/utils/parsing_utils.dart';
import 'aroma_accord.dart';

class AccordProfile {
  const AccordProfile({
    required this.accords,
    required this.entityId,
    required this.entityName,
    required this.imageUrl,
    required this.referenceId,
  });

  final List<EditableAccord> accords;
  final int entityId;
  final String entityName;
  final String imageUrl;
  final int? referenceId;

  factory AccordProfile.fromProductResponse(Map<String, dynamic> json) {
    final product =
        (json['producto'] as Map?)?.cast<String, dynamic>() ?? const {};

    return AccordProfile(
      accords: _accordsFrom(json),
      entityId: asInt(product['id']),
      entityName: asString(product['nombre']),
      imageUrl: asString(product['imagenUrl']),
      referenceId: product['referenciaId'] == null
          ? null
          : asInt(product['referenciaId']),
    );
  }

  factory AccordProfile.fromReferenceResponse(Map<String, dynamic> json) {
    final reference =
        (json['referencia'] as Map?)?.cast<String, dynamic>() ?? const {};

    return AccordProfile(
      accords: _accordsFrom(json),
      entityId: asInt(reference['id']),
      entityName: asString(reference['nombre']),
      imageUrl: '',
      referenceId: asInt(reference['id']),
    );
  }

  static List<EditableAccord> _accordsFrom(Map<String, dynamic> json) {
    return (json['datos'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => EditableAccord.fromJson(item.cast<String, dynamic>()))
        .toList();
  }
}
