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
      padding: EdgeInsets.fromLTRB(sidePadding, 26, sidePadding, 4),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: AppLayout.contentMaxWidth(viewportWidth),
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$visibleProducts de $totalProducts',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
