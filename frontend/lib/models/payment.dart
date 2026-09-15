import '../core/utils/parsing_utils.dart';

/// Payment attempt registered against an [Order].
///
/// - `metodo`: `EFECTIVO | TARJETA | TRANSFERENCIA | OTRO`
/// - `estado`: `PENDIENTE | PAGADO | FALLIDO`
///
/// The backend stores the amount as a decimal string; we parse it into a
/// `double` on ingest. `fechaPago` is only set when the payment was approved.
class Payment {
  const Payment({
    required this.id,
    required this.ventaId,
    required this.metodo,
    required this.estado,
    required this.monto,
    this.fechaPago,
  });

  final int id;
  final int ventaId;
  final String metodo;
  final String estado;
  final double monto;
  final DateTime? fechaPago;

  bool get isApproved => estado == 'PAGADO';
  bool get isPending => estado == 'PENDIENTE';
  bool get isFailed => estado == 'FALLIDO';

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: asInt(json['id']),
      ventaId: asInt(json['ventaId']),
      metodo: asString(json['metodo']),
      estado: asString(json['estado']),
      monto: asDouble(json['monto']),
      fechaPago: json['fechaPago'] is String
          ? DateTime.tryParse(json['fechaPago'] as String)
          : null,
    );
  }
}
