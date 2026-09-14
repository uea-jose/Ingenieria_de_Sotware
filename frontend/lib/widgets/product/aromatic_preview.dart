import 'package:flutter/material.dart';
import '../../app/app_design_tokens.dart';
import '../../models/aroma_accord.dart';

/// Shares the editor's current profile. No fetching and no second editing state.
class AromaticPreview extends StatelessWidget {
  const AromaticPreview({
    super.key,
    required this.name,
    required this.brand,
    required this.accords,
    this.imageUrl,
    this.imageAsset,
    this.caption,
    this.title = 'Vista previa',
    this.imageHeight = 180,
  });
  final String name, brand, title;
  final String? imageUrl, imageAsset, caption;
  final List<EditableAccord> accords;
  final double imageHeight;

  @override
  Widget build(BuildContext context) {
    final placeholder = const Center(
      child: Icon(
        Icons.local_florist_outlined,
        size: 56,
        color: AppColors.textSecondary,
      ),
    );
    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderSoft),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(name, style: Theme.of(context).textTheme.titleLarge),
            Text(brand, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            SizedBox(
              height: imageHeight,
              child: imageAsset != null
                  ? Image.asset(
                      imageAsset!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => placeholder,
                    )
                  : imageUrl != null && imageUrl!.isNotEmpty
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => placeholder,
                    )
                  : placeholder,
            ),
            if (caption != null) ...[
              const SizedBox(height: 8),
              Text(caption!, style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 16),
            if (accords.isEmpty) const Text('Perfil aromático por completar.'),
            for (final item in accords)
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Semantics(
                  label: item.accord.name,
                  child: Container(
                    height: 28,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: const Color(0xFF383838),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Stack(
                      children: [
                        FractionallySizedBox(
                          widthFactor: item.intensity / 100,
                          heightFactor: 1,
                          child: ColoredBox(
                            color: Color(
                              0xFF000000 |
                                  (int.tryParse(
                                        item.accord.colorHex.replaceFirst(
                                          '#',
                                          '',
                                        ),
                                        radix: 16,
                                      ) ??
                                      0x888888),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: .65),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                item.accord.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
