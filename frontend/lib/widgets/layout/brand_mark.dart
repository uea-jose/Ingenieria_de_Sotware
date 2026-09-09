import 'package:flutter/material.dart';

import '../../app/app_design_tokens.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 38 : 44,
          height: compact ? 38 : 44,
          decoration: BoxDecoration(
            color: AppColors.darkPromo,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.spa_outlined,
            color: AppColors.primary,
            size: 25,
          ),
        ),
        if (compact) const SizedBox.shrink() else const SizedBox(width: 10),
        if (compact)
          const SizedBox.shrink()
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aromas Store',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                'Fragancias y bienestar',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
