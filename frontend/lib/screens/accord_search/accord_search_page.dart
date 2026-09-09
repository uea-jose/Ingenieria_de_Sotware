import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_design_tokens.dart';
import '../../data/api/api_service.dart';
import '../../models/aroma_accord.dart';
import '../../models/product.dart';
import '../../widgets/layout/top_navigation.dart';
import '../../widgets/product/accord_bar_row.dart';
import '../product_detail/product_detail_page.dart';

/// Public "Buscar por acordes" page — Fragrantica style.
///
/// Desktop layout (≥ 680 px):
///   Left  ~42 %  — dark panel: title + "Añadir acorde" input + bars
///   Right ~58 %  — product results grid
///
/// The "Añadir acorde" dropdown uses a dark theme with colour dots,
/// matching the Fragrantica dropdown exactly.
class AccordSearchPage extends StatefulWidget {
  const AccordSearchPage({super.key, this.cartCount = 0, this.onAddToCart});

  final int cartCount;
  final ValueChanged<Product>? onAddToCart;

  @override
  State<AccordSearchPage> createState() => _AccordSearchPageState();
}

class _AccordSearchPageState extends State<AccordSearchPage> {
  List<AromaAccord> _masterAccords = const [];
  List<_ActiveAccord> _active = const [];
  List<Product> _results = const [];
  AromaAccord? _accordToAdd;

  bool _loadingAccords = true;
  bool _searching = false;
  String? _error;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadAccords();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  Future<void> _loadAccords() async {
    try {
      final accords = await ApiService.loadAccords();
      if (mounted) {
        setState(() {
          _masterAccords = accords;
          _loadingAccords = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'No se pudieron cargar los acordes.';
          _loadingAccords = false;
        });
      }
    }
  }

