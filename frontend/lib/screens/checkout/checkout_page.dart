import 'package:flutter/material.dart';

import '../../app/app_design_tokens.dart';
import '../../core/validators.dart';
import '../../data/api/api_service.dart';
import '../../data/api/auth_service.dart';
import '../../data/api/orders_api.dart';
import '../../data/storage/cart_storage.dart';
import '../../models/catalog_data.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../state/auth_scope.dart';
import '../../widgets/checkout/delivery_address_panel.dart';
import '../../widgets/feedback/error_view.dart';
import '../../widgets/feedback/feedback_banner.dart';
import '../../widgets/feedback/loading_view.dart';

/// Private route: `/checkout`.
///
/// Wraps three UI states behind a single page:
///   1. `form`       — resumen del carrito + método de pago + datos del cliente.
///   2. `submitting` — overlay con loader mientras se llama `POST /ventas`.
///   3. `success`    — confirmación con número de venta y accesos a
///                     `/mis-pedidos` o volver al catálogo.
///
/// El backend NO cobra el pago desde el frontend (el rol Cliente no tiene
/// permiso para `POST /pagos`). El checkout crea la venta en estado
/// PENDIENTE y confía en que un admin la marque como PAGADA en el panel
/// interno (Paso 9). Esto es intencional y refleja el flujo real de una
/// tienda con pasarela de pago externa.
class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

enum _CheckoutStage { form, submitting, success }

const _paymentMethods = <_PaymentOption>[
  _PaymentOption(
    id: 'TARJETA',
    label: 'Tarjeta',
    icon: Icons.credit_card,
    description: 'Débito o crédito. Validación al aprobar el pedido.',
  ),
  _PaymentOption(
    id: 'TRANSFERENCIA',
    label: 'Transferencia',
    icon: Icons.account_balance_outlined,
    description: 'Envía el comprobante al correo indicado.',
  ),
  _PaymentOption(
    id: 'EFECTIVO',
    label: 'Efectivo contra entrega',
    icon: Icons.payments_outlined,
    description: 'Se cobra al momento de entregar el pedido.',
  ),
];

class _PaymentOption {
  const _PaymentOption({
    required this.id,
    required this.label,
    required this.icon,
    required this.description,
  });
  final String id;
  final String label;
  final IconData icon;
  final String description;
}

class _CheckoutPageState extends State<CheckoutPage> {
  late Future<CatalogData> _catalogFuture;
  final _ordersApi = OrdersApi();
  final _formKey = GlobalKey<FormState>();
  final Map<int, int> _cartQuantities = {};

  // Delivery snapshot controllers — the DeliveryAddressPanel writes here
  // (both on manual edits and on a successful GPS capture) and _confirm
  // reads them to build the payload for POST /ventas.
  final _direccionController = TextEditingController();
  final _ciudadController = TextEditingController();
  final _referenciaController = TextEditingController();
  final _telefonoController = TextEditingController();
  double? _latitudCapturada;
  double? _longitudCapturada;

  String _paymentMethodId = 'TARJETA';
  _CheckoutStage _stage = _CheckoutStage.form;
  Order? _createdOrder;
  String? _errorMessage;
  List<String> _stockWarnings = const [];

  @override
  void initState() {
    super.initState();
    _catalogFuture = ApiService.loadCatalog();
    _cartQuantities.addAll(CartStorage.load());
  }

