import '../core/utils/parsing_utils.dart';

class Inventory {
  const Inventory({
    required this.stock,
    required this.minimumStock,
    required this.location,
  });

  final int stock;
  final int minimumStock;
  final String location;

  factory Inventory.fromJson(Map<String, dynamic> json) {
    return Inventory(
      stock: asInt(json['stock']),
      minimumStock: asInt(json['stockMinimo']),
      location: asString(json['ubicacion']),
    );
  }
}
