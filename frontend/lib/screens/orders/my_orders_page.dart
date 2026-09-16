import 'package:flutter/material.dart';

import '../../app/app_design_tokens.dart';
import '../../data/api/auth_service.dart';
import '../../data/api/orders_api.dart';
import '../../models/order.dart';
import '../../models/order_item.dart';
import '../../state/auth_scope.dart';
import '../../widgets/feedback/error_view.dart';
import '../../widgets/feedback/loading_view.dart';
import '../../widgets/orders/delivery_snapshot_block.dart';

/// Private route: `/mis-pedidos`.
///
/// Lists the orders belonging to the authenticated customer, most recent
/// first. Each row expands to show the line items, payment attempts and
/// (when available) the invoice snapshot.
///
/// The page is intentionally read-only for now: the customer cannot
/// approve, cancel or pay from here. Those actions live in the admin
/// panel (Paso 9). All the state transitions the customer sees are the
/// result of an admin approving the sale.
class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  late Future<List<Order>> _ordersFuture;
  final _api = OrdersApi();

  @override
  void initState() {
    super.initState();
    _ordersFuture = _load();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<List<Order>> _load() {
    final auth = AuthScope.read(context);
    final token = auth.token;
    if (token == null) {
      return Future.error(
        const AuthException('Debes iniciar sesión.', statusCode: 401),
      );
    }
    return _api.loadMyOrders(token: token);
  }

  void _reload() {
    setState(() {
      _ordersFuture = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewportWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        backgroundColor: AppColors.bgPage,
        elevation: 0,
        title: const Text(
          'Mis pedidos',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/', (route) => false);
            }
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
        ],
      ),
      body: FutureBuilder<List<Order>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingView();
          }
          if (snapshot.hasError) {
            return ErrorView(
              message: 'No pudimos cargar tus pedidos.',
              details: snapshot.error?.toString() ?? '',
              onRetry: _reload,
            );
          }
          final orders = snapshot.data ?? const <Order>[];
          if (orders.isEmpty) return const _EmptyOrdersView();

          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: AppLayout.horizontalPadding(viewportWidth),
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${orders.length} ${orders.length == 1 ? 'pedido' : 'pedidos'} registrados',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    for (final order in orders) ...[
                      _OrderCard(order: order),
                      const SizedBox(height: 14),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.borderSoft),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
        shape: const Border(),
        collapsedShape: const Border(),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pedido #${order.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${order.items.length} ${order.items.length == 1 ? 'producto' : 'productos'} · ${order.itemsCount} unidades',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _StatusPill(estado: order.estado),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            'Total \$${order.total.toStringAsFixed(2)}',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ),
        children: [
          const Divider(height: 22, color: AppColors.borderSoft),
          for (final item in order.items) ...[
            _ItemRow(item: item),
            const SizedBox(height: 10),
          ],
          const Divider(height: 20, color: AppColors.borderSoft),
          _TotalsBlock(order: order),
          if (order.tieneSnapshotEntrega) ...[
            const SizedBox(height: 14),
            DeliverySnapshotBlock(order: order),
          ],
          if (order.pagos.isNotEmpty) ...[
            const SizedBox(height: 14),
            _PaymentsBlock(order: order),
          ],
          if (order.factura != null) ...[
            const SizedBox(height: 14),
            _InvoiceBlock(order: order),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.estado});
  final String estado;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border, label, icon) = switch (estado) {
      'PAGADA' => (
        AppColors.successSoft,
        AppColors.success,
        AppColors.success,
        'Pagada',
        Icons.check_circle_outline,
      ),
      'CANCELADA' => (
        AppColors.errorSoft,
        AppColors.error,
        AppColors.error,
        'Cancelada',
        Icons.cancel_outlined,
      ),
      _ => (
        AppColors.bgPeach,
        AppColors.warning,
        AppColors.warning,
        'Pendiente',
        Icons.hourglass_bottom,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: border.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});
  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.marca != null)
                Text(
                  item.marca!.name,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              const SizedBox(height: 2),
              Text(
                item.productoNombre.isEmpty
                    ? 'Producto #${item.productoId}'
                    : item.productoNombre,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${item.cantidad} × \$${item.precioUnitario.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Text(
          '\$${item.total.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
        ),
      ],
    );
  }
}

class _TotalsBlock extends StatelessWidget {
  const _TotalsBlock({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _KeyValueRow(
          label: 'Subtotal',
          value: '\$${order.subtotal.toStringAsFixed(2)}',
        ),
        const SizedBox(height: 4),
        _KeyValueRow(
          label: 'Impuestos',
          value: '\$${order.impuesto.toStringAsFixed(2)}',
        ),
        const SizedBox(height: 6),
        _KeyValueRow(
          label: 'Total',
          value: '\$${order.total.toStringAsFixed(2)}',
          emphasised: true,
        ),
      ],
    );
  }
}

class _PaymentsBlock extends StatelessWidget {
  const _PaymentsBlock({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Pagos registrados',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        for (final pago in order.pagos)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(
                  pago.isApproved
                      ? Icons.check_circle
                      : pago.isFailed
                      ? Icons.cancel
                      : Icons.hourglass_bottom,
                  color: pago.isApproved
                      ? AppColors.success
                      : pago.isFailed
                      ? AppColors.error
                      : AppColors.warning,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${pago.metodo} · ${pago.estado} · \$${pago.monto.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (pago.fechaPago != null)
                  Text(
                    _formatDate(pago.fechaPago!),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _InvoiceBlock extends StatelessWidget {
  const _InvoiceBlock({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final invoice = order.factura!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgMint,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long, color: AppColors.success),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Factura ${invoice.numeroFactura}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${invoice.nombreCliente} · Total \$${invoice.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({
    required this.label,
    required this.value,
    this.emphasised = false,
  });

  final String label;
  final String value;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: emphasised
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
              fontWeight: emphasised ? FontWeight.w900 : FontWeight.w700,
              fontSize: emphasised ? 15 : 13,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: emphasised ? AppColors.primary : AppColors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: emphasised ? 18 : 13,
          ),
        ),
      ],
    );
  }
}

class _EmptyOrdersView extends StatelessWidget {
  const _EmptyOrdersView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 60,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            const Text(
              'Aún no tienes pedidos',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
            ),
            const SizedBox(height: 6),
            const Text(
              'Cuando finalices una compra, aparecerá aquí para que revises su estado.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/', (route) => false),
              icon: const Icon(Icons.storefront_outlined),
              label: const Text('Explorar catálogo'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final d = date.toLocal();
  final day = d.day.toString().padLeft(2, '0');
  final month = d.month.toString().padLeft(2, '0');
  return '$day/$month/${d.year}';
}
