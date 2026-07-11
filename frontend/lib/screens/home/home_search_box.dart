import 'package:flutter/material.dart';

import '../../app/app_design_tokens.dart';
import '../../models/product.dart';
import '../../widgets/catalog/product_image.dart';

class HomeSearchBox extends StatelessWidget {
  const HomeSearchBox({
    required this.controller,
    required this.focusNode,
    required this.query,
    required this.suggestionTerms,
    required this.suggestions,
    required this.highlightedIndex,
    required this.onChanged,
    required this.onClear,
    required this.onClose,
    required this.onSubmitted,
    required this.onTermSelected,
    required this.onSuggestionSelected,
    required this.onViewAll,
    required this.onQuickView,
    required this.onKeyboardNavigation,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String query;
  final List<String> suggestionTerms;
  final List<Product> suggestions;
  final int highlightedIndex;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onClose;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<String> onTermSelected;
  final ValueChanged<Product> onSuggestionSelected;
  final VoidCallback onViewAll;
  final ValueChanged<Product> onQuickView;
  final KeyEventResult Function(KeyEvent event) onKeyboardNavigation;

  bool get _showPanel => query.trim().isNotEmpty && focusNode.hasFocus;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (_, event) => onKeyboardNavigation(event),
      child: TapRegion(
        onTapOutside: (_) => onClose(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Busca por perfume, marca o categoria',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: query.isEmpty
                    ? const Icon(Icons.tune_outlined)
                    : IconButton(
                        tooltip: 'Limpiar busqueda',
                        onPressed: onClear,
                        icon: const Icon(Icons.close),
                      ),
                filled: true,
                fillColor: AppColors.surfaceSoft,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.search),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.search),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.4,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
              ),
            ),
            if (_showPanel)
              SearchMegaPanel(
                query: query,
                suggestionTerms: suggestionTerms,
                suggestions: suggestions,
                highlightedIndex: highlightedIndex,
                onTermSelected: onTermSelected,
                onSuggestionSelected: onSuggestionSelected,
                onViewAll: onViewAll,
                onQuickView: onQuickView,
              ),
          ],
        ),
      ),
    );
  }
}

class SearchMegaPanel extends StatelessWidget {
  const SearchMegaPanel({
    required this.query,
    required this.suggestionTerms,
    required this.suggestions,
    required this.highlightedIndex,
    required this.onTermSelected,
    required this.onSuggestionSelected,
    required this.onViewAll,
    required this.onQuickView,
    super.key,
  });

