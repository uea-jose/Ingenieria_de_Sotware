import '../core/utils/parsing_utils.dart';
import 'brand.dart';
import 'category.dart';

/// Single line item inside an [Order] (a "detalle de venta" in the backend).
///
/// The backend includes a nested `producto` object when it returns
/// order detail (with `marca` and `categoria`). We flatten the fields we
/// actually render — name, brand, image URL — so the UI can consume them
/// without null-safety noise.
class OrderItem {
  const OrderItem({
    required this.id,
    required this.productoId,
    required this.cantidad,
    required this.precioUnitario,
    required this.total,
    this.productoNombre = '',
    this.productoImagenUrl,
    this.marca,
    this.categoria,
  });

  final int id;
  final int productoId;
  final int cantidad;
  final double precioUnitario;
  final double total;
  final String productoNombre;
  final String? productoImagenUrl;
  final Brand? marca;
  final Category? categoria;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final producto = json['producto'];
    return OrderItem(
      id: asInt(json['id']),
      productoId: asInt(json['productoId']),
      cantidad: asInt(json['cantidad']),
      precioUnitario: asDouble(json['precioUnitario']),
      total: asDouble(json['total']),
      productoNombre: producto is Map
          ? asString(producto['nombre'])
          : '',
      productoImagenUrl: producto is Map
          ? producto['imagenUrl'] as String?
          : null,
      marca: producto is Map && producto['marca'] is Map
          ? Brand.fromJson((producto['marca'] as Map).cast<String, dynamic>())
          : null,
      categoria: producto is Map && producto['categoria'] is Map
          ? Category.fromJson(
              (producto['categoria'] as Map).cast<String, dynamic>(),
            )
          : null,
    );
  }
}
