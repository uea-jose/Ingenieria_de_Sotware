import 'package:flutter/material.dart';

import '../../models/product.dart';
import 'product_badges.dart';
import 'product_image.dart';

class ProductCard extends StatefulWidget {
  const ProductCard({
    required this.product,
    required this.onAddToCart,
    super.key,
  });

  final Product product;
  final ValueChanged<Product> onAddToCart;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final stock = product.inventory?.stock ?? 0;
    final stockLow = stock < 3;
    final hasStock = stock > 0;
    final statusText = stockLow ? 'Ultimas unidades' : 'Disponible';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Semantics(
        container: true,
        label:
            '${product.name}, marca ${product.brand.name}, precio ${product.price.toStringAsFixed(2)} dolares, $statusText',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0.0, _hovered ? -4.0 : 0.0, 0.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _hovered ? 0.12 : 0.05),
                blurRadius: _hovered ? 30 : 18,
                offset: Offset(0, _hovered ? 18 : 10),
              ),
            ],
          ),
          child: Card(
            elevation: 0,
            color: Colors.white,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: _hovered
                    ? const Color(0xFF145647)
                    : const Color(0xFFE6E1D8),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ProductImage(imageUrl: product.imageUrl),
                    Positioned(
                      left: 14,
                      top: 14,
                      child: ProductStatusBadge(
                        text: statusText,
                        warning: stockLow,
                      ),
                    ),
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Material(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: const CircleBorder(),
                        child: IconButton(
                          tooltip: 'Guardar en favoritos',
                          onPressed: () =>
                              _showFavoriteMessage(context, product),
                          icon: const Icon(
                            Icons.favorite_border,
                            color: Color(0xFF145647),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.brand.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF145647),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          product.category.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFF68645D)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF58544D),
                            height: 1.25,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '\$${product.price.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF111111),
                                    ),
                              ),
                            ),
                            StockBadge(
                              stock: stock,
                              hasStock: hasStock,
                              stockLow: stockLow,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () =>
                                _showQuickViewMessage(context, product),
                            icon: const Icon(
                              Icons.visibility_outlined,
                              size: 18,
                            ),
                            label: const Text('Vista rapida'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: hasStock
                                ? () => widget.onAddToCart(product)
                                : null,
                            icon: const Icon(Icons.add_shopping_cart),
                            label: Text(
                              hasStock ? 'Agregar al carrito' : 'Sin stock',
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

  void _showQuickViewMessage(BuildContext context, Product product) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Vista rapida de ${product.name} preparada para el siguiente modulo.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
