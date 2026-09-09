import 'package:flutter/material.dart';

import '../../app/app_design_tokens.dart';
import 'account_drawer.dart';
import 'brand_mark.dart';
import 'cart_nav_button.dart';
import 'header_action_button.dart';
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
    final pagePadding = AppLayout.horizontalPadding(screenWidth);

    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          const PremiumAnnouncementBar(),
          DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: AppLayout.contentMaxWidth(screenWidth),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: pagePadding,
                    vertical: screenWidth < 760 ? 12 : 16,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final mobile = constraints.maxWidth < 760;
                      if (mobile) {
                        return _MobileHeader(
                          searchBox: searchBox,
                          cartCount: cartCount,
                          onCartPressed: onCartPressed,
                          onCatalogPressed: onCatalogPressed,
                        );
                      }

                      return _DesktopHeader(
                        searchBox: searchBox,
                        cartCount: cartCount,
                        onCartPressed: onCartPressed,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          _NavigationBar(onCatalogPressed: onCatalogPressed),
        ],
      ),
    );
  }
}

class _DesktopHeader extends StatelessWidget {
  const _DesktopHeader({
    required this.searchBox,
    required this.cartCount,
    required this.onCartPressed,
  });

  final Widget searchBox;
  final int cartCount;
  final VoidCallback onCartPressed;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 1180;

    return Row(
      children: [
        const BrandMark(),
        const SizedBox(width: 32),
        Expanded(
          child: Semantics(
            textField: true,
            label: 'Buscar perfumes, marcas o categorias',
            child: searchBox,
          ),
        ),
        const SizedBox(width: 20),
        HeaderActionButton(
          tooltip: 'Favoritos',
          icon: Icons.favorite_border,
          onPressed: () => _showFavoritesMessage(context),
        ),
        const SizedBox(width: 4),
        CartNavButton(count: cartCount, onPressed: onCartPressed),
        const SizedBox(width: 4),
        HeaderActionButton(
          tooltip: compact ? 'Cuenta' : 'Iniciar sesion',
          semanticLabel: 'Abrir panel de cuenta',
          icon: Icons.person_outline,
          badgeLabel: '!',
          showBadgeWhenZero: true,
          onPressed: () => showAccountDrawer(context),
        ),
      ],
    );
  }

  void _showFavoritesMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Favoritos visual preparado para una siguiente etapa.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _MobileHeader extends StatelessWidget {
  const _MobileHeader({
    required this.searchBox,
    required this.cartCount,
    required this.onCartPressed,
    required this.onCatalogPressed,
  });

  final Widget searchBox;
  final int cartCount;
  final VoidCallback onCartPressed;
  final VoidCallback onCatalogPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _HeaderIconButton(
              tooltip: 'Abrir menu',
              icon: Icons.menu,
              onPressed: () => _openMobileMenu(context),
            ),
            const Expanded(child: Center(child: BrandMark(compact: true))),
            HeaderActionButton(
              tooltip: 'Favoritos',
              icon: Icons.favorite_border,
              onPressed: () => _showFavoritesMessage(context),
            ),
            CartNavButton(count: cartCount, onPressed: onCartPressed),
            HeaderActionButton(
              tooltip: 'Cuenta',
              semanticLabel: 'Abrir panel de cuenta',
              icon: Icons.person_outline,
              badgeLabel: '!',
              showBadgeWhenZero: true,
              onPressed: () => showAccountDrawer(context),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Semantics(
          textField: true,
          label: 'Buscar perfumes, marcas o categorias',
          child: searchBox,
        ),
      ],
    );
  }

  void _showFavoritesMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Favoritos visual preparado para una siguiente etapa.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openMobileMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final links = [
          ('Inicio', Icons.home_outlined),
          ('Perfumes', Icons.spa_outlined),
          ('Mujer', Icons.female_outlined),
          ('Hombre', Icons.male_outlined),
          ('Unisex', Icons.diversity_1_outlined),
          ('Marcas', Icons.sell_outlined),
          ('Promociones', Icons.local_offer_outlined),
        ];
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Menu',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar menu',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              for (final link in links)
                ListTile(
                  leading: Icon(link.$2),
                  title: Text(link.$1),
                  onTap: () {
                    Navigator.of(context).pop();
                    if (link.$1 != 'Inicio') onCatalogPressed();
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _NavigationBar extends StatelessWidget {
  const _NavigationBar({required this.onCatalogPressed});

  final VoidCallback onCatalogPressed;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 760) return const SizedBox.shrink();
    final sidePadding = AppLayout.horizontalPadding(width);

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: AppLayout.contentMaxWidth(width),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: sidePadding),
            child: Row(
              children: [
                _NavButton(label: 'Inicio', active: true, onPressed: () {}),
                _NavButton(label: 'Perfumes', onPressed: onCatalogPressed),
                _NavButton(label: 'Mujer', onPressed: onCatalogPressed),
                _NavButton(label: 'Hombre', onPressed: onCatalogPressed),
                _NavButton(label: 'Unisex', onPressed: onCatalogPressed),
                _NavButton(label: 'Marcas', onPressed: onCatalogPressed),
                _NavButton(label: 'Promociones', onPressed: onCatalogPressed),
                _NavButton(
                  label: 'Buscar por acordes',
                  onPressed: () => Navigator.of(context).pushNamed('/acordes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      icon: Icon(icon, color: AppColors.textPrimary),
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
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
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
