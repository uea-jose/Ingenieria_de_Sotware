import 'package:flutter/material.dart';

import '../../models/cart_validation.dart';

class CartPreviewBar extends StatelessWidget {
  const CartPreviewBar({
    required this.itemCount,
    required this.validation,
    required this.validating,
    required this.onOpenCart,
    required this.onValidate,
    super.key,
  });

  final int itemCount;
  final CartValidation? validation;
  final bool validating;
  final VoidCallback onOpenCart;
  final Future<void> Function() onValidate;

  @override
  Widget build(BuildContext context) {
    if (itemCount == 0) return const SizedBox.shrink();

    final total = validation?.total;
    final valid = validation?.valid;

    return Container(
      color: const Color(0xFFFAF8F4),
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Card(
            elevation: 0,
            color: const Color(0xFF102F29),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Wrap(
                spacing: 14,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.shopping_bag_outlined,
                        color: Color(0xFFE8C766),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '$itemCount producto${itemCount == 1 ? '' : 's'} en el carrito',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (total != null) ...[
                        const SizedBox(width: 12),
                        Text(
                          'Total: \$${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xFFE8C766),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                      if (valid != null) ...[
                        const SizedBox(width: 12),
                        Icon(
                          valid
                              ? Icons.check_circle_outline
                              : Icons.warning_amber_rounded,
                          color: valid
                              ? const Color(0xFF9FE7BD)
                              : const Color(0xFFFFD66B),
                          size: 20,
                        ),
                      ],
                    ],
                  ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: validating ? null : () => onValidate(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                        ),
                        icon: validating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.verified_outlined),
                        label: Text(validating ? 'Validando' : 'Validar'),
                      ),
                      FilledButton.icon(
                        onPressed: onOpenCart,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFE8C766),
                          foregroundColor: const Color(0xFF102F29),
                        ),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Ver carrito'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
