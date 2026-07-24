import 'package:flutter/material.dart';

import '../../app/app_design_tokens.dart';
import '../../models/brand.dart';
import '../../models/product.dart';
import '../../widgets/catalog/product_card.dart';

class CategoryShortcuts extends StatelessWidget {
  const CategoryShortcuts({required this.onSelected, super.key});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = const [
      _CategoryData(
        title: 'Mujer',
        text: 'Florales, ambaradas y frescas para cada momento.',
        icon: Icons.local_florist_outlined,
      ),
      _CategoryData(
        title: 'Hombre',
        text: 'Aromas amaderados, citricos e intensos.',
        icon: Icons.nightlife_outlined,
      ),
      _CategoryData(
        title: 'Unisex',
        text: 'Fragancias versatiles faciles de compartir.',
        icon: Icons.diversity_1_outlined,
      ),
      _CategoryData(
        title: 'Sets y regalos',
        text: 'Opciones listas para ocasiones especiales.',
        icon: Icons.card_giftcard_outlined,
      ),
    ];

    return _SectionShell(
      title: 'Explora por categoria',
      subtitle: 'Encuentra rapido el tipo de fragancia que necesitas.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final width = compact
              ? constraints.maxWidth
              : (constraints.maxWidth - 42) / 4;
          return Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              for (final item in items)
                SizedBox(
                  width: width,
                  child: _CategoryCard(
                    data: item,
                    onTap: () => onSelected(item.title),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class ProductShowcaseSection extends StatelessWidget {
  const ProductShowcaseSection({
    required this.title,
    required this.subtitle,
    required this.products,
    required this.onAddToCart,
    required this.onViewDetails,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<Product> products;
  final ValueChanged<Product> onAddToCart;
  final ValueChanged<Product> onViewDetails;

  @override
  Widget build(BuildContext context) {
    final visible = products.take(4).toList();
    return _SectionShell(
      title: title,
      subtitle: subtitle,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 1120
              ? 4
              : constraints.maxWidth >= 760
              ? 2
              : 1;
          final width = (constraints.maxWidth - (columns - 1) * 18) / columns;
          return Wrap(
            spacing: 18,
            runSpacing: 18,
            children: [
              for (final product in visible)
                SizedBox(
                  width: width,
                  height: 486,
                  child: ProductCard(
                    product: product,
                    onAddToCart: onAddToCart,
                    onViewDetails: onViewDetails,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class PromoBannerSection extends StatelessWidget {
  const PromoBannerSection({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 10),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppColors.bgSoftPink,
                  AppColors.bgLavender,
                  AppColors.bgBlue,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadii.block),
              border: Border.all(color: AppColors.borderSoft),
              boxShadow: AppShadows.base,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 720;
                final textContent = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Promocion de temporada',
                      style: TextStyle(
                        color: AppColors.primaryHover,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Fragancias seleccionadas para regalar y descubrir.',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Simulacion visual preparada para conectar promociones reales mas adelante.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                );
                final action = FilledButton.icon(
                  onPressed: onPressed,
                  icon: const Icon(Icons.local_offer_outlined),
                  label: const Text('Ver promociones'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surface,
                  ),
                );

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [textContent, const SizedBox(height: 18), action],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: textContent),
                    const SizedBox(width: 24),
                    action,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class BrandShowcaseSection extends StatelessWidget {
  const BrandShowcaseSection({
    required this.brands,
    required this.onTap,
    super.key,
  });

  final List<Brand> brands;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return _SectionShell(
      title: 'Marcas destacadas',
      subtitle: 'Casas reconocidas para explorar por nombre o estilo.',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final brand in brands.take(8))
            ActionChip(
              avatar: const Icon(Icons.spa_outlined, size: 18),
              label: Text(brand.name),
              onPressed: () => onTap(brand.name),
              backgroundColor: AppColors.surface,
              side: const BorderSide(color: AppColors.borderSoft),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
        ],
      ),
    );
  }
}

class OccasionSection extends StatelessWidget {
  const OccasionSection({required this.onTap, super.key});

  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final items = const [
      ('Para regalar', Icons.card_giftcard_outlined),
      ('Uso diario', Icons.wb_sunny_outlined),
      ('Ocasiones especiales', Icons.auto_awesome_outlined),
      ('Fragancias frescas', Icons.water_drop_outlined),
      ('Fragancias intensas', Icons.local_fire_department_outlined),
    ];
    return _SectionShell(
      title: 'Compra por ocasion',
      subtitle: 'Atajos simples para reducir decisiones y comparar mejor.',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final item in items)
            OutlinedButton.icon(
              onPressed: () => onTap(item.$1),
              icon: Icon(item.$2),
              label: Text(item.$1),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class BenefitsSection extends StatelessWidget {
  const BenefitsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final items = const [
      _BenefitData(
        title: 'Stock visible',
        text: 'Disponibilidad clara antes de agregar al carrito.',
        icon: Icons.inventory_2_outlined,
      ),
      _BenefitData(
        title: 'Carrito validado',
        text: 'Cantidades revisadas contra disponibilidad.',
        icon: Icons.verified_outlined,
      ),
      _BenefitData(
        title: 'Compra guiada',
        text: 'Acciones simples, mensajes claros y recuperacion.',
        icon: Icons.support_agent_outlined,
      ),
    ];

    return _SectionShell(
      title: 'Beneficios de compra',
      subtitle: 'Una experiencia clara para explorar sin friccion.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 780;
          return Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              for (final item in items)
                SizedBox(
                  width: compact
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 28) / 3,
                  child: _BenefitCard(data: item),
                ),
            ],
          );
        },
      ),
    );
  }
}

class HomeFooter extends StatelessWidget {
  const HomeFooter({required this.onExplore, super.key});

  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgLavender,
      padding: const EdgeInsets.fromLTRB(24, 34, 24, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;
              final callToAction = FilledButton.icon(
                onPressed: onExplore,
                icon: const Icon(Icons.arrow_upward),
                label: const Text('Explorar catalogo'),
              );
              final text = Column(
                crossAxisAlignment: compact
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Aromas Store',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Portada publica preparada para conectar busqueda, promociones y compra real por etapas.',
                    textAlign: compact ? TextAlign.center : TextAlign.start,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              );

              if (compact) {
                return Column(
                  children: [text, const SizedBox(height: 18), callToAction],
                );
              }

              return Row(
                children: [
                  Expanded(child: text),
                  const SizedBox(width: 18),
                  callToAction,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SectionShell extends StatelessWidget {
  const _SectionShell({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 34, 24, 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 18),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  const _CategoryCard({required this.data, required this.onTap});

  final _CategoryData data;
  final VoidCallback onTap;

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            constraints: const BoxConstraints(minHeight: 148),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(
                color: _hovered ? AppColors.primary : AppColors.borderSoft,
              ),
              boxShadow: _hovered ? AppShadows.hover : AppShadows.base,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(widget.data.icon, color: AppColors.primary, size: 30),
                const SizedBox(height: 14),
                Text(
                  widget.data.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.data.text,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Explorar',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  const _BenefitCard({required this.data});

  final _BenefitData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          Icon(data.icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  data.text,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryData {
  const _CategoryData({
    required this.title,
    required this.text,
    required this.icon,
  });

  final String title;
  final String text;
  final IconData icon;
}

class _BenefitData {
  const _BenefitData({
    required this.title,
    required this.text,
    required this.icon,
  });

  final String title;
  final String text;
  final IconData icon;
}
