import 'package:flutter/material.dart';

import '../../app/app_design_tokens.dart';

/// Store brand mark. Renders the Essenza / Aromas Store logo inside a
/// rounded square, optionally followed by a two-line brand caption.
///
/// The whole block is a clickable "home" affordance: tapping either the
/// logo box or the "Aromas Store · Fragancias y bienestar" caption
/// navigates to `/` from any inner page. If the user is already at `/`
/// the tap is a no-op to avoid rebuilding the home stack.
///
/// The logo is loaded from `assets/img/essenza_logo.png` and uses
/// [BoxFit.contain] so it never deforms nor overflows its container. When
/// [compact] is true only the logo box is shown (used inside the mobile
/// header where horizontal space is tight).
class BrandMark extends StatelessWidget {
  const BrandMark({this.compact = false, super.key});

  final bool compact;

  static const String _logoAsset = 'assets/img/essenza_logo.png';

  void _goHome(BuildContext context) {
    // Skip the navigation when we're already sitting at `/`. Keeps
    // hitting the logo on the home page as a friendly no-op instead of
    // rebuilding the whole page.
    final currentRoute = ModalRoute.of(context)?.settings.name;
    if (currentRoute == '/') return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final boxSize = compact ? 38.0 : 44.0;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: boxSize,
          height: boxSize,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.darkPromo,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Image.asset(
            _logoAsset,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            // Fallback keeps the header stable if the asset ever fails to load.
            errorBuilder: (_, _, _) => const Icon(
              Icons.spa_outlined,
              color: AppColors.primary,
              size: 25,
            ),
          ),
        ),
        if (!compact) ...[
          const SizedBox(width: 10),
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
      ],
    );

    return Semantics(
      button: true,
      label: 'Ir al inicio de Aromas Store',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _goHome(context),
          child: content,
        ),
      ),
    );
  }
}
