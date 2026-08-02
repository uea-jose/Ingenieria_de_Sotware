import 'package:flutter/material.dart';

import '../../app/app_design_tokens.dart';
import 'brand_mark.dart';
import 'cart_nav_button.dart';
import 'premium_announcement_bar.dart';

class TopNavigation extends StatelessWidget {
  const TopNavigation({
    required this.onCatalogPressed,
    required this.onCartPressed,
    required this.cartCount,
    required this.searchBox,
    super.key,
  });

  final VoidCallback onCatalogPressed;
  final VoidCallback onCartPressed;
  final int cartCount;
  final Widget searchBox;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final pagePadding = screenWidth < 560 ? 16.0 : 24.0;

    return Container(
      color: AppColors.bgPage,
      child: Column(
        children: [
          const PremiumAnnouncementBar(),
          Padding(
            padding: EdgeInsets.fromLTRB(pagePadding, 18, pagePadding, 16),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: AppLayout.contentMaxWidth(screenWidth),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadii.block),
                    border: Border.all(color: AppColors.borderSoft),
                    boxShadow: AppShadows.base,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth < 560 ? 14 : 18),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 680;
                        final comfortable = constraints.maxWidth >= 1180;
                        final navLinks = Wrap(
                          spacing: 6,
                          runSpacing: 8,
                          alignment: compact
                              ? WrapAlignment.center
                              : WrapAlignment.start,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _NavButton(
                              label: 'Inicio',
                              active: true,
                              onPressed: () {},
                            ),
                            _NavButton(
                              label: 'Perfumes',
                              onPressed: onCatalogPressed,
                            ),
                            _NavButton(
                              label: 'Mujer',
                              onPressed: onCatalogPressed,
                            ),
                            _NavButton(
                              label: 'Hombre',
                              onPressed: onCatalogPressed,
                            ),
                            _NavButton(
                              label: 'Unisex',
                              onPressed: onCatalogPressed,
                            ),
                            _NavButton(
                              label: 'Marcas',
                              onPressed: onCatalogPressed,
                            ),
                            _NavButton(
                              label: 'Promociones',
                              onPressed: onCatalogPressed,
                            ),
                          ],
                        );
                        final userActions = Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.end,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            IconButton(
                              tooltip: 'Favoritos visuales',
                              onPressed: () {},
                              icon: const Icon(Icons.favorite_border),
                            ),
                            CartNavButton(
                              count: cartCount,
                              onPressed: onCartPressed,
                            ),
                            OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.person_outline),
                              label: const Text('Iniciar sesion'),
                            ),
                          ],
                        );

                        return Column(
                          children: [
                            if (comfortable)
                              Row(
                                children: [
                                  const BrandMark(),
                                  const SizedBox(width: 32),
                                  Expanded(child: navLinks),
                                  const SizedBox(width: 14),
                                  userActions,
                                ],
                              )
                            else ...[
                              if (compact)
                                Column(
                                  children: [
                                    const BrandMark(),
                                    const SizedBox(height: 12),
                                    userActions,
                                  ],
                                )
                              else
                                Row(
                                  children: [
                                    const BrandMark(),
                                    const Spacer(),
                                    Flexible(child: userActions),
                                  ],
                                ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: compact
                                    ? Alignment.center
                                    : Alignment.centerLeft,
                                child: navLinks,
                              ),
                            ],
                            const SizedBox(height: 18),
                            Semantics(
                              textField: true,
                              label: 'Buscar perfumes, marcas o categorias',
                              child: searchBox,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.label,
    required this.onPressed,
    this.active = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return _AnimatedNavLink(label: label, active: active, onPressed: onPressed);
  }
}

class _AnimatedNavLink extends StatefulWidget {
  const _AnimatedNavLink({
    required this.label,
    required this.active,
    required this.onPressed,
  });

  final String label;
  final bool active;
  final VoidCallback onPressed;

  @override
  State<_AnimatedNavLink> createState() => _AnimatedNavLinkState();
}

class _AnimatedNavLinkState extends State<_AnimatedNavLink> {
  bool _hovered = false;
  bool _focused = false;

  bool get _showUnderline => widget.active || _hovered || _focused;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return FocusableActionDetector(
      onShowFocusHighlight: (focused) => setState(() => _focused = focused),
      onShowHoverHighlight: (hovered) => setState(() => _hovered = hovered),
      mouseCursor: SystemMouseCursors.click,
      child: TextButton(
        onPressed: widget.onPressed,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          backgroundColor: _hovered || _focused || widget.active
              ? AppColors.bgSoftPink
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedScale(
              scale: _showUnderline ? 1 : 0,
              alignment: Alignment.centerLeft,
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 240),
              curve: Curves.easeOut,
              child: Container(
                width: _textUnderlineWidth(widget.label),
                height: 2,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _textUnderlineWidth(String text) {
    return (text.length * 7.4).clamp(34.0, 92.0);
  }
}
