import 'package:flutter/material.dart';

import '../../app/app_design_tokens.dart';
import '../../data/api/api_service.dart';
import '../../models/product.dart';
import '../catalog/product_card.dart';

/// Two horizontal carousels shown at the bottom of the product detail:
/// "Más de {marca}" and "También te podría gustar" (misma categoría).
///
/// Both lists are loaded from `GET /productos` with server-side filters
/// (`marcaId=` / `categoriaId=`). The section:
/// - Excludes the current product from both lists.
/// - Removes any product from the "categoría" list that already appears
///   in the "marca" list, so duplicates never show up twice.
/// - Hides itself silently when both lists come back empty.
///
/// The tap on a card navigates via `Navigator.pushNamed('/producto/$id')`
/// with the product as `arguments` — same pattern used from the catalog.
class RelatedProductsSection extends StatefulWidget {
  const RelatedProductsSection({
    required this.currentProduct,
    required this.onAddToCart,
    super.key,
  });

  final Product currentProduct;
  final ValueChanged<Product> onAddToCart;

  @override
  State<RelatedProductsSection> createState() => _RelatedProductsSectionState();
}

class _RelatedProductsSectionState extends State<RelatedProductsSection> {
  late Future<_RelatedBundle> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant RelatedProductsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentProduct.id != widget.currentProduct.id) {
      setState(() => _future = _load());
    }
  }

  Future<_RelatedBundle> _load() async {
    // Two parallel requests: same brand and same category. Both come
    // through /productos with filters that the backend already handles.
    final results = await Future.wait([
      ApiService.loadRelatedProducts(
        excludeId: widget.currentProduct.id,
        brandId: widget.currentProduct.brand.id,
      ),
      ApiService.loadRelatedProducts(
        excludeId: widget.currentProduct.id,
        categoryId: widget.currentProduct.category.id,
      ),
    ]);
    final byBrand = results[0];
    final byBrandIds = byBrand.map((p) => p.id).toSet();
    final byCategoryDedup = results[1]
        .where((p) => !byBrandIds.contains(p.id))
        .toList(growable: false);
    return _RelatedBundle(
      brandName: widget.currentProduct.brand.name,
      byBrand: byBrand,
      byCategory: byCategoryDedup,
    );
  }

  void _openProduct(BuildContext context, Product product) {
    Navigator.of(
      context,
    ).pushNamed('/producto/${product.id}', arguments: product);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_RelatedBundle>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          // Small silent placeholder — related products are non-critical.
          return const SizedBox(height: 32);
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final bundle = snapshot.data!;
        final blocks = <Widget>[];

        if (bundle.byBrand.isNotEmpty) {
          blocks.add(
            _RelatedRow(
              title: 'Más de ${bundle.brandName}',
              products: bundle.byBrand,
              onOpen: (p) => _openProduct(context, p),
              onAddToCart: widget.onAddToCart,
            ),
          );
        }
        if (bundle.byCategory.isNotEmpty) {
          if (blocks.isNotEmpty) blocks.add(const SizedBox(height: 24));
          blocks.add(
            _RelatedRow(
              title: 'También te podría gustar',
              products: bundle.byCategory,
              onOpen: (p) => _openProduct(context, p),
              onAddToCart: widget.onAddToCart,
            ),
          );
        }

        if (blocks.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: blocks,
        );
      },
    );
  }
}

class _RelatedBundle {
  const _RelatedBundle({
    required this.brandName,
    required this.byBrand,
    required this.byCategory,
  });

  final String brandName;
  final List<Product> byBrand;
  final List<Product> byCategory;
}

class _RelatedRow extends StatelessWidget {
  const _RelatedRow({
    required this.title,
    required this.products,
    required this.onOpen,
    required this.onAddToCart,
  });

  final String title;
  final List<Product> products;
  final ValueChanged<Product> onOpen;
  final ValueChanged<Product> onAddToCart;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 2),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        SizedBox(
          height: 460,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (_, index) {
              final product = products[index];
              return SizedBox(
                width: 260,
                child: ProductCard(
                  product: product,
                  onAddToCart: onAddToCart,
                  onViewDetails: onOpen,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
