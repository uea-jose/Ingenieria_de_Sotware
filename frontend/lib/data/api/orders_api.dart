import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../models/order.dart';
import 'auth_service.dart';

/// Item payload accepted by `POST /ventas`.
class OrderItemDraft {
  const OrderItemDraft({required this.productoId, required this.cantidad});

  final int productoId;
  final int cantidad;

  Map<String, dynamic> toJson() => {
    'productoId': productoId,
    'cantidad': cantidad,
  };
}

/// Delivery snapshot to persist alongside the sale row. Mirrors the six
/// nullable columns added to `model Venta` (see schema.prisma). The
/// backend already accepts nulls, so callers can send just the required
/// fields on new sales and skip lat/lng when the user rejected GPS.
class DeliverySnapshotDraft {
  const DeliverySnapshotDraft({
    this.direccionEntrega,
    this.ciudadEntrega,
    this.referenciaEntrega,
    this.telefonoContacto,
    this.latitudEntrega,
    this.longitudEntrega,
  });

  final String? direccionEntrega;
  final String? ciudadEntrega;
  final String? referenciaEntrega;
  final String? telefonoContacto;
  final double? latitudEntrega;
  final double? longitudEntrega;

  bool get isEmpty =>
      (direccionEntrega == null || direccionEntrega!.trim().isEmpty) &&
      (ciudadEntrega == null || ciudadEntrega!.trim().isEmpty) &&
      (referenciaEntrega == null || referenciaEntrega!.trim().isEmpty) &&
      (telefonoContacto == null || telefonoContacto!.trim().isEmpty) &&
      latitudEntrega == null &&
      longitudEntrega == null;

  Map<String, dynamic> toJson() => {
    if (direccionEntrega != null) 'direccionEntrega': direccionEntrega,
    if (ciudadEntrega != null) 'ciudadEntrega': ciudadEntrega,
    if (referenciaEntrega != null) 'referenciaEntrega': referenciaEntrega,
    if (telefonoContacto != null) 'telefonoContacto': telefonoContacto,
    if (latitudEntrega != null) 'latitudEntrega': latitudEntrega,
    if (longitudEntrega != null) 'longitudEntrega': longitudEntrega,
  };
}

/// Result of a successful `POST /ventas`.
///
/// The backend responds with `{venta, alertasStock, mensaje}` — we surface
/// all three so the checkout page can show low-stock warnings after the
/// order is created.
class OrderCreationResult {
  const OrderCreationResult({
    required this.order,
    required this.mensaje,
    this.alertasStock = const [],
  });

  final Order order;
  final String mensaje;
  final List<String> alertasStock;
}

/// Thin client for the sales endpoints. Requires an [AuthException]-aware
/// token supplied by the caller (typically `AuthScope.of(context).token`).
///
/// Endpoints used:
/// - `POST /ventas`      (Cliente/Administrador/Vendedor) → create order
/// - `GET  /ventas/mis`  (any auth) → orders belonging to the current customer
class OrdersApi {
  OrdersApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Accepted `metodoPago` values, mirror of METODOS_CHECKOUT_PERMITIDOS
  /// in backend/src/modules/ventas/ventas.service.js. TARJETA is a
  /// simulated payment: the backend approves it automatically and the
  /// sale returns as PAGADA. The other two leave the sale PENDIENTE.
  static const paymentMethodTarjeta = 'TARJETA';
  static const paymentMethodTransferencia = 'TRANSFERENCIA';
  static const paymentMethodEfectivo = 'EFECTIVO';

  Future<OrderCreationResult> createOrder({
    required String token,
    required List<OrderItemDraft> items,
    required String paymentMethod,
    DeliverySnapshotDraft? entrega,
  }) async {
    if (items.isEmpty) {
      throw const AuthException(
        'No hay productos para crear la venta.',
        statusCode: 400,
      );
    }

    final body = <String, dynamic>{
      'items': items.map((item) => item.toJson()).toList(),
      'metodoPago': paymentMethod,
      if (entrega != null && !entrega.isEmpty) ...entrega.toJson(),
    };

    final json = await _request(
      '/ventas',
      method: 'POST',
      token: token,
      body: body,
    );

    final ventaJson = json['venta'];
    if (ventaJson is! Map) {
      throw const AuthException(
        'El servidor no devolvió los datos de la venta.',
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

    return OrderCreationResult(
      order: Order.fromJson(ventaJson.cast<String, dynamic>()),
      mensaje: json['mensaje']?.toString() ?? 'Venta creada correctamente.',
      alertasStock: alertas,
    );
  }

  Future<List<Order>> loadMyOrders({required String token}) async {
    final json = await _request('/ventas/mis', token: token);
    final raw = json['datos'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => Order.fromJson(item.cast<String, dynamic>()))
        .toList(growable: false);
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
    // Try `detalles` array coming from validation errors.
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
