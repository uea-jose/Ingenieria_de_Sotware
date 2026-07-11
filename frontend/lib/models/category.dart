import '../core/utils/parsing_utils.dart';

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.description,
    required this.active,
  });

  final int id;
  final String name;
  final String description;
  final bool active;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: asInt(json['id']),
      name: asString(json['nombre']),
      description: asString(json['descripcion']),
      active: json['activo'] != false,
    );
  }
}
