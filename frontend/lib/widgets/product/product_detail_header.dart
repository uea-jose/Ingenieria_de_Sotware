import 'package:flutter/material.dart';

import '../../app/app_design_tokens.dart';
import '../../models/product.dart';
import '../catalog/product_image.dart';

class ProductDetailHeader extends StatelessWidget {
  const ProductDetailHeader({required this.product, super.key});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final stock = product.inventory?.stock ?? 0;
    final hasStock = stock > 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.block),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: AppShadows.base,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 420,
            child: _LargeProductImage(imageUrl: product.imageUrl),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Icon(
                  hasStock
                      ? Icons.check_circle_outline
                      : Icons.highlight_off_outlined,
                  color: hasStock ? AppColors.success : AppColors.error,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasStock
                        ? 'Disponible para agregar al carrito'
                        : 'Producto sin stock disponible',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
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

class _LargeProductImage extends StatelessWidget {
  const _LargeProductImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;

    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        semanticLabel: 'Imagen del producto',
        errorBuilder: (context, error, stackTrace) =>
            const ProductPlaceholder(),
      );
    }

    return const ProductPlaceholder();
  }
}
