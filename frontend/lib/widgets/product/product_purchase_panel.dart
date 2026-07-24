import 'package:flutter/material.dart';

import '../../app/app_design_tokens.dart';
import '../../core/utils/price_formatter.dart';
import '../../models/product.dart';

class ProductPurchasePanel extends StatelessWidget {
  const ProductPurchasePanel({
    required this.product,
    required this.onAddToCart,
    super.key,
  });

  final Product product;
  final ValueChanged<Product> onAddToCart;

  @override
  Widget build(BuildContext context) {
    final stock = product.inventory?.stock ?? 0;
    final stockLow = stock > 0 && stock < 3;
    final hasStock = stock > 0;
    final volume = product.volumeMl == null ? null : '${product.volumeMl} ml';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.block),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: AppShadows.base,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.brand.name,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.name,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoChip(icon: Icons.category_outlined, label: product.category.name),
              if (volume != null)
                _InfoChip(icon: Icons.straighten_outlined, label: volume),
              _InfoChip(
                icon: hasStock
                    ? Icons.inventory_2_outlined
                    : Icons.remove_shopping_cart_outlined,
                label: hasStock
                    ? stockLow
                          ? 'Ultimas $stock unidades'
                          : 'Stock: $stock'
                    : 'Sin stock',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            formatPrice(product.price),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: AppColors.primaryHover,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: hasStock ? () => onAddToCart(product) : null,
              icon: const Icon(Icons.add_shopping_cart),
              label: Text(hasStock ? 'Agregar al carrito' : 'Sin stock'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgSoftPink,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
