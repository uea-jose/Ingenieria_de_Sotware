import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Swaps between two asset images on hover.
///
/// This is a small, self-contained widget used **only** as a controlled UX
/// experiment on a single product card (Good Girl — Carolina Herrera). It is
/// deliberately kept general (`primaryAsset` / `hoverAsset` parameters) so it
/// can be reused later, but for now it is only wired up from
/// [ProductImage] when it detects that specific product.
///
/// Behaviour:
/// - Desktop / web: `onEnter` fades to [hoverAsset], `onExit` fades back to
///   [primaryAsset]. Transition is a soft cross-fade (~180 ms).
/// - Touch / mobile: no hover events fire, so [primaryAsset] stays visible.
/// - Both images share exactly the same container ([BoxFit.contain],
///   full width/height), so the card never resizes when swapping.
/// - Both images are precached in [didChangeDependencies], so the first
///   hover doesn't show a white flash or a load lag.
/// - The 3-D drop shadow used elsewhere for the perfume grid is reproduced
///   here internally and follows the currently visible image, so hover keeps
///   the same premium look.
class HoverProductImage extends StatefulWidget {
  const HoverProductImage({
    required this.primaryAsset,
    required this.hoverAsset,
    this.fit = BoxFit.contain,
    this.transitionDuration = const Duration(milliseconds: 180),
    this.compact = false,
    this.semanticLabel,
    super.key,
  });

  final String primaryAsset;
  final String hoverAsset;
  final BoxFit fit;
  final Duration transitionDuration;
  final bool compact;
  final String? semanticLabel;

  @override
  State<HoverProductImage> createState() => _HoverProductImageState();
}

class _HoverProductImageState extends State<HoverProductImage> {
  bool _hovered = false;
  bool _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      // Warm the image cache with both variants before the very first hover
      // to prevent a white flash or a visible load on first entry.
      precacheImage(AssetImage(widget.primaryAsset), context);
      precacheImage(AssetImage(widget.hoverAsset), context);
    }
  }

  void _setHovered(bool value) {
    if (_hovered == value) return;
    setState(() => _hovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final asset = _hovered ? widget.hoverAsset : widget.primaryAsset;

    // MouseRegion emits enter/exit events on web + desktop; on touch devices
    // it is a no-op, so the primary image simply stays on screen.
    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1) Drop shadow layer. Duplicates the image, tints it dark, blurs
          //    it and pushes it down so the bottle looks lifted off the card.
          //    Uses the SAME `_hovered` state, so the shadow morphs together
          //    with the visible image — no ghosting on hover.
          Positioned.fill(
            child: _ShadowLayer(asset: asset, compact: widget.compact),
          ),

          // 2) Foreground image with a cross-fade between primary and hover.
          //    Both children share the same key strategy so AnimatedSwitcher
          //    treats them as different frames and fades between them.
          AnimatedSwitcher(
            duration: widget.transitionDuration,
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            layoutBuilder: (currentChild, previousChildren) {
              // Stack both so they occupy the exact same box; that way the
              // card never changes height mid-transition.
              return Stack(
                alignment: Alignment.center,
                fit: StackFit.expand,
                children: <Widget>[...previousChildren, ?currentChild],
              );
            },
            child: Image.asset(
              asset,
              key: ValueKey<String>(asset),
              fit: widget.fit,
              width: double.infinity,
              height: double.infinity,
              gaplessPlayback: true,
              semanticLabel: widget.semanticLabel,
            ),
          ),
        ],
      ),
    );
  }
}

/// Blurred, darkened, translated copy of the current asset. Rendered behind
/// the real image to produce a bottle-shaped drop shadow that follows the
/// PNG/JPEG's alpha or bright silhouette.
class _ShadowLayer extends StatelessWidget {
  const _ShadowLayer({required this.asset, required this.compact});

  final String asset;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final blur = compact ? 10.0 : 14.0;
    final drop = compact ? 6.0 : 9.0;
    const shadowColor = Color(0xFF1C1B1A);

    return IgnorePointer(
      child: Transform.translate(
        offset: Offset(0, drop),
        child: ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(
              shadowColor.withValues(alpha: 0.38),
              BlendMode.srcATop,
            ),
            child: Opacity(
              opacity: 0.9,
              child: Image.asset(
                asset,
                // Same ValueKey rule so the framework re-runs the shadow
                // pipeline whenever the visible asset changes.
                key: ValueKey<String>('shadow:$asset'),
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                gaplessPlayback: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
