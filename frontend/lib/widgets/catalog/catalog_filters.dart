import 'package:flutter/material.dart';

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
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Color(0xFFE6E1D8)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 760;
                  final fields = [
                    Expanded(
                      flex: 2,
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
                    Expanded(
                      child: DropdownButtonFormField<int?>(
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
                    Expanded(
                      child: DropdownButtonFormField<int?>(
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
                    OutlinedButton.icon(
                      onPressed: onClear,
                      icon: const Icon(Icons.filter_alt_off_outlined),
                      label: const Text('Limpiar'),
                    ),
                  ];

                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < fields.length; i++) ...[
                          if (fields[i] is Expanded)
                            (fields[i] as Expanded).child
                          else
                            fields[i],
                          if (i != fields.length - 1)
                            const SizedBox(height: 12),
                        ],
                      ],
                    );
                  }

                  return Row(
                    children: [
                      fields[0],
                      const SizedBox(width: 12),
                      fields[1],
                      const SizedBox(width: 12),
                      fields[2],
                      const SizedBox(width: 12),
                      fields[3],
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
