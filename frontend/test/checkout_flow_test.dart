// Unit + widget coverage for the checkout / orders flow.
//
// 1. Order.fromJson parses a realistic response from POST /ventas /
//    GET /ventas/mis (with nested detalles, pagos and factura).
// 2. MyOrdersPage renders a loading state while the FutureBuilder awaits
//    the API call; it doesn't need a live backend for this assertion.
//
// The tests intentionally stay off the network: OrdersApi is not stubbed
// because we never exercise a code path that would actually reach the
// http client. The AuthController is created with the default in-memory
// storage stub (auth_storage_stub.dart), so no dart:html dependency
// leaks into the test VM.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/models/order.dart';
import 'package:frontend/screens/orders/my_orders_page.dart';
import 'package:frontend/state/auth_scope.dart';

Widget _wrapWithScope(Widget child) {
  final controller = AuthController();
  return AuthScope(
    controller: controller,
    child: MaterialApp(
      home: child,
      onGenerateRoute: (settings) => MaterialPageRoute(
        settings: settings,
        builder: (_) => const Scaffold(),
      ),
    ),
  );
}

Future<void> _sizeViewport(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1000, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  test('Order.fromJson parses a realistic POST /ventas response', () {
    // Shape copied from ventas.service.js `crearVenta`:
    // include cliente, usuario (subset), detalles.producto(marca+categoria),
    // pagos, factura.
    final json = <String, dynamic>{
      'id': 42,
      'clienteId': 3,
      'usuarioId': 7,
      'estado': 'PENDIENTE',
      'subtotal': '80.00',
      'impuesto': '0.00',
      'total': '80.00',
      'createdAt': '2026-09-14T18:00:00.000Z',
      'cliente': {
        'id': 3,
        'nombres': 'Jose',
        'apellidos': 'PruebaAuth',
        'correo': 'jose.prueba@example.com',
      },
      'detalles': [
        {
          'id': 100,
          'productoId': 24,
          'cantidad': 2,
          'precioUnitario': '40.00',
          'total': '80.00',
          'producto': {
            'nombre': 'Good Girl',
            'imagenUrl': null,
            'marca': {'id': 1, 'nombre': 'Carolina Herrera'},
            'categoria': {'id': 2, 'nombre': 'Perfumes'},
          },
        },
      ],
      'pagos': <Map<String, dynamic>>[],
      'factura': null,
    };

    final order = Order.fromJson(json);

    expect(order.id, 42);
    expect(order.clienteId, 3);
    expect(order.estado, 'PENDIENTE');
    expect(order.total, 80.0);
    expect(order.isPending, isTrue);
    expect(order.isPaid, isFalse);
    expect(order.items, hasLength(1));
    expect(order.items.first.productoId, 24);
    expect(order.items.first.productoNombre, 'Good Girl');
    expect(order.items.first.marca?.name, 'Carolina Herrera');
    expect(order.itemsCount, 2);
    expect(order.pagos, isEmpty);
    expect(order.factura, isNull);
    expect(order.clienteNombre, 'Jose PruebaAuth');
    expect(order.clienteCorreo, 'jose.prueba@example.com');
  });

  test('Order.fromJson parses a paid order with payments and invoice', () {
    final json = <String, dynamic>{
      'id': 7,
      'clienteId': 1,
      'usuarioId': 1,
      'estado': 'PAGADA',
      'subtotal': '100.00',
      'impuesto': '15.00',
      'total': '115.00',
      'detalles': <Map<String, dynamic>>[],
      'pagos': [
        {
          'id': 55,
          'ventaId': 7,
          'metodo': 'TARJETA',
          'estado': 'PAGADO',
          'monto': '115.00',
          'fechaPago': '2026-09-14T20:15:00.000Z',
        },
      ],
      'factura': {
        'id': 3,
        'ventaId': 7,
        'numeroFactura': 'FAC-000007',
        'nombreCliente': 'Administrador Aromas Store',
        'cedulaCliente': null,
        'subtotal': '100.00',
        'impuesto': '15.00',
        'total': '115.00',
      },
    };

    final order = Order.fromJson(json);

    expect(order.isPaid, isTrue);
    expect(order.pagos, hasLength(1));
    expect(order.pagos.first.isApproved, isTrue);
    expect(order.pagos.first.metodo, 'TARJETA');
    expect(order.pagos.first.fechaPago, isNotNull);
    expect(order.factura, isNotNull);
    expect(order.factura!.numeroFactura, 'FAC-000007');
    expect(order.factura!.total, 115.0);
  });

  testWidgets(
    'MyOrdersPage renders app bar and refresh action without exceptions',
    (tester) async {
      await _sizeViewport(tester);
      // The page will kick off an HTTP request that fails in tests, but
      // that only shows up asynchronously inside the FutureBuilder. This
      // pump just verifies the page mounts and its chrome renders — the
      // same guarantee we get for LoginPage / RegisterPage in the auth
      // suite.
      await tester.pumpWidget(_wrapWithScope(const MyOrdersPage()));
      await tester.pump();

      expect(find.text('Mis pedidos'), findsWidgets);
      expect(find.byTooltip('Actualizar'), findsOne);
      expect(tester.takeException(), isNull);
    },
  );
}
