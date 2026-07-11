import 'package:flutter/material.dart';

class ProductStatusBadge extends StatelessWidget {
  const ProductStatusBadge({
    required this.text,
    required this.warning,
    super.key,
  });

  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: warning
            ? const Color(0xFFFFF1C2)
            : Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: warning ? const Color(0xFFE4B635) : const Color(0xFFE5DED2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            warning ? Icons.warning_amber_rounded : Icons.check_circle_outline,
            size: 16,
            color: warning ? const Color(0xFF684900) : const Color(0xFF145647),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: warning
                  ? const Color(0xFF684900)
                  : const Color(0xFF145647),
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class StockBadge extends StatelessWidget {
  const StockBadge({
    required this.stock,
    required this.hasStock,
    required this.stockLow,
    super.key,
  });

  final int stock;
  final bool hasStock;
  final bool stockLow;

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color foreground;
    final String text;

    if (!hasStock) {
      background = const Color(0xFFFFE6E6);
      foreground = const Color(0xFF8A1C1C);
      text = 'Agotado';
    } else if (stockLow) {
      background = const Color(0xFFFFF1C2);
      foreground = const Color(0xFF684900);
      text = 'Stock bajo: $stock';
    } else {
      background = const Color(0xFFE4F4EA);
      foreground = const Color(0xFF145647);
      text = 'Stock: $stock';
    }

    return Semantics(
      label: text,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: foreground,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
