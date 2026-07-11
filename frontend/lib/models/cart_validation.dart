import '../core/utils/parsing_utils.dart';

class CartValidation {
  const CartValidation({
    required this.valid,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.taxPercent,
    required this.stockAlerts,
    required this.errors,
  });

  final bool valid;
  final double subtotal;
  final double tax;
  final double total;
  final double taxPercent;
  final List<String> stockAlerts;
  final List<String> errors;

  factory CartValidation.fromJson(Map<String, dynamic> json) {
    final alerts = json['alertasStock'];
    final errors = json['errores'];

    return CartValidation(
      valid: json['valido'] == true,
      subtotal: asDouble(json['subtotal']),
      tax: asDouble(json['impuesto']),
      total: asDouble(json['total']),
      taxPercent: asDouble(json['porcentajeImpuesto']),
      stockAlerts: alerts is List
          ? alerts
                .map((alert) {
                  if (alert is Map) return asString(alert['mensaje']);
                  return asString(alert);
                })
                .where((message) => message.isNotEmpty)
                .toList()
          : const [],
      errors: errors is List
          ? errors.map(asString).where((message) => message.isNotEmpty).toList()
          : const [],
    );
  }
}
