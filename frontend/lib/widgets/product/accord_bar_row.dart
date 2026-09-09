import 'package:flutter/material.dart';

/// Compact accord row — Fragrantica "Buscar por acordes" style.
///
/// Layout:  [name 90px left-aligned] [8px] [coloured track] [× 16px]
/// Row height : 26 px
/// Bar height : 22 px   (matches Fragrantica visual)
/// Gap between rows is managed by the parent (use 4 px).
class AccordBarRow extends StatelessWidget {
  const AccordBarRow({
    required this.name,
    required this.colorHex,
    required this.intensity,
    super.key,
    this.editMode = false,
    this.onIntensityChanged,
    this.onRemove,
  });

  final String name;
  final String colorHex;

  /// 1 – 100.
  final int intensity;

  /// Shows drag interaction + × when true.
  final bool editMode;

  final ValueChanged<int>? onIntensityChanged;
  final VoidCallback? onRemove;

  static const double _rowH = 26;
  static const double _barH = 22;
  static const double _nameW = 90;

  @override
  Widget build(BuildContext context) {
    final barColor = _hex(colorHex);

    return SizedBox(
      height: _rowH,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Name — left-aligned, fixed width ─────────────────────────────
          SizedBox(
            width: _nameW,
            child: Text(
              name,
              textAlign: TextAlign.left,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: Color(0xFFCCCCCC),
                height: 1.0,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // ── Track ─────────────────────────────────────────────────────────
          Expanded(
            child: editMode
                ? _DraggableTrack(
                    barColor: barColor,
                    barH: _barH,
                    rowH: _rowH,
                    intensity: intensity,
                    onIntensityChanged: onIntensityChanged,
                  )
                : _Track(barColor: barColor, barH: _barH, intensity: intensity),
          ),

          // ── Remove × (edit only) ──────────────────────────────────────────
          if (editMode) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onRemove,
              behavior: HitTestBehavior.opaque,
              child: const SizedBox(
                width: 16,
                height: _rowH,
                child: Center(
                  child: Text(
                    '×',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFFAA4444),
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Color _hex(String v) {
    final c = v.replaceFirst('#', '');
    final n = int.tryParse(c, radix: 16);
    return n == null ? const Color(0xFF888888) : Color(0xFF000000 | n);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Static bar (read-only)
// ─────────────────────────────────────────────────────────────────────────────

class _Track extends StatelessWidget {
  const _Track({
    required this.barColor,
    required this.barH,
    required this.intensity,
  });

  final Color barColor;
  final double barH;
  final int intensity;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: barH,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: Color(0xFF3A3A3A)),
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (intensity / 100).clamp(0.01, 1.0),
                child: ColoredBox(color: barColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Draggable bar (edit mode) — uses GestureDetector, no Flutter Slider widget.
// ─────────────────────────────────────────────────────────────────────────────

class _DraggableTrack extends StatelessWidget {
  const _DraggableTrack({
    required this.barColor,
    required this.barH,
    required this.rowH,
    required this.intensity,
    required this.onIntensityChanged,
  });

  final Color barColor;
  final double barH;
  final double rowH;
  final int intensity;
  final ValueChanged<int>? onIntensityChanged;

  void _update(double dx, double trackWidth) {
    if (onIntensityChanged == null || trackWidth <= 0) return;
    onIntensityChanged!((dx / trackWidth * 100).round().clamp(1, 100));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _update(d.localPosition.dx, w),
          onHorizontalDragUpdate: (d) => _update(d.localPosition.dx, w),
          child: SizedBox(
            height: rowH,
            child: Center(
              child: SizedBox(
                height: barH,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Grey track background
                      const ColoredBox(color: Color(0xFF3A3A3A)),
                      // Coloured fill
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: (intensity / 100).clamp(0.01, 1.0),
                        child: ColoredBox(color: barColor),
                      ),
                      // Thin white divider at the fill edge
                      Positioned(
                        left: ((intensity / 100).clamp(0.01, 0.98) * w) - 1,
                        top: 3,
                        bottom: 3,
                        width: 2,
                        child: ColoredBox(
                          color: Colors.white.withValues(alpha: 0.50),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
