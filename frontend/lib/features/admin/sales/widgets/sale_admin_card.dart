import 'package:flutter/material.dart';

import '../../../../app/app_design_tokens.dart';
import '../../../../models/order.dart';
import '../../../../models/order_item.dart';
import '../../../../models/payment.dart';
import '../../../../widgets/feedback/feedback_banner.dart';
import '../../../../widgets/orders/delivery_snapshot_block.dart';

/// A single sale rendered as a collapsible admin card. Header shows
/// customer, status and total. Expanded body shows items, totals,
/// delivery snapshot, payment history, invoice (if any) and the
/// available actions.
///
/// The parent (`AdminSalesPage`) owns the mutation logic and passes:
///   - [busy]: whether an action is in flight for this specific sale.
///   - [stockAlerts]: warnings surfaced after confirming a payment.
///   - [onConfirmPayment] / [onGenerateInvoice]: callbacks bound to
///     the API client + role-gated state.
///
/// The card decides which action to show by looking at
/// `order.pagos` — the initial `Pago` is created inside the same
/// transaction as the `Venta` in `POST /ventas`, so any sale created
/// after the payment-flow migration will always have at least one
/// payment. Pre-migration `PENDIENTE` sales without any payment fall
/// into the "método no registrado" read-only branch.
class SaleAdminCard extends StatelessWidget {
  const SaleAdminCard({
    required this.order,
    required this.busy,
    required this.stockAlerts,
    required this.onConfirmPayment,
    required this.onGenerateInvoice,
    required this.onDismissStockAlert,
    super.key,
  });

  final Order order;
  final bool busy;
  final List<String> stockAlerts;
  final VoidCallback onConfirmPayment;
  final VoidCallback onGenerateInvoice;
  final VoidCallback onDismissStockAlert;

  /// The first PENDIENTE payment, if any. Used to decide whether the
  /// confirm-payment action is available and which copy to render.
  Payment? get _pendingPayment {
    for (final p in order.pagos) {
      if (p.isPending) return p;
    }
    return null;
  }

  /// Legacy sale in `PENDIENTE` state with no payment attached: created
  /// before the payment flow migration. Read-only from this panel.
  bool get _isLegacyPending => order.isPending && order.pagos.isEmpty;

  bool get _canConfirmPayment =>
      order.isPending && _pendingPayment != null && !busy;

  bool get _canGenerateInvoice =>
      order.isPaid && order.factura == null && !busy;