  @override
  void dispose() {
    _ordersApi.dispose();
    _direccionController.dispose();
    _ciudadController.dispose();
    _referenciaController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  void _onCoordsCaptured(double lat, double lng, String? _) {
    setState(() {
      _latitudCapturada = lat;
      _longitudCapturada = lng;
    });
  }

  void _onCoordsCleared() {
    if (_latitudCapturada == null && _longitudCapturada == null) return;
    setState(() {
      _latitudCapturada = null;
      _longitudCapturada = null;
    });
  }

  Future<void> _confirm(List<Product> products) async {
    final auth = AuthScope.read(context);
    final token = auth.token;
    if (token == null) {
      setState(() {
        _errorMessage = 'Tu sesión expiró. Vuelve a iniciar sesión.';
      });
      return;
    }

    final items = _cartQuantities.entries
        .map(
          (entry) =>
              OrderItemDraft(productoId: entry.key, cantidad: entry.value),
        )
        .toList();

    if (items.isEmpty) {
      setState(() {
        _errorMessage = 'Agrega productos al carrito antes de finalizar.';
      });
      return;
    }

    // Validate the delivery address form (direccion / ciudad / telefono
    // are required, referencia optional). If any field is invalid the
    // Form paints its own inline errors; we stop here without sending.
    if (!(_formKey.currentState?.validate() ?? true)) {
      setState(() {
        _errorMessage = 'Revisa los datos de entrega antes de continuar.';
      });
      return;
    }

    // Normalise the phone to the canonical Ecuadorian shape (09XXXXXXXX)
    // before persisting it. Falls back to the raw text if the normaliser
    // can't parse it — the field validator already rejected malformed
    // values, so `raw` here is a well-formed variant we didn't map.
    final telefonoRaw = _telefonoController.text.trim();
    final telefonoNormalizado =
        normalizePhoneEcuador(telefonoRaw) ??
        (telefonoRaw.isEmpty ? null : telefonoRaw);

    final snapshot = DeliverySnapshotDraft(
      direccionEntrega: _direccionController.text.trim().isEmpty
          ? null
          : _direccionController.text.trim(),
      ciudadEntrega: _ciudadController.text.trim().isEmpty
          ? null
          : _ciudadController.text.trim(),
      referenciaEntrega: _referenciaController.text.trim().isEmpty
          ? null
          : _referenciaController.text.trim(),
      telefonoContacto: telefonoNormalizado,
      latitudEntrega: _latitudCapturada,
      longitudEntrega: _longitudCapturada,
    );

    setState(() {
      _stage = _CheckoutStage.submitting;
      _errorMessage = null;
      _stockWarnings = const [];
    });

    try {
      final result = await _ordersApi.createOrder(
        token: token,
        items: items,
        entrega: snapshot,
      );
      CartStorage.clear();
      if (!mounted) return;
      setState(() {
        _createdOrder = result.order;
        _stockWarnings = result.alertasStock;
        _stage = _CheckoutStage.success;
      });
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _stage = _CheckoutStage.form;
        _errorMessage = error.message;
      });
    }
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
          'Finalizar compra',
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
      ),
      body: FutureBuilder<CatalogData>(
        future: _catalogFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingView();
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return ErrorView(
              message: 'No pudimos cargar los datos del pedido.',
              details: snapshot.error?.toString() ?? 'Catálogo no disponible.',
              onRetry: () => setState(() {
                _catalogFuture = ApiService.loadCatalog();
              }),
            );
          }
          final catalog = snapshot.data!;
          final productsById = {for (final p in catalog.products) p.id: p};
          final cartProducts = _cartQuantities.keys
              .map((id) => productsById[id])
              .whereType<Product>()
              .toList();

          if (_stage == _CheckoutStage.success && _createdOrder != null) {
            return _SuccessView(
              order: _createdOrder!,
              paymentMethod: _paymentMethodLabel(_paymentMethodId),
              stockWarnings: _stockWarnings,
            );
          }

          if (cartProducts.isEmpty) {
            return const _EmptyCartView();
          }

          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: AppLayout.horizontalPadding(viewportWidth),
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                // A single Form wraps summary + delivery panel + payment
                // panel so `_formKey.currentState.validate()` triggers
                // the required-field messages inside `DeliveryAddressPanel`
                // when the user taps "Confirmar pedido".
                child: Form(
                  key: _formKey,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 900;
                      final summary = _OrderSummary(
                        products: cartProducts,
                        quantities: _cartQuantities,
                      );
                      final delivery = DeliveryAddressPanel(
                        direccionController: _direccionController,
                        ciudadController: _ciudadController,
                        referenciaController: _referenciaController,
                        telefonoController: _telefonoController,
                        onCoordsCaptured: _onCoordsCaptured,
                        onCoordsCleared: _onCoordsCleared,
                      );
                      final actions = _PaymentPanel(
                        selectedMethodId: _paymentMethodId,
                        onMethodChanged: (id) =>
                            setState(() => _paymentMethodId = id),
                        total: _computeTotal(cartProducts),
                        isSubmitting: _stage == _CheckoutStage.submitting,
                        errorMessage: _errorMessage,
                        onConfirm: () => _confirm(cartProducts),
                      );

                      if (compact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            summary,
                            const SizedBox(height: 18),
                            delivery,
                            const SizedBox(height: 18),
                            actions,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 6, child: summary),
                          const SizedBox(width: 20),
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                delivery,
                                const SizedBox(height: 18),
                                actions,
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  double _computeTotal(List<Product> products) {
    return products.fold<double>(0, (total, product) {
      final qty = _cartQuantities[product.id] ?? 0;
      return total + (product.price * qty);
    });
  }

  static String _paymentMethodLabel(String id) {
    return _paymentMethods
        .firstWhere(
          (option) => option.id == id,
          orElse: () => _paymentMethods.first,
        )
        .label;
  }
}

