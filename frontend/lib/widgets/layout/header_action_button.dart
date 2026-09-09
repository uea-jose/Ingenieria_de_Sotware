import 'package:flutter/material.dart';

import '../../app/app_design_tokens.dart';

class HeaderActionButton extends StatefulWidget {
  const HeaderActionButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.badgeCount,
    this.badgeLabel,
    this.showBadgeWhenZero = false,
    this.semanticLabel,
    super.key,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final int? badgeCount;
  final String? badgeLabel;
  final bool showBadgeWhenZero;
  final String? semanticLabel;

  @override
  State<HeaderActionButton> createState() => _HeaderActionButtonState();
}

class _HeaderActionButtonState extends State<HeaderActionButton> {
  bool _hovered = false;
  bool _focused = false;

  bool get _active => _hovered || _focused;

  @override
  Widget build(BuildContext context) {
    final count = widget.badgeCount;
    final hasCount = count != null && (count > 0 || widget.showBadgeWhenZero);
    final label = widget.badgeLabel ?? _formatBadge(count);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      button: true,
      label: widget.semanticLabel ?? widget.tooltip,
      child: Tooltip(
        message: widget.tooltip,
        child: FocusableActionDetector(
          mouseCursor: SystemMouseCursors.click,
          onShowHoverHighlight: (value) => setState(() => _hovered = value),
          onShowFocusHighlight: (value) => setState(() => _focused = value),
          child: AnimatedContainer(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _active
                  ? AppColors.darkPromo.withValues(alpha: 0.06)
                  : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: _focused ? AppColors.primary : Colors.transparent,
                width: 1.4,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: IconButton(
                    tooltip: widget.tooltip,
                    onPressed: widget.onPressed,
                    icon: AnimatedScale(
                      scale: _active ? 1.06 : 1,
                      duration: reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      child: Icon(
                        widget.icon,
                        color: AppColors.textPrimary,
                        size: 25,
                      ),
                    ),
                  ),
                ),
                if (hasCount && label.isNotEmpty)
                  Positioned(
                    top: 3,
                    right: 2,
                    child: AnimatedScale(
                      scale: _active ? 1.08 : 1,
                      duration: reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      child: _HeaderBadge(label: label),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatBadge(int? count) {
    if (count == null) return '';
    if (count > 99) return '99+';
    if (count > 9) return '9+';
    return '$count';
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.surface, width: 1.5),
        boxShadow: AppShadows.mobile,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.onDark,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}
