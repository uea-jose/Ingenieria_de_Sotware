import 'package:flutter/material.dart';

import '../../app/app_design_tokens.dart';
import 'feedback_banner.dart';

/// Unified entry point for the temporary toast-style feedback of the app.
///
/// Replaces ad-hoc `ScaffoldMessenger.of(context).showSnackBar(...)` calls
/// spread across the codebase (~15 sites). All snackbars now share the
/// same behaviour, colours and iconography, mapped by [FeedbackVariant].
///
/// Basic use:
///
/// ```dart
/// AppFeedback.success(context, 'Sesión iniciada.');
/// AppFeedback.error(context, 'Credenciales inválidas.');
/// AppFeedback.warning(context, 'Solo quedan 3 unidades disponibles.');
/// AppFeedback.info(context, 'La recuperación se habilitará pronto.');
/// ```
///
/// Optional undo action:
///
/// ```dart
/// AppFeedback.info(
///   context,
///   'Producto eliminado del carrito.',
///   action: SnackBarAction(
///     label: 'Deshacer',
///     onPressed: () => cart.restore(item),
///   ),
/// );
/// ```
class AppFeedback {
  const AppFeedback._();

  /// Shorthand for the four semantic variants.
  static void success(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration duration = _defaultDuration,
  }) => _show(
    context,
    message,
    FeedbackVariant.success,
    action: action,
    duration: duration,
  );

  static void error(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration duration = _defaultDuration,
  }) => _show(
    context,
    message,
    FeedbackVariant.error,
    action: action,
    duration: duration,
  );

  static void warning(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration duration = _defaultDuration,
  }) => _show(
    context,
    message,
    FeedbackVariant.warning,
    action: action,
    duration: duration,
  );

  static void info(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration duration = _defaultDuration,
  }) => _show(
    context,
    message,
    FeedbackVariant.info,
    action: action,
    duration: duration,
  );

  /// Removes any pending snackbar. Handy before pushing a new page that
  /// would otherwise overlap.
  static void clear(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  // ────────────────────────────────────────────────────────────────

  static const Duration _defaultDuration = Duration(seconds: 4);

  static void _show(
    BuildContext context,
    String message,
    FeedbackVariant variant, {
    SnackBarAction? action,
    required Duration duration,
  }) {
    final palette = _palette(variant);
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: duration,
          backgroundColor: palette.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.card),
            side: BorderSide(color: palette.border),
          ),
          content: Row(
            children: [
              Icon(palette.icon, color: palette.foreground, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: palette.foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          action: action,
        ),
      );
  }

  static _SnackPalette _palette(FeedbackVariant v) {
    switch (v) {
      case FeedbackVariant.success:
        return _SnackPalette(
          background: AppColors.successSoft,
          border: AppColors.success.withValues(alpha: 0.35),
          foreground: AppColors.success,
          icon: Icons.check_circle_outline,
        );
      case FeedbackVariant.error:
        return _SnackPalette(
          background: AppColors.errorSoft,
          border: AppColors.error.withValues(alpha: 0.3),
          foreground: AppColors.error,
          icon: Icons.error_outline,
        );
      case FeedbackVariant.warning:
        return _SnackPalette(
          background: AppColors.bgPeach,
          border: AppColors.warning.withValues(alpha: 0.5),
          foreground: AppColors.warning,
          icon: Icons.warning_amber_rounded,
        );
      case FeedbackVariant.info:
        return _SnackPalette(
          background: AppColors.bgBlue,
          border: AppColors.primary.withValues(alpha: 0.3),
          foreground: AppColors.primary,
          icon: Icons.info_outline,
        );
    }
  }
}

class _SnackPalette {
  const _SnackPalette({
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
