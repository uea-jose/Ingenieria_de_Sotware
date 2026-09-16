import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../models/invoice.dart';
import '../../models/order.dart';
import 'auth_service.dart';

/// Payload returned by `POST /pagos/:id/confirmar`. The backend responds
/// with `{pago, venta, alertasStock, mensaje}` — we surface the updated
/// venta so the caller can replace the row in place, plus the stock
/// alerts to render as inline warnings.
class ConfirmPaymentResult {
  const ConfirmPaymentResult({
    required this.order,
    required this.mensaje,
    this.alertasStock = const [],
  });

  final Order order;
  final String mensaje;
  final List<String> alertasStock;
}

/// Payload returned by `POST /facturas`. Backend responds with
/// `{dato: factura, mensaje}`.
class GenerateInvoiceResult {
  const GenerateInvoiceResult({required this.invoice, required this.mensaje});

  final Invoice invoice;
  final String mensaje;
}

/// Client for the admin sales panel. All methods require a token
/// belonging to a user with rol `Administrador` or `Vendedor` (the
/// backend enforces the role in `pagos.routes.js`, `facturas.routes.js`
/// and `ventas.routes.js`). The UI layer must gate the panel entrance
/// on `isAdmin || isVendedor` so Bodeguero doesn't hit a 403.
///
/// The client mirrors the transport style of [OrdersApi]: it decodes
/// the JSON body, maps 4xx errors to [AuthException] and lets the
/// caller display the human-readable message.
class AdminSalesApi {
  AdminSalesApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// `GET /api/ventas` — returns every sale, newest first, with the six
  /// snapshot columns embedded in each row and the initial payment
  /// preloaded (created by `POST /ventas` during checkout).
  Future<List<Order>> loadSales({required String token}) async {
    final json = await _request('/ventas', token: token);
    final raw = json['datos'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => Order.fromJson(item.cast<String, dynamic>()))
        .toList(growable: false);
  }

  /// `POST /api/pagos/:id/confirmar`. The backend approves the existing
  /// PENDIENTE payment without re-asking for the method — it reads the
  /// original `metodo` from the payment record created at checkout.
  ///
  /// Efectos:
  /// - Pago pasa de PENDIENTE a PAGADO con `fechaPago = now`.
  /// - Inventario descontado por cada detalle de la venta.
  /// - `MovimientoInventario` creado con motivo "Salida automatica…".
  /// - Venta pasa a estado PAGADA.
  Future<ConfirmPaymentResult> confirmPayment({
    required String token,
    required int paymentId,
  }) async {
    final json = await _request(
      '/pagos/$paymentId/confirmar',
      method: 'POST',
      token: token,
      body: const {},
    );

    final ventaJson = json['venta'];
    if (ventaJson is! Map) {
      throw const AuthException(
        'El servidor no devolvió la venta actualizada.',
      );
    }

    final alertasRaw = json['alertasStock'];
    final alertas = <String>[];
    if (alertasRaw is List) {
      for (final entry in alertasRaw) {
        if (entry is Map) {
          final mensaje = entry['mensaje']?.toString();
          if (mensaje != null && mensaje.isNotEmpty) alertas.add(mensaje);
        }
      }
    }

    return ConfirmPaymentResult(
      order: Order.fromJson(ventaJson.cast<String, dynamic>()),
      mensaje: json['mensaje']?.toString() ?? 'Pago confirmado.',
      alertasStock: alertas,
    );
  }

  /// `POST /api/facturas`. The backend enforces that the sale is
  /// `PAGADA` and has no factura yet; both checks return 409.
  Future<GenerateInvoiceResult> generateInvoice({
    required String token,
    required int saleId,
  }) async {
    final json = await _request(
      '/facturas',
      method: 'POST',
      token: token,
      body: {'ventaId': saleId},
    );

    final facturaJson = json['dato'];
    if (facturaJson is! Map) {
      throw const AuthException('El servidor no devolvió la factura generada.');
    }

    return GenerateInvoiceResult(
      invoice: Invoice.fromJson(facturaJson.cast<String, dynamic>()),
      mensaje: json['mensaje']?.toString() ?? 'Factura generada.',
    );
  }

  void dispose() {
    _client.close();
  }

  Future<Map<String, dynamic>> _request(
    String path, {
    required String token,
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$apiBaseUrl$path');
    final headers = <String, String>{
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
      if (body != null) 'Content-Type': 'application/json',
    };

    late http.Response response;
    try {
      switch (method) {
        case 'POST':
          response = await _client.post(
            uri,
            headers: headers,
            body: jsonEncode(body ?? const {}),
          );
        case 'PUT':
          response = await _client.put(
            uri,
            headers: headers,
            body: jsonEncode(body ?? const {}),
          );
        default:
          response = await _client.get(uri, headers: headers);
      }
    } on Object catch (error) {
      throw AuthException(
        'No se pudo contactar el servidor: $error',
        statusCode: 0,
      );
    }

    final decoded = response.body.isEmpty
        ? const <String, dynamic>{}
        : _safeDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(
        _extractErrorMessage(decoded, response.statusCode),
        statusCode: response.statusCode,
      );
    }

    return decoded;
  }

  static Map<String, dynamic> _safeDecode(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return decoded.cast<String, dynamic>();
    } catch (_) {}
    return const {};
  }

  static String _extractErrorMessage(Map<String, dynamic> json, int status) {
    final err = json['error'];
    if (err is String && err.trim().isNotEmpty) return err.trim();
    if (err is Map) {
      final msg = err['mensaje'] ?? err['message'];
      if (msg != null) return msg.toString();
    }
    final detalles = json['detalles'];
    if (detalles is List && detalles.isNotEmpty) {
      return detalles.join(' ');
    }
    switch (status) {
      case 400:
        return 'Los datos enviados no son válidos.';
      case 401:
        return 'Sesión expirada. Vuelve a iniciar sesión.';
      case 403:
        return 'No tienes permisos para esta acción.';
      case 404:
        return 'Recurso no encontrado.';
      case 409:
        return 'Conflicto: el recurso no puede procesarse en su estado actual.';
      default:
        return 'Error HTTP $status.';
    }
  }
}
