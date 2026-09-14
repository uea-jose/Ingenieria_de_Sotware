import 'package:flutter/material.dart';

import '../../../data/api/catalog_admin_api.dart';
import '../../../models/brand.dart';
import '../../../models/category.dart';
import '../../../models/product.dart';

class ProductForm extends StatefulWidget {
  const ProductForm({
    super.key,
    required this.api,
    required this.brands,
    required this.categories,
    this.product,
    this.initialName = '',
    this.initialBrand,
    this.embedded = false,
    this.extraData,
    this.onSaved,
    this.onDraftChanged,
    this.onSavingChanged,
    this.creating = false,
  });

  final CatalogAdminApi api;
  final List<Brand> brands;
  final List<Category> categories;
  final Product? product;
  final String initialName;
  final int? initialBrand;
  final bool embedded;
  final bool creating;
  final Map<String, dynamic> Function()? extraData;
  final ValueChanged<Product>? onSaved;
  final void Function(String name, String image, int? brand)? onDraftChanged;
  final ValueChanged<bool>? onSavingChanged;

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _form = GlobalKey<FormState>();
  late final _fields = <String, TextEditingController>{
    'nombre': TextEditingController(
      text: widget.product?.name ?? widget.initialName,
    ),
    'codigo': TextEditingController(text: widget.product?.code ?? ''),
    'precio': TextEditingController(
      text: widget.product?.price.toString() ?? '',
    ),
    'stock': TextEditingController(
      text: '${widget.product?.inventory?.stock ?? 0}',
    ),
    'volumenMl': TextEditingController(
      text: widget.product?.volumeMl?.toString() ?? '',
    ),
    'descripcion': TextEditingController(
      text: widget.product?.description ?? '',
    ),
    'imagenUrl': TextEditingController(text: widget.product?.imageUrl ?? ''),
  };
  late int? _brand =
      widget.brands.any(
        (b) => b.id == (widget.product?.brandId ?? widget.initialBrand),
      )
      ? widget.product?.brandId ?? widget.initialBrand
      : null;
  late int? _category =
      widget.categories.any((c) => c.id == widget.product?.categoryId)
      ? widget.product?.categoryId
      : null;
  late bool _active = widget.product?.active ?? true;
  late String _gender = widget.product?.gender ?? 'UNISEX';
  bool _saving = false;
  String? _error;

