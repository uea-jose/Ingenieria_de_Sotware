import 'package:flutter/material.dart';

import '../../app/app_design_tokens.dart';
import '../../models/product.dart';

class ProductInfoSection extends StatelessWidget {
  const ProductInfoSection({required this.product, super.key});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Descripcion',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            product.description.isEmpty
                ? 'Este producto aun no tiene una descripcion detallada.'
                : product.description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.55,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
