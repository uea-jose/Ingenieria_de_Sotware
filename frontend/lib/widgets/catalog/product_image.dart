import 'package:flutter/material.dart';

import '../../app/app_design_tokens.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({required this.imageUrl, this.compact = false, super.key});

  final String? imageUrl;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    final useCompact = compact || MediaQuery.sizeOf(context).width < 560;
    final height = useCompact ? 112.0 : 138.0;

    if (url != null && url.isNotEmpty) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          semanticLabel: 'Imagen del producto',
          errorBuilder: (context, error, stackTrace) =>
              ProductPlaceholder(compact: useCompact),
        ),
      );
    }

    return SizedBox(
      height: height,
      width: double.infinity,
      child: ProductPlaceholder(compact: useCompact),
    );
  }
}

class ProductPlaceholder extends StatelessWidget {
  const ProductPlaceholder({this.compact = false, super.key});

  final bool compact;

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
          width: compact ? 62 : 68,
          height: compact ? 88 : 98,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(AppRadii.block),
            boxShadow: AppShadows.base,
          ),
          child: Icon(
            Icons.spa_outlined,
            color: AppColors.primary,
            size: compact ? 30 : 32,
          ),
        ),
      ),
    );
  }
}
