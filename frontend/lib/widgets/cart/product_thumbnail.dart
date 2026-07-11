import 'package:flutter/material.dart';

class ProductThumbnail extends StatelessWidget {
  const ProductThumbnail({required this.imageUrl, super.key});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url != null && url.isNotEmpty) {
      return SizedBox(
        width: 70,
        height: 70,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          semanticLabel: 'Imagen del producto en carrito',
          errorBuilder: (context, error, stackTrace) =>
              const CartProductPlaceholder(),
        ),
      );
    }

    return const CartProductPlaceholder();
  }
}

class CartProductPlaceholder extends StatelessWidget {
  const CartProductPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF5E9D8), Color(0xFFE0D4C2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(Icons.spa_outlined, color: Color(0xFF145647), size: 28),
    );
  }
}
