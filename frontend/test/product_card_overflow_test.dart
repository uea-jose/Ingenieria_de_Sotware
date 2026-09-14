// Guard against the "BOTTOM OVERFLOWED BY N PIXELS" regression on
// ProductCard. Renders the card at the smallest and largest heights used
// by the grid (mainAxisExtent 334 / 348 / 390) with a fresh Product and
// asserts the framework produces no exceptions and no widget rendered its
// content beyond its layout size.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/models/brand.dart';
import 'package:frontend/models/category.dart';
import 'package:frontend/models/inventory.dart';
import 'package:frontend/models/product.dart';
import 'package:frontend/widgets/catalog/product_card.dart';

Product _sample({String name = 'Sauvage'}) {
  return Product(
    id: 1,
    name: name,
    code: 'TST-001',
    description: 'Fragancia intensa con notas amaderadas.',
    price: 129.99,
    volumeMl: 100,
    imageUrl: null, // triggers logo placeholder / catalog resolver fallback
    active: true,
    categoryId: 1,
    brandId: 1,
    brand: const Brand(
      id: 1,
      name: 'Dior',
      country: 'Francia',
      description: '',
      active: true,
    ),
    category: const Category(
      id: 1,
      name: 'Perfumes',
      description: '',
      active: true,
    ),
    inventory: const Inventory(stock: 9, minimumStock: 3, location: 'Bodega'),
  );
}

Future<void> _pumpCardAt(
  WidgetTester tester, {
  required double width,
  required double height,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            height: height,
            child: ProductCard(
              product: _sample(),
              onAddToCart: (_) {},
              onViewDetails: (_) {},
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  // Real widths that come out of ProductGrid at various viewport sizes:
  //  - 174 px  → columns=2 at the 360-px viewport boundary
  //  - 227 px  → columns=3 at 720 px
  //  - 255 px  → columns=4 at 1080 px (dense desktop)
  //  - 325 px  → columns=4 at 1360 px (max content width)
  //  - 348 px  → columns=1 fallback
  // And the mainAxisExtent values: 334 / 348 / 390.
  const widths = [174.0, 200.0, 227.0, 255.0, 300.0, 325.0, 348.0];
  const heights = [334.0, 348.0, 390.0];

  testWidgets('ProductCard never overflows at any grid size', (tester) async {
    for (final w in widths) {
      for (final h in heights) {
        await _pumpCardAt(tester, width: w, height: h);
        await tester.pump();
        expect(
          tester.takeException(),
          isNull,
          reason: 'card ${w.toInt()}×${h.toInt()} overflowed',
        );
      }
    }
  });
}