  @override
  Widget build(BuildContext context) {
    final cliente = order.clienteNombre?.trim();
    final showCliente = cliente != null && cliente.isNotEmpty;

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
                    showCliente
                        ? '$cliente · ${order.items.length} productos · ${order.itemsCount} unidades'
                        : '${order.items.length} productos · ${order.itemsCount} unidades',
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
          if (stockAlerts.isNotEmpty) ...[
            for (final alert in stockAlerts) ...[
              FeedbackBanner.warning(alert, onDismiss: onDismissStockAlert),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 4),
          ],
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
          const SizedBox(height: 14),
          _PaymentStatusBlock(
            order: order,
            pendingPayment: _pendingPayment,
            isLegacyPending: _isLegacyPending,
          ),
          if (order.pagos.isNotEmpty) ...[
            const SizedBox(height: 14),
            _PaymentsBlock(order: order),
          ],
          if (order.factura != null) ...[
            const SizedBox(height: 14),
            _InvoiceBlock(order: order),
          ],
          const SizedBox(height: 16),
          _ActionsRow(
            order: order,
            pendingPayment: _pendingPayment,
            isLegacyPending: _isLegacyPending,
            busy: busy,
            canConfirmPayment: _canConfirmPayment,
            canGenerateInvoice: _canGenerateInvoice,
            onConfirmPayment: onConfirmPayment,
            onGenerateInvoice: onGenerateInvoice,
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Reusable pieces
// ────────────────────────────────────────────────────────────────

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

/// Compact banner that reflects the current payment situation and
/// hints the operator about the next action. Rendered above the full
/// history block so the state-at-a-glance is visible even when the
/// operator collapses/expands the details.
class _PaymentStatusBlock extends StatelessWidget {
  const _PaymentStatusBlock({
    required this.order,
    required this.pendingPayment,
    required this.isLegacyPending,
  });

  final Order order;
  final Payment? pendingPayment;
  final bool isLegacyPending;

  @override
  Widget build(BuildContext context) {
    // Legacy PENDIENTE without any Pago: we don't invent a method.
    if (isLegacyPending) {
      return _StatusCard(
        icon: Icons.help_outline,
        background: AppColors.bgPage,
        border: AppColors.textSecondary,
        iconColor: AppColors.textSecondary,
        title: 'Venta histórica · método de pago no registrado',
        body:
            'Esta venta se creó antes de la integración del método de pago. Queda en modo lectura hasta que definamos un flujo de regularización manual.',
      );
    }

    if (pendingPayment != null) {
      final metodo = pendingPayment!.metodo;
      final (title, body) = switch (metodo) {
        'TRANSFERENCIA' => (
          'Transferencia pendiente',
          'El cliente eligió pagar por transferencia. Espera el comprobante y confirma cuando lo hayas verificado. Al confirmar se descuenta inventario y se marca la venta como PAGADA.',
        ),
        'EFECTIVO' => (
          'Efectivo pendiente contra entrega',
          'El pedido se cobra en efectivo al entregarlo. Cuando recibas el efectivo, registra el cobro para descontar inventario y marcar la venta como PAGADA.',
        ),
        _ => (
          'Pago pendiente',
          'Método: $metodo. Confirma para marcar la venta como PAGADA.',
        ),
      };
      return _StatusCard(
        icon: metodo == 'TRANSFERENCIA'
            ? Icons.account_balance_outlined
            : metodo == 'EFECTIVO'
            ? Icons.payments_outlined
            : Icons.hourglass_bottom,
        background: AppColors.bgPeach,
        border: AppColors.warning,
        iconColor: AppColors.warning,
        title: title,
        body: body,
      );
    }

    // Order is either PAGADA or CANCELADA (or PENDIENTE with all pagos
    // in non-pending states, which shouldn't happen but we render a
    // generic notice just in case).
    if (order.isPaid) {
      final tarjeta = order.pagos.any(
        (p) => p.metodo == 'TARJETA' && p.isApproved,
      );
      return _StatusCard(
        icon: Icons.check_circle_outline,
        background: AppColors.successSoft,
        border: AppColors.success,
        iconColor: AppColors.success,
        title: tarjeta ? 'Pago con tarjeta aprobado' : 'Pago confirmado',
        body: tarjeta
            ? 'Pago simulado con tarjeta aprobado automáticamente durante el checkout. Inventario ya descontado.'
            : 'La venta está pagada y el inventario ya fue descontado. Puedes generar la factura si aún no existe.',
      );
    }

    if (order.isCancelled) {
      return const _StatusCard(
        icon: Icons.cancel_outlined,
        background: AppColors.errorSoft,
        border: AppColors.error,
        iconColor: AppColors.error,
        title: 'Venta cancelada',
        body: 'No se pueden registrar más movimientos sobre esta venta.',
      );
    }

    return const SizedBox.shrink();
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.background,
    required this.border,
    required this.iconColor,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color background;
  final Color border;
  final Color iconColor;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: border.withValues(alpha: 0.55)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    height: 1.35,
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

class _PaymentsBlock extends StatelessWidget {
  const _PaymentsBlock({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Historial de pagos',
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

class _ActionsRow extends StatelessWidget {
  const _ActionsRow({
    required this.order,
    required this.pendingPayment,
    required this.isLegacyPending,
    required this.busy,
    required this.canConfirmPayment,
    required this.canGenerateInvoice,
    required this.onConfirmPayment,
    required this.onGenerateInvoice,
  });

  final Order order;
  final Payment? pendingPayment;
  final bool isLegacyPending;
  final bool busy;
  final bool canConfirmPayment;
  final bool canGenerateInvoice;
  final VoidCallback onConfirmPayment;
  final VoidCallback onGenerateInvoice;

  @override
  Widget build(BuildContext context) {
    // Legacy PENDIENTE: no action available from this panel. The user
    // sees only the "método no registrado" banner above.
    if (isLegacyPending) {
      return const SizedBox.shrink();
    }

    final confirmLabel = _confirmLabel(pendingPayment?.metodo);
    final actions = <Widget>[];

    if (pendingPayment != null) {
      actions.add(
        FilledButton.icon(
          onPressed: canConfirmPayment ? onConfirmPayment : null,
          icon: busy
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(_confirmIcon(pendingPayment!.metodo), size: 18),
          label: Text(confirmLabel),
        ),
      );
    }

    if (order.isPaid) {
      actions.add(
        OutlinedButton.icon(
          onPressed: canGenerateInvoice ? onGenerateInvoice : null,
          icon: busy
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.receipt_long_outlined, size: 18),
          label: const Text('Generar factura'),
        ),
      );
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.end,
      children: actions,
    );
  }

  static String _confirmLabel(String? metodo) {
    return switch (metodo) {
      'TRANSFERENCIA' => 'Confirmar transferencia',
      'EFECTIVO' => 'Registrar cobro',
      _ => 'Confirmar pago',
    };
  }

  static IconData _confirmIcon(String metodo) {
    return switch (metodo) {
      'TRANSFERENCIA' => Icons.account_balance_outlined,
      'EFECTIVO' => Icons.payments_outlined,
      _ => Icons.check_circle_outline,
    };
  }
}

String _formatDate(DateTime date) {
  final d = date.toLocal();
  final day = d.day.toString().padLeft(2, '0');
  final month = d.month.toString().padLeft(2, '0');
  return '$day/$month/${d.year}';
}
