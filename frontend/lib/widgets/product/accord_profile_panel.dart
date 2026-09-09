import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../app/app_design_tokens.dart';
import '../../config/api_config.dart';
import '../../models/aroma_accord.dart';

/// Displays the aromatic profile of a product as a compact read-only block
/// that matches the visual density and proportions of Fragrantica's
/// "acordes principales" section.
///
/// Layout (Fragrantica product-detail style):
///   - Dark container, no heavy border
///   - Small "acordes principales" label above
///   - Each row: full-width colored bar with the accord name centred inside,
///     bars sized proportionally (most-intense = 100 % width, rest scale down)
///   - Row height ≈ 28 px, gap ≈ 3 px — many accords visible at once
///
/// Fetches the profile from `/api/productos/:productId/acordes` on first build.
class AccordProfilePanel extends StatefulWidget {
  const AccordProfilePanel({required this.productId, super.key});

  final int productId;

  @override
  State<AccordProfilePanel> createState() => _AccordProfilePanelState();
}

class _AccordProfilePanelState extends State<AccordProfilePanel> {
  List<EditableAccord>? _accords;
  bool _loading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final url = '$apiBaseUrl/productos/${widget.productId}/acordes';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 404) {
        // Product has no accord profile yet — hide the panel silently.
        if (mounted) setState(() => _loading = false);
        return;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final raw = json['datos'] as List? ?? const [];
      final accords =
          raw
              .whereType<Map>()
              .map(
                (item) => EditableAccord.fromJson(item.cast<String, dynamic>()),
              )
              .toList()
            ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

      if (mounted) {
        setState(() {
          _accords = accords;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // While loading show a slim shimmer-like placeholder.
    if (_loading) return const _LoadingShimmer();

    // On error or empty profile render nothing — don't clutter the page.
    if (_hasError || _accords == null || _accords!.isEmpty) {
      return const SizedBox.shrink();
    }

    return _AccordBlock(accords: _accords!);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Accord block — dark container with stacked bar rows
// ─────────────────────────────────────────────────────────────────────────────

class _AccordBlock extends StatelessWidget {
  const _AccordBlock({required this.accords});

  final List<EditableAccord> accords;

  @override
  Widget build(BuildContext context) {
    // Normalise so the most-intense bar reaches 100 % width.
    final maxIntensity = accords.fold<int>(
      1,
      (prev, a) => a.intensity > prev ? a.intensity : prev,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section label
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'acordes principales',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),

        // Dark block
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(AppRadii.block),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < accords.length; i++) ...[
                if (i > 0) const SizedBox(height: 3),
                _BarRow(
                  accord: accords[i],
                  widthFactor: accords[i].intensity / maxIntensity,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single bar row — name centred inside the coloured fill
// ─────────────────────────────────────────────────────────────────────────────

class _BarRow extends StatelessWidget {
  const _BarRow({required this.accord, required this.widthFactor});

  final EditableAccord accord;

  /// 0.0 – 1.0, relative to the most intense accord in the profile.
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    final barColor = _parseHex(accord.accord.colorHex);
    final textColor = _parseHex(accord.accord.textColorHex);

    return SizedBox(
      height: 28,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // The filled bar needs a minimum visible width even at low intensity.
          final minWidth = 40.0;
          final availableWidth = constraints.maxWidth;
          final barWidth = (widthFactor * availableWidth).clamp(
            minWidth,
            availableWidth,
          );

          return Stack(
            children: [
              // Track (dark, full width)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: const ColoredBox(color: Color(0xFF3A3A3A)),
                ),
              ),
              // Coloured fill
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: barWidth,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: ColoredBox(color: barColor),
                ),
              ),
              // Name label centred inside the coloured fill
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: barWidth,
                child: Center(
                  child: Text(
                    accord.accord.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static Color _parseHex(String value) {
    final clean = value.replaceFirst('#', '');
    final parsed = int.tryParse(clean, radix: 16);
    return parsed == null
        ? const Color(0xFF888888)
        : Color(0xFF000000 | parsed);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading placeholder
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(AppRadii.block),
      ),
      child: const Center(
        child: SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF555555),
          ),
        ),
      ),
    );
  }
}
