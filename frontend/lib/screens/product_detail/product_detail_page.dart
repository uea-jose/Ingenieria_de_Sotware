import 'package:flutter/material.dart';

import '../../app/app_design_tokens.dart';
import '../../data/api/api_service.dart';
import '../../models/product.dart';
import '../../widgets/feedback/error_view.dart';
import '../../widgets/feedback/loading_view.dart';
import '../../widgets/layout/top_navigation.dart';
import '../../widgets/product/product_detail_header.dart';
import '../../widgets/product/product_future_accords_placeholder.dart';
import '../../widgets/product/product_info_section.dart';
import '../../widgets/product/product_purchase_panel.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({
    required this.productId,
    required this.cartCount,
    required this.onAddToCart,
    this.initialProduct,
    super.key,
  });

  final int productId;
  final int cartCount;
  final Product? initialProduct;
  final ValueChanged<Product> onAddToCart;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late Future<Product> _productFuture;

  @override
  void initState() {
    super.initState();
    _productFuture = widget.initialProduct == null
        ? ApiService.loadProductById(widget.productId)
        : Future.value(widget.initialProduct);
  }

  void _reload() {
    setState(() {
      _productFuture = ApiService.loadProductById(widget.productId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final sidePadding = AppLayout.horizontalPadding(viewportWidth);

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: FutureBuilder<Product>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingView();
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return ErrorView(
              message: 'No pudimos cargar el detalle del producto.',
              details: snapshot.error?.toString() ?? 'Producto no disponible.',
              onRetry: _reload,
            );
          }

          final product = snapshot.data!;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: TopNavigation(
                  cartCount: widget.cartCount,
                  onCatalogPressed: () => Navigator.of(context).pop(),
                  onCartPressed: () => Navigator.of(context).pop(),
                  searchBox: const SizedBox.shrink(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    sidePadding,
                    22,
                    sidePadding,
                    12,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: AppLayout.contentMaxWidth(viewportWidth),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Volver al catalogo'),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(sidePadding, 0, sidePadding, 32),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: AppLayout.contentMaxWidth(viewportWidth),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final compact = constraints.maxWidth < 820;

                          final image = ProductDetailHeader(product: product);
                          final details = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ProductPurchasePanel(
                                product: product,
                                onAddToCart: widget.onAddToCart,
                              ),
                              const SizedBox(height: 18),
                              ProductInfoSection(product: product),
                              const SizedBox(height: 18),
                              const ProductFutureAccordsPlaceholder(),
                            ],
                          );

                          if (compact) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                image,
                                const SizedBox(height: 18),
                                details,
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 5, child: image),
                              const SizedBox(width: 24),
                              Expanded(flex: 6, child: details),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
