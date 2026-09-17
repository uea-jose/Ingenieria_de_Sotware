import 'package:flutter/material.dart';

import '../../app/app_design_tokens.dart';
import '../../data/api/api_service.dart';
import '../../data/storage/cart_storage.dart';
import '../../models/product.dart';
import '../../widgets/feedback/app_feedback.dart';
import '../../widgets/feedback/error_view.dart';
import '../../widgets/feedback/loading_view.dart';
import '../../widgets/layout/top_navigation.dart';
import '../../widgets/product/accord_profile_panel.dart';
import '../../widgets/product/brand_info_block.dart';
import '../../widgets/product/product_detail_header.dart';
import '../../widgets/product/product_info_section.dart';
import '../../widgets/product/product_purchase_panel.dart';
import '../../widgets/product/related_products_section.dart';

/// Public route: `/producto/:id`.
///
/// Renders the full detail view of a single product. Can be reached in
/// three ways:
///
/// 1. `Navigator.pushNamed('/producto/$id', arguments: product)` from
///    the catalog / accord search. The `arguments` field is used to
///    seed the page with an already-loaded [Product], avoiding a
///    request roundtrip while the API still gets consulted for the
///    canonical response (accord profile, up-to-date stock).
/// 2. Direct URL in Web (`http://.../#/producto/23`, refresh included).
///    In this case [initialProduct] is `null` and the page loads
///    everything from the API.
/// 3. Invalid parameter (`/producto/abc`, `/producto/-1`): the router
///    hands over `productId: -1` and we render [_NotFoundView] without
///    hitting the network.
///
/// The old imperative navigation from [HomePage._openProductDetail]
/// used to pass a `cartCount` and `onAddToCart` callback. Both are now
/// optional so the page can operate standalone when reached by URL:
/// - `cartCount == null` → we read it from [CartStorage] on build.
/// - `onAddToCart == null` → the "Agregar al carrito" button writes
///    into [CartStorage] and shows an in-page toast.
class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({
    required this.productId,
    this.cartCount,
    this.onAddToCart,
    this.initialProduct,
    super.key,
  });

  final int productId;

  /// Cart badge shown in the top navigation. When `null` we compute it
  /// from [CartStorage].
  final int? cartCount;

  /// Callback invoked when the user taps "Agregar al carrito". When
  /// `null` (typical for direct URL entry) the page writes into
  /// [CartStorage] directly.
  final ValueChanged<Product>? onAddToCart;

  final Product? initialProduct;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  Future<Product>? _productFuture;

  /// Local cart count when the page is reached by URL (no parent
  /// widget tracking it in memory). Kept in state so the badge updates
  /// after tapping "Agregar al carrito" without a full reload.
  late int _fallbackCartCount;

  @override
  void initState() {
    super.initState();
    _fallbackCartCount = _readCartCountFromStorage();
    if (widget.productId <= 0) {
      _productFuture = null; // rendered as _NotFoundView
      return;
    }
    _productFuture = widget.initialProduct == null
        ? ApiService.loadProductById(widget.productId)
        : Future.value(widget.initialProduct);
  }

  void _reload() {
    if (widget.productId <= 0) return;
    setState(() {
      _productFuture = ApiService.loadProductById(widget.productId);
    });
  }

  int _readCartCountFromStorage() {
    return CartStorage.load().values.fold<int>(
      0,
      (total, quantity) => total + quantity,
    );
  }

  int get _effectiveCartCount => widget.cartCount ?? _fallbackCartCount;

  void _handleAddToCart(Product product) {
    final external = widget.onAddToCart;
    if (external != null) {
      external(product);
      return;
    }
    // Fallback path — page reached by direct URL. Write to storage
    // and reflect the change in the cart badge locally.
    final stock = product.inventory?.stock ?? 0;
    if (stock <= 0) return;

    final current = CartStorage.load();
    final previous = current[product.id] ?? 0;
    if (previous >= stock) {
      AppFeedback.warning(
        context,
        '${product.name} solo tiene $stock unidades disponibles.',
      );
      return;
    }
    current[product.id] = previous + 1;
    CartStorage.save(current);
    setState(() {
      _fallbackCartCount = current.values.fold<int>(
        0,
        (total, quantity) => total + quantity,
      );
    });
    AppFeedback.success(
      context,
      previous == 0
          ? '${product.name} agregado al carrito.'
          : 'Cantidad actualizada en el carrito.',
    );
  }

  void _goBackOrHome() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.productId <= 0 || _productFuture == null) {
      return _NotFoundScaffold(
        cartCount: _effectiveCartCount,
        onBack: _goBackOrHome,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: FutureBuilder<Product>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingView();
          }

          if (snapshot.hasError) {
            // Distinguish a "product not found" backend response from a
            // generic network error. The API throws an Exception whose
            // toString() contains "HTTP 404" when the id doesn't exist.
            final message = snapshot.error?.toString() ?? '';
            if (message.contains('HTTP 404')) {
              return _NotFoundScaffold(
                cartCount: _effectiveCartCount,
                onBack: _goBackOrHome,
              );
            }
            return ErrorView(
              message: 'No pudimos cargar el detalle del producto.',
              details: message.isEmpty ? 'Producto no disponible.' : message,
              onRetry: _reload,
            );
          }

          if (!snapshot.hasData) {
            return _NotFoundScaffold(
              cartCount: _effectiveCartCount,
              onBack: _goBackOrHome,
            );
          }

          final product = snapshot.data!;
          return _DetailBody(
            product: product,
            cartCount: _effectiveCartCount,
            onAddToCart: _handleAddToCart,
            onBack: _goBackOrHome,
          );
        },
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Main content
// ────────────────────────────────────────────────────────────────

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.product,
    required this.cartCount,
    required this.onAddToCart,
    required this.onBack,
  });

  final Product product;
  final int cartCount;
  final ValueChanged<Product> onAddToCart;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final sidePadding = AppLayout.horizontalPadding(viewportWidth);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: TopNavigation(
            cartCount: cartCount,
            onCatalogPressed: onBack,
            onCartPressed: onBack,
            searchBox: const SizedBox.shrink(),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(sidePadding, 22, sidePadding, 12),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: AppLayout.contentMaxWidth(viewportWidth),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: onBack,
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
                          onAddToCart: onAddToCart,
                        ),
                        const SizedBox(height: 18),
                        ProductInfoSection(product: product),
                        if (BrandInfoBlock.hasInfo(product.brand)) ...[
                          const SizedBox(height: 18),
                          BrandInfoBlock(brand: product.brand),
                        ],
                        const SizedBox(height: 18),
                        AccordProfilePanel(productId: product.id),
                      ],
                    );

                    if (compact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [image, const SizedBox(height: 18), details],
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
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(sidePadding, 0, sidePadding, 48),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: AppLayout.contentMaxWidth(viewportWidth),
                ),
                child: RelatedProductsSection(
                  currentProduct: product,
                  onAddToCart: onAddToCart,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Not-found view — used for invalid id (parse failure) and 404
// ────────────────────────────────────────────────────────────────

class _NotFoundScaffold extends StatelessWidget {
  const _NotFoundScaffold({required this.cartCount, required this.onBack});

  final int cartCount;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: Column(
        children: [
          TopNavigation(
            cartCount: cartCount,
            onCatalogPressed: onBack,
            onCartPressed: onBack,
            searchBox: const SizedBox.shrink(),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.search_off_outlined,
                      size: 64,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Producto no encontrado',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'El enlace que abriste no corresponde a ningún producto disponible. Puede haber sido retirado o el número no es válido.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 22),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/', (route) => false),
                      icon: const Icon(Icons.storefront_outlined),
                      label: const Text('Explorar catálogo'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
