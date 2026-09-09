import 'package:flutter/material.dart';

import '../../app/app_design_tokens.dart';
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

    final viewportWidth = MediaQuery.sizeOf(context).width;
    final sidePadding = AppLayout.horizontalPadding(viewportWidth);

    return Container(
      color: AppColors.bgPage,
      padding: EdgeInsets.fromLTRB(sidePadding, 18, sidePadding, 8),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: AppLayout.contentMaxWidth(viewportWidth),
          ),
          child: Card(
            elevation: 0,
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.card),
              side: const BorderSide(color: AppColors.borderSoft),
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
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '$itemCount producto${itemCount == 1 ? '' : 's'} en el carrito',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (total != null) ...[
                        const SizedBox(width: 12),
                        Text(
                          'Total: \$${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppColors.primary,
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
                          color: valid ? AppColors.success : AppColors.warning,
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
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.borderSoft),
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
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.surface,
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
