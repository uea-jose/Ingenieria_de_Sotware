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
    // Delivery snapshot — captured at checkout time and never mutated.
    // See `model Venta` in backend/prisma/schema.prisma. Every field is
    // nullable so pre-migration orders keep loading without crashing.
    this.direccionEntrega,
    this.ciudadEntrega,
    this.referenciaEntrega,
    this.telefonoContacto,
    this.latitudEntrega,
    this.longitudEntrega,
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

  final String? direccionEntrega;
  final String? ciudadEntrega;
  final String? referenciaEntrega;
  final String? telefonoContacto;
  final double? latitudEntrega;
  final double? longitudEntrega;

  /// True cuando la venta trae los 6 campos snapshot completos (o al
  /// menos los tres textuales obligatorios). Se usa en `/mis-pedidos`
  /// para decidir si vale la pena renderizar el bloque de dirección.
  bool get tieneSnapshotEntrega =>
      (direccionEntrega?.isNotEmpty ?? false) ||
      (ciudadEntrega?.isNotEmpty ?? false) ||
      (telefonoContacto?.isNotEmpty ?? false);

  bool get isPending => estado == 'PENDIENTE';
  bool get isPaid => estado == 'PAGADA';
  bool get isCancelled => estado == 'CANCELADA';

  /// Total quantity across all line items (used for headline "N unidades").
  int get itemsCount => items.fold(0, (total, item) => total + item.cantidad);

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
      items: _asList(
        json['detalles'],
      ).map(OrderItem.fromJson).toList(growable: false),
      pagos: _asList(
        json['pagos'],
      ).map(Payment.fromJson).toList(growable: false),
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
      // Delivery snapshot — server sends `null` for pre-migration rows
      // and for rows created without a snapshot payload; preservamos el
      // null para que el UI pueda mostrar "sin dirección registrada".
      direccionEntrega: _asOptString(json['direccionEntrega']),
      ciudadEntrega: _asOptString(json['ciudadEntrega']),
      referenciaEntrega: _asOptString(json['referenciaEntrega']),
      telefonoContacto: _asOptString(json['telefonoContacto']),
      latitudEntrega: _asOptDouble(json['latitudEntrega']),
      longitudEntrega: _asOptDouble(json['longitudEntrega']),
    );
  }

  static String? _asOptString(Object? value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }

  static double? _asOptDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      return double.tryParse(trimmed);
    }
    return null;
  }

  static List<Map<String, dynamic>> _asList(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }
}
