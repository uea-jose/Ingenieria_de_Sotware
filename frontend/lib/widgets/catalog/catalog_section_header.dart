import 'package:flutter/material.dart';

import '../../app/app_design_tokens.dart';

class CatalogSectionHeader extends StatelessWidget {
  const CatalogSectionHeader({
    required this.visibleProducts,
    required this.totalProducts,
    super.key,
  });

  final int visibleProducts;
  final int totalProducts;

  @override
  Widget build(BuildContext context) {
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final sidePadding = AppLayout.horizontalPadding(viewportWidth);

    return Padding(
      padding: EdgeInsets.fromLTRB(sidePadding, 34, sidePadding, 4),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: AppLayout.contentMaxWidth(viewportWidth),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 560;
              final copy = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Catalogo de fragancias',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Busca por producto, marca o categoria. El stock se muestra antes de agregar al carrito.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              );
              final count = Text(
                '$visibleProducts de $totalProducts',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [copy, const SizedBox(height: 10), count],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: copy),
                  const SizedBox(width: 18),
                  count,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
