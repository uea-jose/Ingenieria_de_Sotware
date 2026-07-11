import 'package:flutter/material.dart';

import '../../models/product.dart';
import 'product_card.dart';

class ProductGrid extends StatelessWidget {
  const ProductGrid({
    required this.products,
    required this.onAddToCart,
    super.key,
  });

  final List<Product> products;
  final ValueChanged<Product> onAddToCart;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 48),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.crossAxisExtent;
          final columns = width >= 1180
              ? 4
              : width >= 860
              ? 3
              : width >= 560
              ? 2
              : 1;

          return SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) => ProductCard(
                product: products[index],
                onAddToCart: onAddToCart,
              ),
              childCount: products.length,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 18,
              crossAxisSpacing: 18,
              mainAxisExtent: 486,
            ),
          );
        },
      ),
    );
  }
}
