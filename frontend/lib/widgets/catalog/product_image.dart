import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({required this.imageUrl, super.key});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;

    if (url != null && url.isNotEmpty) {
      return SizedBox(
        height: 210,
        width: double.infinity,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          semanticLabel: 'Imagen del producto',
          errorBuilder: (context, error, stackTrace) =>
              const ProductPlaceholder(),
        ),
      );
    }

    return const SizedBox(
      height: 210,
      width: double.infinity,
      child: ProductPlaceholder(),
    );
  }
}

class ProductPlaceholder extends StatelessWidget {
  const ProductPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF5E9D8), Color(0xFFE0D4C2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Container(
          width: 96,
          height: 138,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: const Icon(
            Icons.spa_outlined,
            color: Color(0xFF145647),
            size: 42,
          ),
        ),
      ),
    );
  }
}
