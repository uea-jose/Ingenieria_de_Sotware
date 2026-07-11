import 'package:flutter/material.dart';

import '../../models/cart_validation.dart';
import '../../models/product.dart';
import 'cart_product_row.dart';
import 'cart_validation_summary.dart';

class CartPanel extends StatelessWidget {
  const CartPanel({
    required this.products,
    required this.quantities,
    required this.validation,
    required this.validating,
    required this.onQuantityChanged,
    required this.onValidate,
    required this.onClear,
    required this.onCheckout,
    super.key,
  });

  final List<Product> products;
  final Map<int, int> quantities;
  final CartValidation? validation;
  final bool validating;
  final Future<void> Function(Product product, int quantity) onQuantityChanged;
  final Future<void> Function() onValidate;
  final Future<void> Function() onClear;
  final Future<void> Function() onCheckout;

  @override
  Widget build(BuildContext context) {
    final total = validation?.total ?? _localTotal;

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.42,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
            children: [
              Center(
                child: Container(
                  width: 54,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8D2C8),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Carrito de compras',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF111111),
                          ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar carrito',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Revisa cantidades, disponibilidad y total antes de continuar.',
                style: TextStyle(color: Color(0xFF68645D)),
              ),
              const SizedBox(height: 18),
              if (products.isEmpty)
                const _EmptyCartMessage()
              else ...[
                for (final product in products) ...[
                  CartProductRow(
                    product: product,
                    quantity: quantities[product.id] ?? 0,
                    onQuantityChanged: (value) =>
                        onQuantityChanged(product, value),
                  ),
                  const SizedBox(height: 12),
                ],
                const Divider(height: 28),
                if (validation != null)
                  CartValidationSummary(validation: validation!),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Total estimado',
                        style: TextStyle(
                          color: Color(0xFF68645D),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF145647),
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Continuar comprando'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => onClear(),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Vaciar carrito'),
                    ),
                    FilledButton.icon(
                      onPressed: validating ? null : () => onValidate(),
                      icon: validating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.verified_outlined),
                      label: Text(validating ? 'Validando' : 'Validar carrito'),
                    ),
                    FilledButton.icon(
                      onPressed: validating ? null : () => onCheckout(),
                      icon: const Icon(Icons.lock_outline),
                      label: const Text('Finalizar compra'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  double get _localTotal {
    return products.fold(0, (total, product) {
      final quantity = quantities[product.id] ?? 0;
      return total + (product.price * quantity);
    });
  }
}

class _EmptyCartMessage extends StatelessWidget {
  const _EmptyCartMessage();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Icon(Icons.shopping_bag_outlined, size: 52, color: Color(0xFF68645D)),
          SizedBox(height: 12),
          Text(
            'Tu carrito esta vacio.',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
          ),
          SizedBox(height: 6),
          Text('Agrega productos desde el catalogo publico.'),
        ],
      ),
    );
  }
}
