import '../core/utils/parsing_utils.dart';

/// Invoice generated for a paid [Order].
///
/// The backend enforces the constraint that only orders with
/// `estado == PAGADA` can produce a factura. The factura is a 1:1 with the
/// venta and stores a snapshot of the customer's identity at issue time
/// (nombre + cédula) so historic invoices remain accurate even if the
/// cliente record is later updated.
class Invoice {
  const Invoice({
    required this.id,
    required this.ventaId,
    required this.numeroFactura,
    required this.nombreCliente,
    required this.subtotal,
    required this.impuesto,
    required this.total,
    this.cedulaCliente,
    this.fechaEmision,
  });

  final int id;
  final int ventaId;
  final String numeroFactura;
  final String nombreCliente;
  final String? cedulaCliente;
  final double subtotal;
  final double impuesto;
  final double total;
  final DateTime? fechaEmision;

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: asInt(json['id']),
      ventaId: asInt(json['ventaId']),
      numeroFactura: asString(json['numeroFactura']),
      nombreCliente: asString(json['nombreCliente']),
      cedulaCliente: json['cedulaCliente'] as String?,
      subtotal: asDouble(json['subtotal']),
      impuesto: asDouble(json['impuesto']),
      total: asDouble(json['total']),
      fechaEmision: json['fechaEmision'] is String
          ? DateTime.tryParse(json['fechaEmision'] as String)
          : null,
    );
  }
}
