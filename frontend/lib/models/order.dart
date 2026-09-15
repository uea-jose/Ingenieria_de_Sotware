import '../core/utils/parsing_utils.dart';
import 'invoice.dart';
import 'order_item.dart';
import 'payment.dart';

/// Sales order ("venta" in the backend). Snapshot of a cart that was
/// converted into a transactional record.
///
/// Estado (state machine):
///   PENDIENTE   → recién creada, aún no pagada.
///   PAGADA      → un pago con estado PAGADO llegó a coincidir con el total.
///                 El inventario ya fue descontado.
///   CANCELADA   → la venta fue anulada manualmente.
///
/// The frontend maps the state to a display label + color at render time.
class Order {
  const Order({
    required this.id,
    required this.clienteId,
    required this.usuarioId,
    required this.estado,
    required this.subtotal,
    required this.impuesto,
    required this.total,
    required this.items,
    this.pagos = const [],
    this.factura,
    this.fechaCreacion,
    this.clienteNombre,
    this.clienteCorreo,
  });

  final int id;
  final int clienteId;
  final int usuarioId;
  final String estado;
  final double subtotal;
  final double impuesto;
  final double total;
  final List<OrderItem> items;
  final List<Payment> pagos;
  final Invoice? factura;
  final DateTime? fechaCreacion;
  final String? clienteNombre;
  final String? clienteCorreo;

  bool get isPending => estado == 'PENDIENTE';
  bool get isPaid => estado == 'PAGADA';
  bool get isCancelled => estado == 'CANCELADA';

  /// Total quantity across all line items (used for headline "N unidades").
  int get itemsCount =>
      items.fold(0, (total, item) => total + item.cantidad);

  factory Order.fromJson(Map<String, dynamic> json) {
    final cliente = json['cliente'];
    return Order(
      id: asInt(json['id']),
      clienteId: asInt(json['clienteId']),
      usuarioId: asInt(json['usuarioId']),
      estado: asString(json['estado']),
      subtotal: asDouble(json['subtotal']),
      impuesto: asDouble(json['impuesto']),
      total: asDouble(json['total']),
      items: _asList(json['detalles'])
          .map(OrderItem.fromJson)
          .toList(growable: false),
      pagos: _asList(json['pagos'])
          .map(Payment.fromJson)
          .toList(growable: false),
      factura: json['factura'] is Map
          ? Invoice.fromJson((json['factura'] as Map).cast<String, dynamic>())
          : null,
      fechaCreacion: json['createdAt'] is String
          ? DateTime.tryParse(json['createdAt'] as String)
          : json['fechaCreacion'] is String
                ? DateTime.tryParse(json['fechaCreacion'] as String)
                : null,
      clienteNombre: cliente is Map
          ? '${asString(cliente['nombres'])} ${asString(cliente['apellidos'])}'
                .trim()
          : null,
      clienteCorreo: cliente is Map ? cliente['correo'] as String? : null,
    );
  }

  static List<Map<String, dynamic>> _asList(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }
}
