import 'package:flutter/material.dart';

import '../../models/product.dart';
import 'product_thumbnail.dart';
import 'quantity_stepper.dart';

class CartProductRow extends StatelessWidget {
  const CartProductRow({
    required this.product,
    required this.quantity,
    required this.onQuantityChanged,
    super.key,
  });

  final Product product;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    final stock = product.inventory?.stock ?? 0;
    final lineSubtotal = product.price * quantity;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8F4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E0D5)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ProductThumbnail(imageUrl: product.imageUrl),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '${product.brand.name} Ã‚Â· ${product.category.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF68645D)),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  children: [
                    Text(
                      '\$${product.price.toStringAsFixed(2)} c/u',
                      style: const TextStyle(
                        color: Color(0xFF145647),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Subtotal: \$${lineSubtotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'Disponible: $stock',
                      style: const TextStyle(color: Color(0xFF68645D)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          QuantityStepper(
            quantity: quantity,
            maxQuantity: stock,
            onChanged: onQuantityChanged,
          ),
        ],
      ),
    );
  }
}
