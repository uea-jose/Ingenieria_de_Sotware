import 'package:flutter/material.dart';

import '../../app/app_design_tokens.dart';
import '../../models/brand.dart';

/// Compact "Sobre la marca" panel shown inside the product detail view.
///
/// Uses only fields that actually exist on the backend `Marca` model:
///   - `nombre`
///   - `paisOrigen` (nullable in DB)
///   - `descripcion` (nullable in DB)
///
/// We deliberately do NOT invent a `fabricante` field. In the domain,
/// the brand fulfills that role for a perfume record.
///
/// The parent should gate rendering with [BrandInfoBlock.hasInfo] so the
/// block never renders as an empty card when the brand has neither a
/// country nor a description.
class BrandInfoBlock extends StatelessWidget {
  const BrandInfoBlock({required this.brand, super.key});

  final Brand brand;

  /// True when the brand carries at least one displayable field beyond
  /// the name (which is already shown in the purchase panel).
  static bool hasInfo(Brand brand) {
    return brand.country.trim().isNotEmpty ||
        brand.description.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final country = brand.country.trim();
    final description = brand.description.trim();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.workspace_premium_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sobre ${brand.name}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          if (country.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.public_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Origen: $country',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
          if (description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              description,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.55,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