  void _scheduleSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), _search);
  }

  Future<void> _search() async {
    if (_active.isEmpty) {
      if (mounted) setState(() => _results = const []);
      return;
    }
    if (mounted) setState(() => _searching = true);
    try {
      final intensities = {for (final a in _active) a.accord.slug: a.intensity};
      final results = await ApiService.searchByAccords(intensities);
      if (mounted) setState(() => _results = results);
    } catch (_) {
      // keep previous results
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  // ── Accord management ─────────────────────────────────────────────────────

  void _addAccord() {
    final accord = _accordToAdd;
    if (accord == null) return;
    if (_active.any((a) => a.accord.id == accord.id)) return;
    if (_active.length >= 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Máximo 8 acordes.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() {
      _active = [..._active, _ActiveAccord(accord: accord, intensity: 75)];
      _accordToAdd = null;
    });
    _scheduleSearch();
  }

  void _updateIntensity(int id, int intensity) {
    setState(() {
      _active = [
        for (final a in _active)
          if (a.accord.id == id)
            _ActiveAccord(accord: a.accord, intensity: intensity)
          else
            a,
      ];
    });
    _scheduleSearch();
  }

  void _removeAccord(int id) {
    setState(() {
      _active = _active.where((a) => a.accord.id != id).toList();
    });
    _scheduleSearch();
  }

  void _reset() {
    setState(() {
      _active = const [];
      _results = const [];
      _accordToAdd = null;
    });
  }

  void _openProduct(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailPage(
          productId: product.id,
          cartCount: widget.cartCount,
          initialProduct: product,
          onAddToCart: widget.onAddToCart ?? (_) {},
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Column(
        children: [
          TopNavigation(
            cartCount: widget.cartCount,
            onCatalogPressed: () => Navigator.of(context).pop(),
            onCartPressed: () => Navigator.of(context).pop(),
            searchBox: const SizedBox.shrink(),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loadingAccords) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                setState(() {
                  _error = null;
                  _loadingAccords = true;
                });
                _loadAccords();
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final vw = MediaQuery.sizeOf(context).width;
    final side = AppLayout.horizontalPadding(vw);
    final maxW = AppLayout.contentMaxWidth(vw);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(side, 28, side, 48),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 680;

              // ── Page title (outside dark panel, like Fragrantica) ─────────
              final title = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Buscar por acordes',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Crea un perfil de acordes y encuentra perfumes con una intensidad de acordes similar.',
                    style: TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
                  ),
                ],
              );

              final accordPanel = _AccordPanel(
                masterAccords: _masterAccords,
                active: _active,
                accordToAdd: _accordToAdd,
                onAccordToAddChanged: (a) => setState(() => _accordToAdd = a),
                onAdd: _addAccord,
                onUpdateIntensity: _updateIntensity,
                onRemove: _removeAccord,
                onReset: _reset,
              );

              final resultsPanel = _ResultsPanel(
                results: _results,
                searching: _searching,
                activeCount: _active.length,
                onOpenProduct: _openProduct,
              );

              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    title,
                    const SizedBox(height: 20),
                    accordPanel,
                    const SizedBox(height: 28),
                    resultsPanel,
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  title,
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left ~42 %
                      SizedBox(
                        width: constraints.maxWidth * 0.42,
                        child: accordPanel,
                      ),
                      const SizedBox(width: 22),
                      // Right ~58 %
                      Expanded(child: resultsPanel),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Left panel — accordion selector + bars
// ─────────────────────────────────────────────────────────────────────────────

class _AccordPanel extends StatelessWidget {
  const _AccordPanel({
    required this.masterAccords,
    required this.active,
    required this.accordToAdd,
    required this.onAccordToAddChanged,
    required this.onAdd,
    required this.onUpdateIntensity,
    required this.onRemove,
    required this.onReset,
  });

  final List<AromaAccord> masterAccords;
  final List<_ActiveAccord> active;
  final AromaAccord? accordToAdd;
  final ValueChanged<AromaAccord?> onAccordToAddChanged;
  final VoidCallback onAdd;
  final void Function(int id, int intensity) onUpdateIntensity;
  final void Function(int id) onRemove;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final available = masterAccords
        .where((a) => !active.any((act) => act.accord.id == a.id))
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF242424),
        borderRadius: BorderRadius.circular(AppRadii.block),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Section label ──────────────────────────────────────────────
          const Text(
            'Buscar por acordes',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),

          // ── Toolbar: + Añadir acorde  Reset ───────────────────────────
          Row(
            children: [
              // Dark-themed dropdown
              Expanded(
                child: Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(canvasColor: const Color(0xFF2E2E2E)),
                  child: DropdownButtonFormField<AromaAccord>(
                    key: ValueKey('add-${accordToAdd?.id}'),
                    initialValue: accordToAdd,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF2E2E2E),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: '+ Añadir acorde',
                      hintStyle: const TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 12,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 9,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF2E2E2E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Color(0xFF444444)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Color(0xFF444444)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                    ),
                    items: [
                      for (final accord in available)
                        DropdownMenuItem(
                          value: accord,
                          child: Row(
                            children: [
                              // Colour dot
                              Container(
                                width: 12,
                                height: 12,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: _hexColor(accord.colorHex),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  accord.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                    onChanged: onAccordToAddChanged,
                    selectedItemBuilder: (context) => [
                      for (final accord in available)
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: _hexColor(accord.colorHex),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Text(
                              accord.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // + Añadir button (teal/green like Fragrantica)
              ElevatedButton(
                onPressed: accordToAdd == null ? null : onAdd,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2B7A5E),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF2B4040),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('+ Añadir'),
              ),
              const SizedBox(width: 4),
              // Reset button
              OutlinedButton(
                onPressed: active.isEmpty ? null : onReset,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFCCCCCC),
                  side: const BorderSide(color: Color(0xFF555555)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  textStyle: const TextStyle(fontSize: 12),
                ),
                child: const Text('Reset'),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Accord bars ────────────────────────────────────────────────
          if (active.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Añade entre 1 y 8 acordes para empezar a buscar.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF666666), fontSize: 12),
              ),
            )
          else
            Column(
              children: [
                for (var i = 0; i < active.length; i++) ...[
                  if (i > 0) const SizedBox(height: 4),
                  AccordBarRow(
                    name: active[i].accord.name,
                    colorHex: active[i].accord.colorHex,
                    intensity: active[i].intensity,
                    editMode: true,
                    onIntensityChanged: (v) =>
                        onUpdateIntensity(active[i].accord.id, v),
                    onRemove: () => onRemove(active[i].accord.id),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  static Color _hexColor(String v) {
    final c = v.replaceFirst('#', '');
    final n = int.tryParse(c, radix: 16);
    return n == null ? const Color(0xFF888888) : Color(0xFF000000 | n);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Right panel — results
// ─────────────────────────────────────────────────────────────────────────────

class _ResultsPanel extends StatelessWidget {
  const _ResultsPanel({
    required this.results,
    required this.searching,
    required this.activeCount,
    required this.onOpenProduct,
  });

  final List<Product> results;
  final bool searching;
  final int activeCount;
  final ValueChanged<Product> onOpenProduct;

  @override
  Widget build(BuildContext context) {
    if (activeCount == 0) {
      return const Padding(
        padding: EdgeInsets.only(top: 60),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.tune_outlined, size: 48, color: Color(0xFF555555)),
              SizedBox(height: 12),
              Text(
                'Selecciona acordes para buscar perfumes.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF777777), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (searching) {
      return const Padding(
        padding: EdgeInsets.only(top: 60),
        child: Center(child: CircularProgressIndicator(color: Colors.white54)),
      );
    }

    if (results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 60),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, size: 48, color: Color(0xFF555555)),
              SizedBox(height: 12),
              Text(
                'Sin resultados para esta combinación de acordes.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF777777), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Resultados: ${results.length}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
          ),
        ),
        for (final product in results) ...[
          _ProductCard(product: product, onTap: () => onOpenProduct(product)),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Product result card — dark theme
// ─────────────────────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF242424),
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: const Color(0xFF333333)),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.button),
              child: Container(
                width: 64,
                height: 64,
                color: const Color(0xFF333333),
                child: product.imageUrl != null
                    ? Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.spa_outlined,
                          color: Color(0xFF666666),
                        ),
                      )
                    : const Icon(Icons.spa_outlined, color: Color(0xFF666666)),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.brand.name,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF888888),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${product.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF4ECDC4),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF555555), size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal model
// ─────────────────────────────────────────────────────────────────────────────

class _ActiveAccord {
  const _ActiveAccord({required this.accord, required this.intensity});
  final AromaAccord accord;
  final int intensity;
}
