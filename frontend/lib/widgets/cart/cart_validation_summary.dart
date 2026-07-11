import 'package:flutter/material.dart';

import '../../app/app_design_tokens.dart';
import '../../models/cart_validation.dart';

class CartValidationSummary extends StatelessWidget {
  const CartValidationSummary({required this.validation, super.key});

  final CartValidation validation;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: validation.valid ? AppColors.bgMint : AppColors.bgPeach,
        borderRadius: BorderRadius.circular(AppRadii.search),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                validation.valid
                    ? Icons.check_circle_outline
                    : Icons.warning_amber_rounded,
                color: validation.valid ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: 8),
              Text(
                validation.valid ? 'Carrito valido' : 'Revisar carrito',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Subtotal: \$${validation.subtotal.toStringAsFixed(2)}'),
          Text('IVA 15%: \$${validation.tax.toStringAsFixed(2)}'),
          const Text('Descuentos: \$0.00'),
          const Text('Envio: Por coordinar'),
          Text(
            'Total final: \$${validation.total.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          if (validation.stockAlerts.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final alert in validation.stockAlerts)
              Text(
                'Alerta: $alert',
                style: const TextStyle(color: AppColors.warning),
              ),
          ],
          if (validation.errors.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final error in validation.errors)
              Text(
                'Error: $error',
                style: const TextStyle(color: AppColors.error),
              ),
          ],
        ],
      ),
    );
  }
}