  final String query;
  final List<String> suggestionTerms;
  final List<Product> suggestions;
  final int highlightedIndex;
  final ValueChanged<String> onTermSelected;
  final ValueChanged<Product> onSuggestionSelected;
  final VoidCallback onViewAll;
  final ValueChanged<Product> onQuickView;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      constraints: const BoxConstraints(maxHeight: 620),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadii.block),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: AppShadows.hover,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.block),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 720;
            final products = suggestions.take(4).toList();

            if (compact) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SuggestionTermsColumn(
                      query: query,
                      terms: suggestionTerms,
                      onTermSelected: onTermSelected,
                    ),
                    const SizedBox(height: 16),
                    _SearchProductsArea(
                      query: query,
                      products: products,
                      totalResults: suggestions.length,
                      highlightedIndex: highlightedIndex,
                      onSuggestionSelected: onSuggestionSelected,
                      onQuickView: onQuickView,
                      onViewAll: onViewAll,
                      columns: 1,
                    ),
                  ],
                ),
              );
            }

            final columns = constraints.maxWidth >= 1050 ? 3 : 2;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: constraints.maxWidth * 0.31,
                  child: _SuggestionTermsColumn(
                    query: query,
                    terms: suggestionTerms,
                    onTermSelected: onTermSelected,
                  ),
                ),
                const VerticalDivider(width: 1, color: AppColors.borderSoft),
                Expanded(
                  child: _SearchProductsArea(
                    query: query,
                    products: products,
                    totalResults: suggestions.length,
                    highlightedIndex: highlightedIndex,
                    onSuggestionSelected: onSuggestionSelected,
                    onQuickView: onQuickView,
                    onViewAll: onViewAll,
                    columns: columns,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SuggestionTermsColumn extends StatelessWidget {
  const _SuggestionTermsColumn({
    required this.query,
    required this.terms,
    required this.onTermSelected,
  });

  final String query;
  final List<String> terms;
  final ValueChanged<String> onTermSelected;

  @override
  Widget build(BuildContext context) {
    final visibleTerms = terms.take(8).toList();

    return Container(
      color: AppColors.surfaceSoft,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelLabel(text: 'SUGERENCIAS'),
          const SizedBox(height: 12),
          if (visibleTerms.isEmpty)
            const Text(
              'Prueba con una marca, categoria o perfume.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.35),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: visibleTerms.length,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final term = visibleTerms[index];
                  return _SuggestionTermTile(
                    term: term,
                    query: query,
                    onTap: () => onTermSelected(term),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _SuggestionTermTile extends StatefulWidget {
  const _SuggestionTermTile({
    required this.term,
    required this.query,
    required this.onTap,
  });

  final String term;
  final String query;
  final VoidCallback onTap;

  @override
  State<_SuggestionTermTile> createState() => _SuggestionTermTileState();
}

class _SuggestionTermTileState extends State<_SuggestionTermTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Semantics(
        button: true,
        label: 'Buscar ${widget.term}',
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 170),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: _hovered ? AppColors.bgSoftPink : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadii.search),
              border: Border(
                left: BorderSide(
                  color: _hovered ? AppColors.primary : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 18, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: _HighlightedTerm(
                    term: widget.term,
                    query: widget.query,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HighlightedTerm extends StatelessWidget {
  const _HighlightedTerm({required this.term, required this.query});

  final String term;
  final String query;

  @override
  Widget build(BuildContext context) {
    final normalizedTerm = term.toLowerCase();
    final normalizedQuery = query.trim().toLowerCase();
    final start = normalizedQuery.isEmpty
        ? -1
        : normalizedTerm.indexOf(normalizedQuery);

    if (start < 0) {
      return Text(
        term,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
      );
    }

    final end = start + normalizedQuery.length;
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
        children: [
          TextSpan(text: term.substring(0, start)),
          TextSpan(
            text: term.substring(start, end),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
              decoration: TextDecoration.underline,
            ),
          ),
          TextSpan(text: term.substring(end)),
        ],
      ),
    );
  }
}

class _SearchProductsArea extends StatelessWidget {
  const _SearchProductsArea({
    required this.query,
    required this.products,
    required this.totalResults,
    required this.highlightedIndex,
    required this.columns,
    required this.onSuggestionSelected,
    required this.onQuickView,
    required this.onViewAll,
  });

  final String query;
  final List<Product> products;
  final int totalResults;
  final int highlightedIndex;
  final int columns;
  final ValueChanged<Product> onSuggestionSelected;
  final ValueChanged<Product> onQuickView;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final title = query.trim().isEmpty
        ? 'PRODUCTOS ENCONTRADOS'
        : 'PRODUCTOS PARA ${query.trim().toUpperCase()}';

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _PanelLabel(text: title)),
              Text(
                '$totalResults resultado${totalResults == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (products.isEmpty)
            const _EmptySuggestions()
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 470),
              child: SingleChildScrollView(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final gap = 12.0;
                    final cardWidth =
                        (constraints.maxWidth - ((columns - 1) * gap)) /
                        columns;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        for (var index = 0; index < products.length; index++)
                          SizedBox(
                            width: cardWidth,
                            child: _SearchProductCard(
                              product: products[index],
                              selected: index == highlightedIndex,
                              onTap: () =>
                                  onSuggestionSelected(products[index]),
                              onQuickView: () => onQuickView(products[index]),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onViewAll,
              icon: const Icon(Icons.arrow_forward),
              label: Text(
                totalResults > 4
                    ? 'Ver todos los $totalResults productos'
                    : 'Ver todos los resultados',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchProductCard extends StatefulWidget {
  const _SearchProductCard({
    required this.product,
    required this.selected,
    required this.onTap,
    required this.onQuickView,
  });

  final Product product;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onQuickView;

  @override
  State<_SearchProductCard> createState() => _SearchProductCardState();
}

class _SearchProductCardState extends State<_SearchProductCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final stock = product.inventory?.stock ?? 0;
    return Semantics(
      button: true,
      selected: widget.selected,
      label:
          '${product.name}, ${product.brand.name}, ${product.price.toStringAsFixed(2)} dolares',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 190),
          transform: Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(
              color: widget.selected || _hovered
                  ? AppColors.primary
                  : AppColors.borderSoft,
            ),
            boxShadow: _hovered ? AppShadows.hover : AppShadows.base,
          ),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(AppRadii.card),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.card),
                    child: const SizedBox(
                      height: 150,
                      width: double.infinity,
                      child: ProductPlaceholder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    product.brand.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                      height: 1.12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '\$${product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      _MiniLabel(text: stock <= 3 ? 'Stock bajo' : 'Demo'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onQuickView,
                          icon: const Icon(Icons.visibility_outlined, size: 17),
                          label: const Text('Vista rapida'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: 'Carrito simulado desde buscador',
                        child: IconButton.filledTonal(
                          onPressed: widget.onTap,
                          icon: const Icon(Icons.add_shopping_cart, size: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PanelLabel extends StatelessWidget {
  const _PanelLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.8,
        fontSize: 12,
      ),
    );
  }
}

class _MiniLabel extends StatelessWidget {
  const _MiniLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.bgPeach,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _EmptySuggestions extends StatelessWidget {
  const _EmptySuggestions();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(18),
      child: Row(
        children: [
          Icon(Icons.search_off_outlined, color: AppColors.textSecondary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'No encontramos perfumes con ese nombre.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
