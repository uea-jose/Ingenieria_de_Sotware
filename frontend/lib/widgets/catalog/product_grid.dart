import 'package:flutter/material.dart';

import '../../app/app_design_tokens.dart';
import '../../models/product.dart';
import 'product_card.dart';

class ProductGrid extends StatelessWidget {
  const ProductGrid({
    required this.products,
    required this.onAddToCart,
    required this.onViewDetails,
    super.key,
  });

  final List<Product> products;
  final ValueChanged<Product> onAddToCart;
  final ValueChanged<Product> onViewDetails;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final sideInset = AppLayout.containerSideInset(
          constraints.crossAxisExtent,
        );
        final contentWidth = constraints.crossAxisExtent - (sideInset * 2);
        final columns = contentWidth >= 960
            ? 4
            : contentWidth >= 720
            ? 3
            : contentWidth >= 360
            ? 2
            : 1;

        return SliverPadding(
          padding: EdgeInsets.fromLTRB(sideInset, 4, sideInset, 48),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) => ProductCard(
                product: products[index],
                onAddToCart: onAddToCart,
                onViewDetails: onViewDetails,
              ),
              childCount: products.length,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: columns == 2 ? 14 : 18,
              crossAxisSpacing: columns == 2 ? 12 : 18,
              mainAxisExtent: columns == 1
                  ? 460
                  : columns == 2
                  ? 366
                  : 384,
            ),
          ),
        );
      },
    );
  }
}
