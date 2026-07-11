import 'package:flutter/material.dart';

import 'brand_mark.dart';
import 'cart_nav_button.dart';
import 'premium_announcement_bar.dart';

class TopNavigation extends StatelessWidget {
  const TopNavigation({
    required this.onCatalogPressed,
    required this.onCartPressed,
    required this.onSearchChanged,
    required this.cartCount,
    super.key,
  });

  final VoidCallback onCatalogPressed;
  final VoidCallback onCartPressed;
  final ValueChanged<String> onSearchChanged;
  final int cartCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          const PremiumAnnouncementBar(),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 760;
                    final navActions = Wrap(
                      spacing: 6,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _NavButton(label: 'Inicio', onPressed: () {}),
                        _NavButton(
                          label: 'Catalogo',
                          onPressed: onCatalogPressed,
                        ),
                        _NavButton(
                          label: 'Promociones',
                          onPressed: onCatalogPressed,
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
                        if (compact) ...[
                          const BrandMark(),
                          const SizedBox(height: 14),
                          navActions,
                        ] else
                          Row(
                            children: [
                              const BrandMark(),
                              const Spacer(),
                              navActions,
                            ],
                          ),
                        const SizedBox(height: 18),
                        Semantics(
                          textField: true,
                          label: 'Buscar perfumes, marcas o categorias',
                          child: TextField(
                            onChanged: onSearchChanged,
                            decoration: InputDecoration(
                              hintText: 'Buscar perfume, marca o categoria',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: const Icon(Icons.tune_outlined),
                              filled: true,
                              fillColor: const Color(0xFFF1F1F1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
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
  const _NavButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF111111),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
