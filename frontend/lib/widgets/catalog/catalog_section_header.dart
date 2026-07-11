import 'package:flutter/material.dart';

class CatalogSectionHeader extends StatelessWidget {
  const CatalogSectionHeader({
    required this.visibleProducts,
    required this.totalProducts,
    super.key,
  });

  final int visibleProducts;
  final int totalProducts;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Catalogo publico',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF111111),
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Encuentra productos por marca, categoria o nombre. El stock se comunica con texto, no solo color.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF555555),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Text(
                '$visibleProducts de $totalProducts',
                style: const TextStyle(
                  color: Color(0xFF145647),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
