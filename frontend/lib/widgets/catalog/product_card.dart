import 'package:flutter/material.dart';

import '../../app/app_design_tokens.dart';
import '../../models/product.dart';
import 'product_badges.dart';
import 'product_image.dart';

class ProductCard extends StatefulWidget {
  const ProductCard({
    required this.product,
    required this.onAddToCart,
    required this.onViewDetails,
    super.key,
  });

  final Product product;
  final ValueChanged<Product> onAddToCart;
  final ValueChanged<Product> onViewDetails;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final compact = MediaQuery.sizeOf(context).width < 560;
    final dense = MediaQuery.sizeOf(context).width >= 900;
    final enableHover = !compact;
    final stock = product.inventory?.stock ?? 0;
    final stockLow = stock < 3;
    final hasStock = stock > 0;
    final statusText = stockLow ? 'Ultimas unidades' : 'Disponible';

    return LayoutBuilder(
      builder: (context, constraints) {
        final mini = constraints.maxWidth < 230;
        final tight = mini || dense || constraints.maxWidth < 360;

        return MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: Semantics(
            container: true,
            label:
                '${product.name}, marca ${product.brand.name}, precio ${product.price.toStringAsFixed(2)} dolares, $statusText',
            child: AnimatedContainer(
              duration: enableHover
                  ? const Duration(milliseconds: 180)
                  : Duration.zero,
              curve: Curves.easeOut,
              transform: Matrix4.translationValues(
                0.0,
                enableHover && _hovered ? -4.0 : 0.0,
                0.0,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.card),
                boxShadow: compact
                    ? AppShadows.mobile
                    : _hovered
                    ? AppShadows.hover
                    : AppShadows.base,
              ),
              child: Card(
                elevation: 0,
                color: AppColors.surface,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  side: BorderSide(
                    color: _hovered ? AppColors.primary : AppColors.borderSoft,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        ProductImage(
                          imageUrl: product.imageUrl,
                          compact: tight,
                        ),
                        Positioned(
                          left: dense ? 10 : 14,
                          top: dense ? 10 : 14,
                          child: ProductStatusBadge(
                            text: statusText,
                            warning: stockLow,
                            compact: tight,
                          ),
                        ),
                        Positioned(
                          right: dense ? 8 : 12,
                          top: dense ? 8 : 12,
                          child: SizedBox.square(
                            dimension: mini ? 34 : 48,
                            child: Material(
                              color: Colors.white.withValues(alpha: 0.92),
                              shape: const CircleBorder(),
                              child: IconButton(
                                tooltip: 'Guardar en favoritos',
                                padding: EdgeInsets.zero,
                                onPressed: () =>
                                    _showFavoriteMessage(context, product),
                                icon: Icon(
                                  Icons.favorite_border,
                                  color: AppColors.primary,
                                  size: mini ? 20 : 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(
                          mini
                              ? 9
                              : compact
                              ? 12
                              : 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.brand.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                              ),
                            ),
                            SizedBox(
                              height: mini
                                  ? 3
                                  : compact
                                  ? 5
                                  : 4,
                            ),
                            Text(
                              product.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    height: 1.1,
                                    fontSize: mini
                                        ? 14
                                        : compact || tight
                                        ? 17
                                        : 18,
                                  ),
                            ),
                            SizedBox(
                              height: mini
                                  ? 3
                                  : compact
                                  ? 5
                                  : 4,
                            ),
                            Text(
                              product.category.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: mini ? 10.5 : 12,
                              ),
                            ),
                            SizedBox(
                              height: mini
                                  ? 4
                                  : compact
                                  ? 6
                                  : 6,
                            ),
                            if (!tight)
                              Text(
                                product.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  height: 1.25,
                                  fontSize: 12,
                                ),
                              ),
                            const Spacer(),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '\$${product.price.toStringAsFixed(2)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.textPrimary,
                                          fontSize: mini
                                              ? 16
                                              : tight
                                              ? 18
                                              : compact
                                              ? null
                                              : 22,
                                        ),
                                  ),
                                ),
                                StockBadge(
                                  stock: stock,
                                  hasStock: hasStock,
                                  stockLow: stockLow,
                                  compact: tight,
                                ),
                              ],
                            ),
                            SizedBox(
                              height: mini
                                  ? 2
                                  : compact
                                  ? 6
                                  : 4,
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size(0, mini ? 24 : 30),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () => widget.onViewDetails(product),
                                icon: Icon(
                                  Icons.visibility_outlined,
                                  size: mini ? 13 : 15,
                                ),
                                label: Text(mini ? 'Detalle' : 'Ver detalle'),
                              ),
                            ),
                            SizedBox(
                              height: mini
                                  ? 4
                                  : compact
                                  ? 6
                                  : 4,
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: mini || tight ? 8 : 16,
                                    vertical: mini || tight ? 7 : 11,
                                  ),
                                  minimumSize: Size.fromHeight(
                                    mini || tight ? 32 : 40,
                                  ),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: hasStock
                                    ? () => widget.onAddToCart(product)
                                    : null,
                                icon: Icon(
                                  Icons.add_shopping_cart,
                                  size: mini || tight ? 17 : 20,
                                ),
                                label: Text(
                                  hasStock
                                      ? mini
                                            ? 'Agregar'
                                            : 'Agregar al carrito'
                                      : 'Sin stock',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showFavoriteMessage(BuildContext context, Product product) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${product.name} marcado como favorito para una siguiente iteracion.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
