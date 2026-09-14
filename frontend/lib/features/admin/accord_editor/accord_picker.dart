import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/aroma_accord.dart';

/// Compact accord selector used both to ADD a new accord and to REPLACE an
/// existing one. Fragrantica-style: a small text field that opens a **floating
/// dropdown** anchored right below it — it overlays the content instead of
/// pushing the rows down.
///
/// - Filters as the user types (accent-insensitive).
/// - Options excluded via [exclude] (ids already in the profile) are hidden.
/// - Escape, tapping outside, or the × cancels ([onCancel]).
/// - Picking an option calls [onSelected]; the caller then closes the picker.
///
/// [fieldWidth] keeps the text field the same width as the accord name box so
/// the row layout does not shift when switching to edit mode.
class AccordPicker extends StatefulWidget {
  const AccordPicker({
    required this.library,
    required this.exclude,
    required this.onSelected,
    required this.onCancel,
    super.key,
    this.hint = 'Añadir acorde...',
    this.fieldWidth = 130,
    this.initialText = '',
    this.autofocus = true,
    this.leadingColorHex,
  });

  final List<AromaAccord> library;
  final Set<int> exclude;
  final ValueChanged<AromaAccord> onSelected;
  final VoidCallback onCancel;
  final String hint;
  final double fieldWidth;

  /// Pre-fills the field (used when editing an existing accord's name).
  final String initialText;

  /// Autofocus + auto-open dropdown when created.
  final bool autofocus;

  /// Optional colour dot shown inside the field (the current accord's colour).
  final String? leadingColorHex;

  @override
  State<AccordPicker> createState() => _AccordPickerState();
}

class _AccordPickerState extends State<AccordPicker> {
  late final _controller = TextEditingController(text: widget.initialText);
  final _focus = FocusNode();
  final _link = LayerLink();
  final _overlayController = OverlayPortalController();
  late String _query = widget.initialText;

  @override
  void initState() {
    super.initState();
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _overlayController.show();
        _focus.requestFocus();
        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controller.text.length,
        );
      });
    }
    _focus.addListener(() {
      if (_focus.hasFocus) {
        _overlayController.show();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  List<AromaAccord> get _filtered {
    final q = _normalize(_query);
    // When the field still shows the original accord name unchanged, show the
    // full list so the user can browse; once they type, filter live.
    final showAll = q == _normalize(widget.initialText);
    return widget.library
        .where(
          (a) =>
              !widget.exclude.contains(a.id) &&
              (showAll || _normalize(a.name).contains(q)),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    // The field stays inline (same footprint as the name box). The dropdown
    // is rendered in an OverlayPortal and positioned via CompositedTransform.
    return Focus(
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          widget.onCancel();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: CompositedTransformTarget(
        link: _link,
        child: OverlayPortal(
          controller: _overlayController,
          overlayChildBuilder: _buildOverlay,
          child: SizedBox(
            width: widget.fieldWidth,
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              onChanged: (value) => setState(() => _query = value),
              onTap: () => _overlayController.show(),
              style: const TextStyle(fontSize: 11),
              decoration: InputDecoration(
                isDense: true,
                hintText: widget.hint,
                hintStyle: const TextStyle(fontSize: 11),
                prefixIcon: widget.leadingColorHex == null
                    ? null
                    : Padding(
                        padding: const EdgeInsets.only(left: 8, right: 4),
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _hex(widget.leadingColorHex!),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 0,
                  minHeight: 0,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    final options = _filtered;

    return Stack(
      children: [
        // Full-screen barrier: tapping outside cancels.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: widget.onCancel,
          ),
        ),
        // Floating dropdown anchored below the field.
        CompositedTransformFollower(
          link: _link,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(0, 4),
          child: Align(
            alignment: Alignment.topLeft,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 240,
                constraints: const BoxConstraints(maxHeight: 260),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1E20),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF34383D)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: options.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: Text(
                          'Sin coincidencias',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF888888),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: options.length,
                        itemBuilder: (context, i) => _Option(
                          accord: options[i],
                          onTap: widget.onSelected,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _normalize(String value) {
    var r = value.toLowerCase().trim();
    const accented = 'áéíóúüñ';
    const plain = 'aeiouun';
    for (var i = 0; i < accented.length; i++) {
      r = r.replaceAll(accented[i], plain[i]);
    }
    return r;
  }

  static Color _hex(String v) {
    final c = v.replaceFirst('#', '');
    final n = int.tryParse(c, radix: 16);
    return n == null ? const Color(0xFF888888) : Color(0xFF000000 | n);
  }
}

/// A single option row: [colour dot] [name], with hover highlight + pointer.
class _Option extends StatefulWidget {
  const _Option({required this.accord, required this.onTap});

  final AromaAccord accord;
  final ValueChanged<AromaAccord> onTap;

  @override
  State<_Option> createState() => _OptionState();
}

class _OptionState extends State<_Option> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => widget.onTap(widget.accord),
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: _hover ? const Color(0xFF2C3033) : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _hexColor(widget.accord.colorHex),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.accord.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _hexColor(String v) {
    final c = v.replaceFirst('#', '');
    final n = int.tryParse(c, radix: 16);
    return n == null ? const Color(0xFF888888) : Color(0xFF000000 | n);
  }
}
