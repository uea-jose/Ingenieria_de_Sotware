import 'package:flutter/material.dart';

/// Compact accord row — Fragrantica "Buscar por acordes" style.
///
/// Layout:  [name box 90px] [8px] [coloured track] [× 16px]
/// Row height : 26 px · Bar height : 22 px · gap between rows managed by parent.
///
/// Interaction (web):
///   - name box  → click cursor, opens replace picker via [onNameTap]
///   - bar       → grab cursor, grabbing while dragging; tap/drag sets intensity
///   - ×         → click cursor, red intensifies on hover
class AccordBarRow extends StatelessWidget {
  const AccordBarRow({
    required this.name,
    required this.colorHex,
    required this.intensity,
    super.key,
    this.editMode = false,
    this.onIntensityChanged,
    this.onRemove,
    this.onNameTap,
    this.showName = true,
  });

  final String name;
  final String colorHex;

  /// 1 – 100.
  final int intensity;

  /// Shows drag interaction + × when true.
  final bool editMode;

  final ValueChanged<int>? onIntensityChanged;
  final VoidCallback? onRemove;

  /// When provided (and [editMode]), tapping the name box triggers this
  /// (used to open the replace-accord picker).
  final VoidCallback? onNameTap;

  /// When false, the name box is not rendered (caller supplies its own field).
  final bool showName;

  static const double _rowH = 26;
  static const double _barH = 22;
  static const double _nameW = 90;

  @override
  Widget build(BuildContext context) {
    final barColor = _hex(colorHex);

    final nameBox = Container(
      width: _nameW,
      height: _barH,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: const Color(0xFF4A4A4A)),
      ),
      child: Text(
        name,
        textAlign: TextAlign.left,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: Color(0xFFDDDDDD),
          height: 1.0,
        ),
      ),
    );

    return SizedBox(
      height: _rowH,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Name box — optional; clickable (replace) when editable ───────
          if (showName) ...[
            if (editMode && onNameTap != null)
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: onNameTap,
                  behavior: HitTestBehavior.opaque,
                  child: nameBox,
                ),
              )
            else
              nameBox,
            const SizedBox(width: 8),
          ],

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
            _RemoveButton(rowH: _rowH, onRemove: onRemove),
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
// Remove × — click cursor + colour intensifies on hover
// ─────────────────────────────────────────────────────────────────────────────

class _RemoveButton extends StatefulWidget {
  const _RemoveButton({required this.rowH, required this.onRemove});

  final double rowH;
  final VoidCallback? onRemove;

  @override
  State<_RemoveButton> createState() => _RemoveButtonState();
}

class _RemoveButtonState extends State<_RemoveButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onRemove,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 16,
          height: widget.rowH,
          child: Center(
            child: Text(
              '×',
              style: TextStyle(
                fontSize: _hover ? 16 : 14,
                fontWeight: _hover ? FontWeight.w700 : FontWeight.w400,
                color: _hover
                    ? const Color(0xFFE53935)
                    : const Color(0xFFAA4444),
                height: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
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
// Draggable bar (edit mode) — grab/grabbing cursors, tap + drag to set value.
// Uses no Material Slider so the visual stays discrete like Fragrantica.
// ─────────────────────────────────────────────────────────────────────────────

class _DraggableTrack extends StatefulWidget {
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

  @override
  State<_DraggableTrack> createState() => _DraggableTrackState();
}

class _DraggableTrackState extends State<_DraggableTrack> {
  bool _dragging = false;

  void _update(double dx, double trackWidth) {
    final cb = widget.onIntensityChanged;
    if (cb == null || trackWidth <= 0) return;
    cb((dx / trackWidth * 100).round().clamp(1, 100));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        return MouseRegion(
          cursor: _dragging
              ? SystemMouseCursors.grabbing
              : SystemMouseCursors.grab,
          child: Listener(
            // Closed hand on press, open hand on release (matches Fragrantica).
            onPointerDown: (e) {
              setState(() => _dragging = true);
              _update(e.localPosition.dx, w);
            },
            onPointerMove: (e) => _update(e.localPosition.dx, w),
            onPointerUp: (_) => setState(() => _dragging = false),
            onPointerCancel: (_) => setState(() => _dragging = false),
            child: SizedBox(
              height: widget.rowH,
              child: Center(
                child: SizedBox(
                  height: widget.barH,
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
                          widthFactor: (widget.intensity / 100).clamp(
                            0.01,
                            1.0,
                          ),
                          child: ColoredBox(color: widget.barColor),
                        ),
                        // Vertical handle at the fill edge (Fragrantica style)
                        Positioned(
                          left:
                              ((widget.intensity / 100).clamp(0.02, 0.97) * w) -
                              2,
                          top: 2,
                          bottom: 2,
                          width: 4,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: _dragging
                                  ? const Color(0xFF999999)
                                  : const Color(0xFF666666),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
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
