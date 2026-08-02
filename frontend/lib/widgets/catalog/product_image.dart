import 'package:flutter/material.dart';

import '../../app/app_design_tokens.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({required this.imageUrl, super.key});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    final compact = MediaQuery.sizeOf(context).width < 560;
    final height = compact ? 178.0 : 210.0;

    if (url != null && url.isNotEmpty) {
      return SizedBox(
        height: height,
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

    return SizedBox(
      height: height,
      width: double.infinity,
      child: const ProductPlaceholder(),
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
          colors: [AppColors.bgSoftPink, AppColors.bgLavender],
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
            borderRadius: BorderRadius.circular(AppRadii.block),
            boxShadow: AppShadows.base,
          ),
          child: const Icon(
            Icons.spa_outlined,
            color: AppColors.primary,
            size: 42,
          ),
        ),
      ),
    );
  }
}
