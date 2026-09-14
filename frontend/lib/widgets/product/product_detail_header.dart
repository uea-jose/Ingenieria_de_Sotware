import 'package:flutter/material.dart';

import '../../app/app_design_tokens.dart';
import '../../data/catalog/catalog_image_resolver.dart';
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
            child: _LargeProductImage(
              imageUrl: product.imageUrl,
              productName: product.name,
              brandName: product.brand.name,
            ),
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
  const _LargeProductImage({
    required this.imageUrl,
    this.productName,
    this.brandName,
  });

  final String? imageUrl;
  final String? productName;
  final String? brandName;

  @override
  Widget build(BuildContext context) {
    final resolved = _resolve();
    if (resolved == null) return const ProductPlaceholder();

    if (resolved.startsWith('assets/')) {
      return Image.asset(
        resolved,
        fit: BoxFit.cover,
        semanticLabel: 'Imagen del producto',
        errorBuilder: (_, _, _) => const ProductPlaceholder(),
      );
    }

    return Image.network(
      resolved,
      fit: BoxFit.cover,
      semanticLabel: 'Imagen del producto',
      errorBuilder: (_, _, _) => const ProductPlaceholder(),
    );
  }

  String? _resolve() {
    final own = imageUrl;
    if (own != null && own.isNotEmpty) return own;
    final name = productName;
    final brand = brandName;
    if (name == null || name.isEmpty || brand == null || brand.isEmpty) {
      return null;
    }
    return CatalogImageResolver.instance.findAsset(name: name, brand: brand);
  }
}
