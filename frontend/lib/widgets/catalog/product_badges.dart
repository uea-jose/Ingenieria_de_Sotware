import 'package:flutter/material.dart';

import '../../app/app_design_tokens.dart';

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
            ? AppColors.bgPeach
            : AppColors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(
          color: warning ? AppColors.warning : AppColors.borderSoft,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            warning ? Icons.warning_amber_rounded : Icons.check_circle_outline,
            size: 16,
            color: warning ? AppColors.warning : AppColors.success,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: warning ? AppColors.textPrimary : AppColors.success,
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
      background = const Color(0xFFFFE8EC);
      foreground = AppColors.error;
      text = 'Agotado';
    } else if (stockLow) {
      background = AppColors.bgPeach;
      foreground = AppColors.textPrimary;
      text = 'Stock bajo: $stock';
    } else {
      background = AppColors.bgMint;
      foreground = AppColors.success;
      text = 'Stock: $stock';
    }

    return Semantics(
      label: text,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadii.pill),
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
