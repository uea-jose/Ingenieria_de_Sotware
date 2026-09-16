import 'package:flutter/material.dart';

import '../../../app/app_design_tokens.dart';
import '../../../data/api/admin_sales_api.dart';
import '../../../data/api/auth_service.dart';
import '../../../models/order.dart';
import '../../../models/payment.dart';
import '../../../state/auth_scope.dart';
import '../../../widgets/feedback/app_feedback.dart';
import '../../../widgets/feedback/error_view.dart';
import '../../../widgets/feedback/loading_view.dart';
import 'widgets/sale_admin_card.dart';

/// Filter tabs available at the top of the panel. Backend has no
/// server-side filter for /ventas, so we filter client-side.
enum _SalesFilter { todas, pendientes, pagadas, canceladas }

extension _SalesFilterX on _SalesFilter {
  String get label => switch (this) {
    _SalesFilter.todas => 'Todas',
    _SalesFilter.pendientes => 'Pendientes',
    _SalesFilter.pagadas => 'Pagadas',
    _SalesFilter.canceladas => 'Canceladas',
  };

  bool matches(Order order) => switch (this) {
    _SalesFilter.todas => true,
    _SalesFilter.pendientes => order.isPending,
    _SalesFilter.pagadas => order.isPaid,
    _SalesFilter.canceladas => order.isCancelled,
  };
}

/// Admin panel at `/admin/ventas` — lists every sale and lets
/// Administrador/Vendedor confirm pending transfers, register cash
/// payments and generate invoices.
///
/// The payment method is decided by the customer at checkout time and
/// persisted on the `Pago` row created inside the same transaction as
/// the sale. The panel never re-asks the method: it reads
/// `order.pagos.first` and shows the appropriate action.
///
/// Roles:
/// - `Administrador` and `Vendedor` can operate the panel.
/// - `Bodeguero` is `isStaff` so `RequireAuth` lets them through, but a
///   second check here shows a friendly restricted view instead of the
///   backend 403.
class AdminSalesPage extends StatefulWidget {
  const AdminSalesPage({super.key, this.api});

  final AdminSalesApi? api;

  @override
  State<AdminSalesPage> createState() => _AdminSalesPageState();
}

class _AdminSalesPageState extends State<AdminSalesPage> {
  late final AdminSalesApi _api = widget.api ?? AdminSalesApi();

  late Future<List<Order>> _future;
  _SalesFilter _filter = _SalesFilter.todas;

  /// Ids of the sales that currently have an ongoing action (confirm
  /// payment / generate invoice). Used to disable the buttons.
  final Set<int> _busySales = <int>{};

  /// Latest stock alerts per sale — rendered as an inline warning banner
  /// under the sale card right after the pago is confirmed. Cleared on
  /// the next reload.
  final Map<int, List<String>> _stockAlerts = <int, List<String>>{};

  @override
  void initState() {
    super.initState();
    _future = _load();
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
    return _api.loadSales(token: token);
  }

  void _reload() {
    setState(() {
      _stockAlerts.clear();
      _future = _load();
    });
  }

  Future<void> _confirmPayment(Order order) async {
    final payment = _pendingPaymentOf(order);
    if (payment == null) return; // UI already hides the button in this case

    final confirmed = await _showConfirmDialog(order, payment);
    if (!confirmed || !mounted) return;

    final auth = AuthScope.read(context);
    final token = auth.token;
    if (token == null) return;

    setState(() => _busySales.add(order.id));
    try {
      final result = await _api.confirmPayment(
        token: token,
        paymentId: payment.id,
      );
      if (!mounted) return;
      _replaceOrder(result.order);
      setState(() {
        if (result.alertasStock.isEmpty) {
          _stockAlerts.remove(order.id);
        } else {
          _stockAlerts[order.id] = result.alertasStock;
        }
      });
      AppFeedback.success(context, result.mensaje);
    } on AuthException catch (error) {
      if (!mounted) return;
      AppFeedback.error(context, error.message);
    } finally {
      if (mounted) {
        setState(() => _busySales.remove(order.id));
      }
    }
  }

