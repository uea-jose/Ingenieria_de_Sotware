import 'package:flutter/material.dart';

import '../../app/app_design_tokens.dart';

/// Semantic variants supported by [FeedbackBanner].
enum FeedbackVariant { success, error, warning, info }

/// Inline banner used to communicate the result of an action inside a
/// form (invalid login, cart validation error, order success, etc.).
///
/// Replaces the four `_ErrorBanner` copies that used to live inside
/// `login_page`, `register_page`, `account_drawer` and `checkout_page`.
/// Same visual weight as those banners so no page needs a rework.
///
/// Prefer the named constructors — they encode the semantic intent:
///
/// ```dart
/// FeedbackBanner.error('Credenciales inválidas.')
/// FeedbackBanner.success('Pedido creado correctamente.')
/// FeedbackBanner.warning('Tu carrito tiene stock bajo.')
/// FeedbackBanner.info('Aún no tienes pedidos.')
/// ```
class FeedbackBanner extends StatelessWidget {
  const FeedbackBanner({
    required this.message,
    required this.variant,
    this.onDismiss,
    super.key,
  });

  const FeedbackBanner.success(this.message, {this.onDismiss, super.key})
    : variant = FeedbackVariant.success;

  const FeedbackBanner.error(this.message, {this.onDismiss, super.key})
    : variant = FeedbackVariant.error;

  const FeedbackBanner.warning(this.message, {this.onDismiss, super.key})
    : variant = FeedbackVariant.warning;

  const FeedbackBanner.info(this.message, {this.onDismiss, super.key})
    : variant = FeedbackVariant.info;

  final String message;
  final FeedbackVariant variant;

  /// Optional close button. When `null` the banner has no dismiss control.
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(variant);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(palette.icon, color: palette.foreground, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: palette.foreground,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: onDismiss,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: palette.foreground,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static _BannerPalette _paletteFor(FeedbackVariant v) {
    switch (v) {
      case FeedbackVariant.success:
        return _BannerPalette(
          background: AppColors.successSoft,
          border: AppColors.success.withValues(alpha: 0.35),
          foreground: AppColors.success,
          icon: Icons.check_circle_outline,
        );
      case FeedbackVariant.error:
        return _BannerPalette(
          background: AppColors.errorSoft,
          border: AppColors.error.withValues(alpha: 0.3),
          foreground: AppColors.error,
          icon: Icons.error_outline,
        );
      case FeedbackVariant.warning:
        return _BannerPalette(
          background: AppColors.bgPeach,
          border: AppColors.warning.withValues(alpha: 0.5),
          foreground: AppColors.warning,
          icon: Icons.warning_amber_rounded,
        );
      case FeedbackVariant.info:
        return _BannerPalette(
          background: AppColors.bgBlue,
          border: AppColors.primary.withValues(alpha: 0.3),
          foreground: AppColors.primary,
          icon: Icons.info_outline,
        );
    }
  }
}

class _BannerPalette {
  const _BannerPalette({
    required this.background,
    required this.border,
    required this.foreground,
    required this.icon,
  });

  final Color background;
  final Color border;
  final Color foreground;
  final IconData icon;
}
