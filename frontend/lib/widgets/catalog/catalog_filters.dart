import 'package:flutter/material.dart';

import '../../app/app_design_tokens.dart';
import '../../models/brand.dart';
import '../../models/category.dart';

class CatalogFilters extends StatelessWidget {
  const CatalogFilters({
    required this.searchController,
    required this.categories,
    required this.brands,
    required this.selectedCategoryId,
    required this.selectedBrandId,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onBrandChanged,
    required this.onClear,
    super.key,
  });

  final TextEditingController searchController;
  final List<Category> categories;
  final List<Brand> brands;
  final int? selectedCategoryId;
  final int? selectedBrandId;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<int?> onCategoryChanged;
  final ValueChanged<int?> onBrandChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final sidePadding = AppLayout.horizontalPadding(viewportWidth);

    return Padding(
      padding: EdgeInsets.fromLTRB(sidePadding, 12, sidePadding, 18),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: AppLayout.contentMaxWidth(viewportWidth),
          ),
          child: Card(
            elevation: 0,
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.card),
              side: const BorderSide(color: AppColors.borderSoft),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final narrow = constraints.maxWidth < 620;
                  final medium = constraints.maxWidth < 900;
                  final gap = narrow ? 10.0 : 12.0;
                  final searchWidth = narrow
                      ? constraints.maxWidth
                      : medium
                      ? constraints.maxWidth
                      : 360.0;
                  final selectWidth = narrow
                      ? constraints.maxWidth
                      : medium
                      ? (constraints.maxWidth - gap) / 2
                      : 190.0;
                  final clearWidth = narrow
                      ? constraints.maxWidth
                      : medium
                      ? 150.0
                      : 118.0;

                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: searchWidth,
                        child: TextField(
                          controller: searchController,
                          onChanged: onSearchChanged,
                          decoration: const InputDecoration(
                            labelText: 'Buscar producto o marca',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: selectWidth,
                        child: DropdownButtonFormField<int?>(
                          isExpanded: true,
                          initialValue: selectedCategoryId,
                          decoration: const InputDecoration(
                            labelText: 'Categoria',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Todas'),
                            ),
                            ...categories.map(
                              (category) => DropdownMenuItem<int?>(
                                value: category.id,
                                child: Text(category.name),
                              ),
                            ),
                          ],
                          onChanged: onCategoryChanged,
                        ),
                      ),
                      SizedBox(
                        width: selectWidth,
                        child: DropdownButtonFormField<int?>(
                          isExpanded: true,
                          initialValue: selectedBrandId,
                          decoration: const InputDecoration(
                            labelText: 'Marca',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Todas'),
                            ),
                            ...brands.map(
                              (brand) => DropdownMenuItem<int?>(
                                value: brand.id,
                                child: Text(brand.name),
                              ),
                            ),
                          ],
                          onChanged: onBrandChanged,
                        ),
                      ),
                      SizedBox(
                        width: clearWidth,
                        child: OutlinedButton.icon(
                          onPressed: onClear,
                          icon: const Icon(Icons.filter_alt_off_outlined),
                          label: const Text('Limpiar'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
