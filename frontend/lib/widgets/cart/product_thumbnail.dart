import 'package:flutter/material.dart';

import '../../app/app_design_tokens.dart';
import '../../data/catalog/catalog_image_resolver.dart';

/// Small square thumbnail used inside the cart panel. Follows the same
/// three-level image resolution as the catalog `ProductImage`: own URL →
/// bundled catalog match by name/brand → Essenza logo placeholder.
class ProductThumbnail extends StatelessWidget {
  const ProductThumbnail({
    required this.imageUrl,
    this.productName,
    this.brandName,
    super.key,
  });

  final String? imageUrl;
  final String? productName;
  final String? brandName;

  @override
  Widget build(BuildContext context) {
    final resolved = _resolve();
    if (resolved == null) return const CartProductPlaceholder();

    return SizedBox(
      width: 70,
      height: 70,
      child: resolved.startsWith('assets/')
          ? Image.asset(
              resolved,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const CartProductPlaceholder(),
            )
          : Image.network(
              resolved,
              fit: BoxFit.cover,
              semanticLabel: 'Imagen del producto en carrito',
              errorBuilder: (_, _, _) => const CartProductPlaceholder(),
            ),
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

class CartProductPlaceholder extends StatelessWidget {
  const CartProductPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      color: Colors.white,
      padding: const EdgeInsets.all(10),
      child: Image.asset(
        'assets/img/essenza_logo.png',
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) =>
            const Icon(Icons.spa_outlined, color: AppColors.primary, size: 28),
      ),
    );
  }
}
