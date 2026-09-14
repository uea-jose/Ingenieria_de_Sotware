import 'package:flutter/material.dart';

import '../../app/app_design_tokens.dart';
import '../../models/product.dart';
import 'product_badges.dart';
import 'product_image.dart';

/// Product card for the storefront grid.
///
/// Fixed structural rule: the header row (badge + logo + favourite), the
/// meta text (brand/name/category) and the bottom block (price + stock +
/// "Ver detalle" + "Agregar al carrito") always take their natural height.
/// The perfume image sits in an [Expanded] between them so it takes exactly
/// whatever space is left — it cannot overflow the card nor push the
/// buttons out.
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Header — availability chip · store logo · favourite
                    _CardHeaderRow(
                      statusText: statusText,
                      stockLow: stockLow,
                      compact: tight,
                      mini: mini,
                      onFavorite: () => _showFavoriteMessage(context, product),
                    ),

                    // 2. Meta text — brand · name · category
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        mini ? 10 : 14,
                        mini ? 6 : 8,
                        mini ? 10 : 14,
                        0,
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
                          SizedBox(height: mini ? 2 : 3),
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
                                      ? 16
                                      : 18,
                                ),
                          ),
                          SizedBox(height: mini ? 2 : 3),
                          Text(
                            product.category.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: mini ? 10.5 : 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 3. Hero image — flexible, takes whatever height is left.
                    //   Padding is minimal so the bottle gets protagonism;
                    //   the widget handles its own drop shadow / breathing.
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          mini ? 4 : 6,
                          mini ? 4 : 6,
                          mini ? 4 : 6,
                          mini ? 6 : 10,
                        ),
                        child: ProductImage(
                          imageUrl: product.imageUrl,
                          productName: product.name,
                          brandName: product.brand.name,
                          compact: tight,
                        ),
                      ),
                    ),

                    // 4. Bottom block — price + stock + actions (fixed size).
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        mini ? 10 : 14,
                        0,
                        mini ? 10 : 14,
                        mini ? 10 : 14,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                          SizedBox(height: mini ? 4 : 6),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size(0, mini ? 24 : 30),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () => widget.onViewDetails(product),
                              icon: Icon(
                                Icons.visibility_outlined,
                                size: mini ? 13 : 15,
                              ),
                              label: Text(mini ? 'Detalle' : 'Ver detalle'),
                            ),
                          ),
                          SizedBox(height: mini ? 4 : 6),
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
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

/// Circular favourite toggle. Uses a plain [GestureDetector] instead of
/// [IconButton] so the tap surface never inflates beyond [size] and can be
/// used inside tight `Row`s without triggering a right-side overflow.
class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({
    required this.size,
    required this.iconSize,
    required this.onPressed,
  });

  final double size;
  final double iconSize;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Guardar en favoritos',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPressed,
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: Icon(
              Icons.favorite_border,
              color: AppColors.primary,
              size: iconSize,
            ),
          ),
        ),
      ),
    );
  }
}

/// Top row of the product card:
///   [ Disponible ]     [ ESSENZA STORE logo ]     [ ♡ ]
///
/// The logo sits in an [Expanded] centred slot, sized as a horizontal wordmark
/// (≈ 26–32 px tall, wide enough to read "Essenza Store"). It never squeezes
/// the availability chip nor the favourite button because both are `Flexible`
/// with a fixed max footprint.
class _CardHeaderRow extends StatelessWidget {
  const _CardHeaderRow({
    required this.statusText,
    required this.stockLow,
    required this.compact,
    required this.mini,
    required this.onFavorite,
  });

  final String statusText;
  final bool stockLow;
  final bool compact;
  final bool mini;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        mini ? 6 : 10,
        mini ? 8 : 10,
        mini ? 6 : 8,
        0,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Widths at which each element can safely fit alongside the others.
          // Below the smaller threshold we drop the availability text and
          // shrink the logo so nothing ever overflows on the right side.
          final favSize = mini ? 30.0 : 34.0;
          final hideBadge = constraints.maxWidth < 190;
          final iconOnlyBadge = !hideBadge && constraints.maxWidth < 250;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (!hideBadge)
                _AvailabilityChip(
                  statusText: statusText,
                  stockLow: stockLow,
                  iconOnly: iconOnlyBadge,
                ),
              if (!hideBadge) const SizedBox(width: 4),
              Expanded(
                child: Center(
                  child: SizedBox(
                    height: mini ? 20 : 26,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Image.asset(
                        'assets/img/essenza_logo.png',
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              _FavoriteButton(
                size: favSize,
                iconSize: mini ? 16 : 18,
                onPressed: onFavorite,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Availability pill. Falls back to an icon-only pill when horizontal space
/// is tight, so it never fights with the logo or the favourite button.
class _AvailabilityChip extends StatelessWidget {
  const _AvailabilityChip({
    required this.statusText,
    required this.stockLow,
    required this.iconOnly,
  });

  final String statusText;
  final bool stockLow;
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    final bg = stockLow ? AppColors.bgPeach : AppColors.successSoft;
    final border = stockLow ? AppColors.warning : AppColors.borderSoft;
    final fg = stockLow ? AppColors.warning : AppColors.success;

    if (iconOnly) {
      return Semantics(
        label: statusText,
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(color: border),
          ),
          alignment: Alignment.center,
          child: Icon(
            stockLow ? Icons.warning_amber_rounded : Icons.check_circle_outline,
            size: 12,
            color: fg,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            stockLow ? Icons.warning_amber_rounded : Icons.check_circle_outline,
            size: 12,
            color: fg,
          ),
          const SizedBox(width: 3),
          Text(
            statusText,
            style: TextStyle(
              color: stockLow ? AppColors.textPrimary : AppColors.success,
              fontWeight: FontWeight.w900,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}
