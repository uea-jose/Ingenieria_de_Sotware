import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../app/app_design_tokens.dart';
import '../../data/catalog/catalog_image_resolver.dart';
import 'hover_product_image.dart';

/// UI-only experiment: swap the perfume photo on hover for a single product
/// (Good Girl — Carolina Herrera). Keeps the rest of the catalog untouched.
///
/// The two assets are shipped locally and already declared under the
/// `assets/productos/` folder in `pubspec.yaml`.
const String _goodGirlPrimaryAsset =
    'assets/productos/good_girl/good_girl_primary.jpg';
const String _goodGirlHoverAsset =
    'assets/productos/good_girl/good_girl_hover.jpg';

bool _isGoodGirlCarolinaHerrera({String? name, String? brand}) {
  final n = name?.trim().toLowerCase();
  final b = brand?.trim().toLowerCase();
  return n == 'good girl' && b == 'carolina herrera';
}

/// Renders a product image with three-level fallback:
///
/// 1. If the product has its own [imageUrl] (asset path or `http/https` URL),
///    it is used verbatim (`BoxFit.contain`).
/// 2. Otherwise, when [productName] and [brandName] are provided, we ask the
///    [CatalogImageResolver] for a match against the bundled reference
///    catalog. If it finds one, we use it.
/// 3. Fallback: [ProductPlaceholder] — the Essenza logo on a white card.
///
/// The image is rendered with a subtle **drop shadow** that follows the
/// bottle's silhouette (via `ImageFiltered` blur on a darkened copy stacked
/// behind the real image). This produces the elevated / 3-D look used by
/// e-commerce sites like Carolina Herrera, Primor, Jomashop, etc.
///
/// The widget does NOT impose a fixed height — put it inside a [Flexible] or
/// [Expanded] so the parent decides how much room it gets.
class ProductImage extends StatelessWidget {
  const ProductImage({
    required this.imageUrl,
    this.compact = false,
    this.productName,
    this.brandName,
    super.key,
  });

  final String? imageUrl;
  final bool compact;
  final String? productName;
  final String? brandName;

  @override
  Widget build(BuildContext context) {
    final useCompact = compact || MediaQuery.sizeOf(context).width < 560;

    // ── UI-only experiment: hover-swap for Good Girl · Carolina Herrera ──
    // The two assets are packaged with the app; no backend / model changes.
    // The rest of the catalog goes through the standard resolver below.
    if (_isGoodGirlCarolinaHerrera(name: productName, brand: brandName)) {
      return Container(
        width: double.infinity,
        color: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: useCompact ? 4 : 6,
          vertical: useCompact ? 4 : 6,
        ),
        alignment: Alignment.center,
        child: HoverProductImage(
          primaryAsset: _goodGirlPrimaryAsset,
          hoverAsset: _goodGirlHoverAsset,
          compact: useCompact,
          semanticLabel: 'Good Girl de Carolina Herrera',
        ),
      );
    }

    final resolved = _resolve();

    if (resolved == null) {
      return ProductPlaceholder(compact: useCompact);
    }

    final image = resolved.startsWith('assets/')
        ? Image.asset(
            resolved,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => ProductPlaceholder(compact: useCompact),
          )
        : Image.network(
            resolved,
            fit: BoxFit.contain,
            semanticLabel: 'Imagen del producto',
            errorBuilder: (context, error, stackTrace) =>
                ProductPlaceholder(compact: useCompact),
          );

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: useCompact ? 4 : 6,
        vertical: useCompact ? 4 : 6,
      ),
      alignment: Alignment.center,
      child: _BottleShadow(compact: useCompact, child: image),
    );
  }

  /// Pick the best image source available: own URL first, catalog match second.
  String? _resolve() {
    final own = imageUrl;
    if (own != null && own.isNotEmpty) return own;

    final name = productName;
    final brand = brandName;
    if (name == null || name.isEmpty || brand == null || brand.isEmpty) {
      return null;
    }
    return CatalogImageResolver.instance.findAsset(name: name, brand: brand);
  }
}

/// Draws a soft blurred drop shadow behind [child] that follows the shape of
/// the image itself (PNG/WEBP alpha channel). The result is a bottle that
/// looks lifted off the card, matching the 3-D feel of luxury perfume shops.
class _BottleShadow extends StatelessWidget {
  const _BottleShadow({required this.child, required this.compact});

  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final blur = compact ? 10.0 : 14.0;
    final drop = compact ? 6.0 : 9.0;
    // Shadow tint: pure black is too harsh, so we soften it. The alpha carries
    // most of the effect.
    const shadowColor = Color(0xFF1C1B1A);

    return Stack(
      alignment: Alignment.center,
      children: [
        // Shadow layer: same image, tinted dark, translated down, blurred.
        Positioned.fill(
          child: IgnorePointer(
            child: Transform.translate(
              offset: Offset(0, drop),
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    shadowColor.withValues(alpha: 0.38),
                    BlendMode.srcATop,
                  ),
                  // Wrap in Opacity so pure white pixels inside the bottle
                  // don't wash out the shadow.
                  child: Opacity(opacity: 0.9, child: child),
                ),
              ),
            ),
          ),
        ),
        // Actual product image on top.
        child,
      ],
    );
  }
}

/// Empty-state card shown when we have no photo at all: white card with the
/// store logo centred. Matches the perfumery e-commerce look.
class ProductPlaceholder extends StatelessWidget {
  const ProductPlaceholder({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 20 : 28,
        vertical: compact ? 12 : 18,
      ),
      child: Image.asset(
        'assets/img/essenza_logo.png',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, _, _) => Icon(
          Icons.spa_outlined,
          color: AppColors.primary,
          size: compact ? 32 : 40,
        ),
      ),
    );
  }
}
