import '../core/utils/parsing_utils.dart';

class Brand {
  const Brand({
    required this.id,
    required this.name,
    required this.country,
    required this.description,
    required this.active,
  });

  final int id;
  final String name;
  final String country;
  final String description;
  final bool active;

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      id: asInt(json['id']),
      name: asString(json['nombre']),
      country: asString(json['paisOrigen']),
      description: asString(json['descripcion']),
      active: json['activo'] != false,
    );
  }
}
