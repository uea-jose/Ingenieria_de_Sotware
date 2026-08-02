import '../core/utils/parsing_utils.dart';

class AromaAccord {
  const AromaAccord({
    required this.id,
    required this.name,
    required this.slug,
    required this.colorHex,
    required this.textColorHex,
    required this.aliases,
  });

  final int id;
  final String name;
  final String slug;
  final String colorHex;
  final String textColorHex;
  final List<String> aliases;

  factory AromaAccord.fromJson(Map<String, dynamic> json) {
    return AromaAccord(
      id: asInt(json['id']),
      name: asString(json['nombre']),
      slug: asString(json['slug']),
      colorHex: asString(json['colorHex']),
      textColorHex: asString(json['colorTextoHex']),
      aliases: (json['alias'] as List? ?? const [])
          .map((item) => asString(item))
          .where((item) => item.isNotEmpty)
          .toList(),
    );
  }
}

class EditableAccord {
  const EditableAccord({
    required this.accord,
    required this.intensity,
    required this.displayOrder,
    this.copiedFromReference = false,
  });

  final AromaAccord accord;
  final int intensity;
  final int displayOrder;
  final bool copiedFromReference;

  factory EditableAccord.fromJson(Map<String, dynamic> json) {
    return EditableAccord(
      accord: AromaAccord.fromJson(
        (json['acorde'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      intensity: asInt(json['intensidad']).clamp(1, 100),
      displayOrder: asInt(json['ordenVisual']),
      copiedFromReference: json['copiadoDeReferencia'] == true,
    );
  }

  EditableAccord copyWith({
    int? intensity,
    int? displayOrder,
    bool? copiedFromReference,
  }) {
    return EditableAccord(
      accord: accord,
      intensity: intensity ?? this.intensity,
      displayOrder: displayOrder ?? this.displayOrder,
      copiedFromReference: copiedFromReference ?? this.copiedFromReference,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'acordeId': accord.id,
      'intensidad': intensity,
      'copiadoDeReferencia': copiedFromReference,
    };
  }
}
