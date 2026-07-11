import 'package:flutter/material.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFE8C766),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.spa_outlined,
            color: Color(0xFF143B33),
            size: 28,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aromas Store',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF111111),
              ),
            ),
            Text(
              'Fragancias y bienestar',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF575757),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