  Future<bool> _showConfirmDialog(Order order, Payment payment) async {
    final total = order.total.toStringAsFixed(2);
    final (title, body, ctaLabel) = switch (payment.metodo) {
      'TRANSFERENCIA' => (
        'Confirmar transferencia',
        'Estás por confirmar que la transferencia de \$$total para el pedido #${order.id} fue recibida. La venta pasará a PAGADA y el inventario se descontará automáticamente.',
        'Confirmar transferencia',
      ),
      'EFECTIVO' => (
        'Registrar cobro',
        'Estás por registrar que recibiste \$$total en efectivo por el pedido #${order.id}. La venta pasará a PAGADA y el inventario se descontará automáticamente.',
        'Registrar cobro',
      ),
      _ => (
        'Confirmar pago',
        'Estás por confirmar el pago pendiente de \$$total para el pedido #${order.id}. La venta pasará a PAGADA y el inventario se descontará automáticamente.',
        'Confirmar pago',
      ),
    };

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(title),
        content: Text(
          body,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            icon: const Icon(Icons.check_circle_outline),
            label: Text(ctaLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _generateInvoice(Order order) async {
    final auth = AuthScope.read(context);
    final token = auth.token;
    if (token == null) return;

    setState(() => _busySales.add(order.id));
    try {
      final result = await _api.generateInvoice(token: token, saleId: order.id);
      if (!mounted) return;
      _reload();
      AppFeedback.success(
        context,
        '${result.mensaje} (${result.invoice.numeroFactura})',
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      AppFeedback.error(context, error.message);
    } finally {
      if (mounted) {
        setState(() => _busySales.remove(order.id));
      }
    }
  }

  /// Swaps the given sale into the cached list without a network
  /// roundtrip. Used after `POST /pagos/:id/confirmar` returns the
  /// updated venta.
  void _replaceOrder(Order updated) {
    _future = _future.then((orders) {
      return [for (final o in orders) o.id == updated.id ? updated : o];
    });
    setState(() {});
  }

  static Payment? _pendingPaymentOf(Order order) {
    for (final p in order.pagos) {
      if (p.isPending) return p;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final user = auth.currentUser;
    final allowed = user != null && (user.isAdmin || user.isVendedor);

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        backgroundColor: AppColors.bgPage,
        elevation: 0,
        title: const Text(
          'Panel de ventas',
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
          if (allowed)
            IconButton(
              tooltip: 'Actualizar',
              icon: const Icon(Icons.refresh),
              onPressed: _reload,
            ),
        ],
      ),
      body: !allowed
          ? const _RestrictedRoleView()
          : FutureBuilder<List<Order>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const LoadingView();
                }
                if (snapshot.hasError) {
                  return ErrorView(
                    message: 'No pudimos cargar las ventas.',
                    details: snapshot.error?.toString() ?? '',
                    onRetry: _reload,
                  );
                }
                final all = snapshot.data ?? const <Order>[];
                if (all.isEmpty) return const _EmptySalesView();
                return _SalesListView(
                  orders: all,
                  filter: _filter,
                  busySales: _busySales,
                  stockAlerts: _stockAlerts,
                  onFilterChanged: (next) => setState(() => _filter = next),
                  onConfirmPayment: _confirmPayment,
                  onGenerateInvoice: _generateInvoice,
                  onDismissStockAlert: (id) =>
                      setState(() => _stockAlerts.remove(id)),
                );
              },
            ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Layout — list, filters, empty & forbidden views
// ────────────────────────────────────────────────────────────────

class _SalesListView extends StatelessWidget {
  const _SalesListView({
    required this.orders,
    required this.filter,
    required this.busySales,
    required this.stockAlerts,
    required this.onFilterChanged,
    required this.onConfirmPayment,
    required this.onGenerateInvoice,
    required this.onDismissStockAlert,
  });

  final List<Order> orders;
  final _SalesFilter filter;
  final Set<int> busySales;
  final Map<int, List<String>> stockAlerts;
  final ValueChanged<_SalesFilter> onFilterChanged;
  final ValueChanged<Order> onConfirmPayment;
  final ValueChanged<Order> onGenerateInvoice;
  final ValueChanged<int> onDismissStockAlert;

  @override
  Widget build(BuildContext context) {
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final filtered = orders.where(filter.matches).toList(growable: false);

    final counts = <_SalesFilter, int>{
      for (final f in _SalesFilter.values) f: orders.where(f.matches).length,
    };

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.horizontalPadding(viewportWidth),
        vertical: 24,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FilterBar(
                current: filter,
                counts: counts,
                onChanged: onFilterChanged,
              ),
              const SizedBox(height: 14),
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: Center(
                    child: Text(
                      'No hay ventas en «${filter.label.toLowerCase()}».',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
              else
                for (final order in filtered) ...[
                  SaleAdminCard(
                    order: order,
                    busy: busySales.contains(order.id),
                    stockAlerts: stockAlerts[order.id] ?? const <String>[],
                    onConfirmPayment: () => onConfirmPayment(order),
                    onGenerateInvoice: () => onGenerateInvoice(order),
                    onDismissStockAlert: () => onDismissStockAlert(order.id),
                  ),
                  const SizedBox(height: 14),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.current,
    required this.counts,
    required this.onChanged,
  });

  final _SalesFilter current;
  final Map<_SalesFilter, int> counts;
  final ValueChanged<_SalesFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final f in _SalesFilter.values)
          _FilterChip(
            label: f.label,
            count: counts[f] ?? 0,
            selected: f == current,
            onTap: () => onChanged(f),
          ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.primary : AppColors.surface;
    final fg = selected ? Colors.white : AppColors.textPrimary;
    final border = selected ? AppColors.primary : AppColors.borderSoft;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.25)
                    : AppColors.bgPage,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySalesView extends StatelessWidget {
  const _EmptySalesView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.point_of_sale_outlined,
              size: 60,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 12),
            Text(
              'Aún no hay ventas registradas',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
            ),
            SizedBox(height: 6),
            Text(
              'Cuando un cliente finalice una compra aparecerá aquí para confirmar el pago y generar la factura.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestrictedRoleView extends StatelessWidget {
  const _RestrictedRoleView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            const Text(
              'Solo Administrador y Vendedor pueden operar ventas.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tu rol no tiene permisos para confirmar pagos ni generar facturas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/', (route) => false),
              child: const Text('Volver al inicio'),
            ),
          ],
        ),
      ),
    );
  }
}