// ────────────────────────────────────────────────────────────────
// UI blocks
// ────────────────────────────────────────────────────────────────

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({required this.products, required this.quantities});

  final List<Product> products;
  final Map<int, int> quantities;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Resumen del pedido',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${products.length} ${products.length == 1 ? 'producto' : 'productos'} en el carrito',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          for (final product in products) ...[
            _SummaryRow(
              product: product,
              quantity: quantities[product.id] ?? 0,
            ),
            const Divider(height: 22, color: AppColors.borderSoft),
          ],
          _TotalsBlock(products: products, quantities: quantities),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  @override
  Widget build(BuildContext context) {
    final lineTotal = product.price * quantity;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.brand.name,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                product.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$quantity × \$${product.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Text(
          '\$${lineTotal.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _TotalsBlock extends StatelessWidget {
  const _TotalsBlock({required this.products, required this.quantities});

  final List<Product> products;
  final Map<int, int> quantities;

  @override
  Widget build(BuildContext context) {
    final subtotal = products.fold<double>(0, (total, product) {
      final qty = quantities[product.id] ?? 0;
      return total + (product.price * qty);
    });
    // Backend calculates impuesto server-side and returns it in the final
    // response. For the pre-submit preview we just show the subtotal as
    // "total estimado" so the number the user sees matches what they see
    // in the cart panel.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Subtotal estimado',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Text(
              '\$${subtotal.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Impuestos y ajustes finales se calculan al confirmar la venta.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

class _PaymentPanel extends StatelessWidget {
  const _PaymentPanel({
    required this.selectedMethodId,
    required this.onMethodChanged,
    required this.total,
    required this.isSubmitting,
    required this.onConfirm,
    this.errorMessage,
  });

  final String selectedMethodId;
  final ValueChanged<String> onMethodChanged;
  final double total;
  final bool isSubmitting;
  final VoidCallback onConfirm;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final user = auth.currentUser;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Datos del comprador',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          _ReadOnlyField(label: 'Nombre', value: user?.displayName ?? '—'),
          const SizedBox(height: 8),
          _ReadOnlyField(label: 'Correo', value: user?.email ?? '—'),
          if (user != null && user.rol != 'Cliente') ...[
            const SizedBox(height: 8),
            FeedbackBanner.warning(
              'Tu rol (${user.rol}) no tiene un perfil de cliente asociado. '
              'Inicia sesión con una cuenta cliente para completar la compra.',
            ),
          ],
          const SizedBox(height: 22),
          const Text(
            'Método de pago',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          for (final option in _paymentMethods)
            _PaymentTile(
              option: option,
              selected: option.id == selectedMethodId,
              onSelected: () => onMethodChanged(option.id),
            ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total a pagar',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'La venta queda pendiente hasta que un vendedor confirme el pago.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            FeedbackBanner.error(errorMessage!),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: isSubmitting ? null : onConfirm,
            icon: isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(isSubmitting ? 'Procesando...' : 'Confirmar pedido'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({
    required this.option,
    required this.selected,
    required this.onSelected,
  });

  final _PaymentOption option;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.card),
        onTap: onSelected,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.bgSoftPink : AppColors.bgPage,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.borderSoft,
              width: selected ? 1.4 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Icon(
                option.icon,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      option.description,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Visual only — the whole tile is clickable via InkWell.
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppColors.primary : AppColors.textSecondary,
                size: 22,
                semanticLabel: selected ? 'Seleccionado' : 'No seleccionado',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Success + empty states
// ────────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  const _SuccessView({
    required this.order,
    required this.paymentMethod,
    required this.stockWarnings,
  });

  final Order order;
  final String paymentMethod;
  final List<String> stockWarnings;

  @override
  Widget build(BuildContext context) {
    final viewportWidth = MediaQuery.sizeOf(context).width;
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: AppLayout.horizontalPadding(viewportWidth),
          vertical: 24,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: CircleAvatar(
                    radius: 34,
                    backgroundColor: AppColors.successSoft,
                    child: Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 44,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '¡Gracias por tu compra!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pedido #${order.id} creado en estado ${order.estado}.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),
                _InfoRow(
                  label: 'Total',
                  value: '\$${order.total.toStringAsFixed(2)}',
                ),
                const Divider(height: 20),
                _InfoRow(
                  label: 'Productos',
                  value: '${order.items.length} (${order.itemsCount} unidades)',
                ),
                const Divider(height: 20),
                _InfoRow(label: 'Método de pago', value: paymentMethod),
                if (order.clienteNombre != null &&
                    order.clienteNombre!.isNotEmpty) ...[
                  const Divider(height: 20),
                  _InfoRow(label: 'Cliente', value: order.clienteNombre!),
                ],
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.bgPeach,
                    borderRadius: BorderRadius.circular(AppRadii.card),
                    border: Border.all(color: AppColors.warning),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.hourglass_bottom, color: AppColors.warning),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Tu pedido está pendiente de aprobación de pago. Un vendedor validará el método elegido y te confirmará cuando quede pagado.',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            height: 1.4,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (stockWarnings.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  // Consolidamos todas las alertas de inventario en un
                  // único banner de warning con lista en el mismo cuerpo,
                  // en lugar de N filas sueltas con estilo distinto.
                  FeedbackBanner.warning(
                    stockWarnings.length == 1
                        ? stockWarnings.first
                        : 'Se detectaron ${stockWarnings.length} alertas de stock:\n• ${stockWarnings.join('\n• ')}',
                  ),
                ],
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: () => Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/mis-pedidos', (route) => false),
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('Ver mis pedidos'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/', (route) => false),
                  icon: const Icon(Icons.storefront_outlined),
                  label: const Text('Seguir comprando'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

class _EmptyCartView extends StatelessWidget {
  const _EmptyCartView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shopping_bag_outlined,
              size: 60,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            const Text(
              'Tu carrito está vacío',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
            ),
            const SizedBox(height: 6),
            const Text(
              'Agrega productos desde el catálogo antes de finalizar la compra.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/', (route) => false),
              icon: const Icon(Icons.storefront_outlined),
              label: const Text('Ver catálogo'),
            ),
          ],
        ),
      ),
    );
  }
}
