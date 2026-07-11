import '../core/utils/parsing_utils.dart';
import 'brand.dart';
import 'category.dart';
import 'inventory.dart';

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.active,
    required this.categoryId,
    required this.brandId,
    required this.brand,
    required this.category,
    required this.inventory,
  });

  final int id;
  final String name;
  final String code;
  final String description;
  final double price;
  final String? imageUrl;
  final bool active;
  final int categoryId;
  final int brandId;
  final Brand brand;
  final Category category;
  final Inventory? inventory;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: asInt(json['id']),
      name: asString(json['nombre']),
      code: asString(json['codigo']),
      description: asString(json['descripcion']),
      price: asDouble(json['precio']),
      imageUrl: json['imagenUrl'] as String?,
      active: json['activo'] == true,
      categoryId: asInt(json['categoriaId']),
      brandId: asInt(json['marcaId']),
      brand: Brand.fromJson(
        (json['marca'] as Map?)?.cast<String, dynamic>() ?? {},
      ),
      category: Category.fromJson(
        (json['categoria'] as Map?)?.cast<String, dynamic>() ?? {},
      ),
      inventory: json['inventario'] is Map
          ? Inventory.fromJson(
              (json['inventario'] as Map).cast<String, dynamic>(),
            )
          : null,
    );
  }
}