  void _changed() => widget.onDraftChanged?.call(
    _fields['nombre']!.text,
    _fields['imagenUrl']!.text,
    _brand,
  );

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  String? _validate(String key, String? value) {
    final text = value?.trim() ?? '';
    if (['nombre', 'codigo', 'precio', 'stock'].contains(key) && text.isEmpty) {
      return 'Campo obligatorio';
    }
    if (key == 'precio') {
      final number = double.tryParse(text.replaceAll(',', '.'));
      if (number == null || !number.isFinite || number <= 0) {
        return 'Ingresa un precio mayor que cero';
      }
    }
    if (key == 'stock' || key == 'volumenMl' && text.isNotEmpty) {
      final number = int.tryParse(text);
      if (number == null || number < (key == 'stock' ? 0 : 1)) {
        return 'Ingresa un entero valido';
      }
    }
    if (key == 'imagenUrl' && text.isNotEmpty && !text.startsWith('assets/')) {
      final uri = Uri.tryParse(text);
      if (uri == null ||
          !['https', 'http'].contains(uri.scheme) ||
          uri.host.isEmpty) {
        return 'Ingresa una URL http o https';
      }
    }
    return null;
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    widget.onSavingChanged?.call(true);
    try {
      final data = <String, dynamic>{
        for (final key in ['nombre', 'codigo', 'descripcion'])
          key: _fields[key]!.text.trim(),
        'precio': double.parse(
          _fields['precio']!.text.trim().replaceAll(',', '.'),
        ),
        'stock': int.parse(_fields['stock']!.text.trim()),
        'volumenMl': int.tryParse(_fields['volumenMl']!.text.trim()),
        'imagenUrl': _fields['imagenUrl']!.text.trim().isEmpty
            ? null
            : _fields['imagenUrl']!.text.trim(),
        'marcaId': _brand,
        'categoriaId': _category,
        'activo': _active,
        'genero': _gender,
        ...?widget.extraData?.call(),
      };
      final product = await widget.api.saveProduct(
        data,
        id: widget.creating ? null : widget.product?.id,
      );
      if (mounted) {
        if (widget.onSaved != null) {
          widget.onSaved!(product);
          setState(() => _saving = false);
        } else {
          Navigator.pop(context, product);
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error is CatalogApiException
              ? error.message
              : 'No se pudo guardar el producto. Intenta nuevamente.';
          _saving = false;
        });
      }
    } finally {
      widget.onSavingChanged?.call(false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: _ProductFormShell(
      embedded: widget.embedded,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.product == null || widget.creating
                      ? 'Ingresar perfume'
                      : 'Editar perfume',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width =
                        constraints.maxWidth < (widget.embedded ? 380 : 500)
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 16) / 2;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        for (final entry in {
                          'nombre': 'Nombre del perfume',
                          'codigo': 'Codigo unico',
                          'precio': 'Precio',
                          'stock': 'Unidades',
                          'volumenMl': 'Volumen (ml)',
                          'imagenUrl': 'URL de imagen',
                          'descripcion': 'Descripcion',
                        }.entries)
                          SizedBox(
                            width: entry.key == 'descripcion'
                                ? constraints.maxWidth
                                : width,
                            child: TextFormField(
                              controller: _fields[entry.key],
                              onChanged: (_) => _changed(),
                              enabled: !_saving,
                              decoration: InputDecoration(
                                labelText: entry.value,
                              ),
                              keyboardType:
                                  [
                                    'precio',
                                    'stock',
                                    'volumenMl',
                                  ].contains(entry.key)
                                  ? const TextInputType.numberWithOptions(
                                      decimal: true,
                                    )
                                  : TextInputType.text,
                              maxLines: entry.key == 'descripcion' ? 3 : 1,
                              validator: (value) => _validate(entry.key, value),
                            ),
                          ),
                        SizedBox(
                          width: width,
                          child: DropdownButtonFormField<int>(
                            initialValue: _brand,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Casa fabricante',
                            ),
                            items: [
                              for (final b in widget.brands)
                                DropdownMenuItem(
                                  value: b.id,
                                  child: Text(
                                    b.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: _saving
                                ? null
                                : (value) {
                                    setState(() => _brand = value);
                                    _changed();
                                  },
                            validator: (value) =>
                                value == null ? 'Selecciona una casa' : null,
                          ),
                        ),
                        SizedBox(
                          width: width,
                          child: DropdownButtonFormField<int>(
                            initialValue: _category,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Categoria',
                            ),
                            items: [
                              for (final c in widget.categories)
                                DropdownMenuItem(
                                  value: c.id,
                                  child: Text(
                                    c.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: _saving
                                ? null
                                : (value) {
                                    setState(() => _category = value);
                                    _changed();
                                  },
                            validator: (value) => value == null
                                ? 'Selecciona una categoria'
                                : null,
                          ),
                        ),
                        SizedBox(
                          width: width,
                          child: DropdownButtonFormField<String>(
                            initialValue: _gender,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Genero',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'MASCULINO',
                                child: Text('Hombre'),
                              ),
                              DropdownMenuItem(
                                value: 'FEMENINO',
                                child: Text('Mujer'),
                              ),
                              DropdownMenuItem(
                                value: 'UNISEX',
                                child: Text('Unisex'),
                              ),
                            ],
                            onChanged: _saving
                                ? null
                                : (value) {
                                    setState(() => _gender = value ?? 'UNISEX');
                                    _changed();
                                  },
                          ),
                        ),
                      ],
                    );
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Producto activo'),
                  value: _active,
                  onChanged: _saving
                      ? null
                      : (value) {
                          setState(() => _active = value);
                          _changed();
                        },
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    if (!widget.embedded)
                      TextButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(
                        _saving ? 'Guardando...' : 'Guardar producto',
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

class _ProductFormShell extends StatelessWidget {
  const _ProductFormShell({required this.embedded, required this.child});
  final bool embedded;
  final Widget child;
  @override
  Widget build(BuildContext context) => embedded
      ? child
      : Dialog(insetPadding: const EdgeInsets.all(16), child: child);
}
