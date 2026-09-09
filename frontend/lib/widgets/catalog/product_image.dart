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
    final height = useCompact ? 88.0 : 122.0;

    if (url != null && url.isNotEmpty) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: Image.network(
          url,
          fit: BoxFit.contain,
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
      decoration: BoxDecoration(
        color: AppColors.bgPage,
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderSoft.withValues(alpha: 0.7),
          ),
        ),
      ),
      child: Center(
        child: Container(
          width: compact ? 52 : 62,
          height: compact ? 72 : 90,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: Icon(
            Icons.spa_outlined,
            color: AppColors.primary,
            size: compact ? 26 : 30,
          ),
        ),
      ),
    );
  }
}
