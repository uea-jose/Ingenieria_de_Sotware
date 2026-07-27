import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_design_tokens.dart';
import '../../../data/api/catalog_admin_api.dart';
import '../../../models/accord_profile.dart';
import '../../../models/aroma_accord.dart';
import '../../../models/brand.dart';
import '../../../models/perfume_reference.dart';
import '../../../models/product.dart';
import 'accord_sorting.dart';

class AccordEditorPage extends StatefulWidget {
  const AccordEditorPage({super.key});

  @override
  State<AccordEditorPage> createState() => _AccordEditorPageState();
}

class _AccordEditorPageState extends State<AccordEditorPage> {
  final _api = CatalogAdminApi();
  final _emailController = TextEditingController(text: 'admin@aromasstore.com');
  final _passwordController = TextEditingController();
  final _valueControllers = <int, TextEditingController>{};
  final _valueFocusNodes = <int, FocusNode>{};

  List<Brand> _brands = const [];
  List<Product> _products = const [];
  List<PerfumeReference> _references = const [];
  List<AromaAccord> _masterAccords = const [];
  List<EditableAccord> _accords = const [];
  List<EditableAccord> _originalAccords = const [];

  Brand? _selectedBrand;
  Product? _selectedProduct;
  PerfumeReference? _selectedReference;
  AromaAccord? _accordToAdd;
  AccordProfile? _productProfile;
  AccordProfile? _referenceProfile;
  bool _busy = false;
  bool _authenticated = false;
  bool _dirty = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    for (final controller in _valueControllers.values) {
      controller.dispose();
    }
    for (final focusNode in _valueFocusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await action();
    } on CatalogApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (mounted) setState(() => _error = 'No se pudo completar la acción.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _login() {
    return _run(() async {
      await _api.login(
        email: _emailController.text,
        password: _passwordController.text,
      );
      final results = await Future.wait([
        _api.loadBrands(),
        _api.loadProducts(),
        _api.loadAccords(),
      ]);

      if (!mounted) return;
      setState(() {
        _brands = results[0] as List<Brand>;
        _products = results[1] as List<Product>;
        _masterAccords = results[2] as List<AromaAccord>;
        _authenticated = true;
      });
    });
  }

  Future<void> _selectBrand(Brand? brand) {
    if (brand == null) return Future.value();
    setState(() {
      _selectedBrand = brand;
      _selectedReference = null;
      _referenceProfile = null;
      _references = const [];
    });

    return _run(() async {
      final references = await _api.loadReferences(brand.id);
      if (mounted) setState(() => _references = references);
    });
  }

  Future<void> _selectReference(PerfumeReference? reference) {
    if (reference == null) return Future.value();
    setState(() => _selectedReference = reference);

    return _run(() async {
      final profile = await _api.loadReferenceProfile(reference.id);
      if (mounted) setState(() => _referenceProfile = profile);
    });
  }

  Future<void> _selectProduct(Product? product) {
    if (product == null) return Future.value();
    setState(() => _selectedProduct = product);

    return _run(() async {
      final profile = await _api.loadProductProfile(product.id);
      if (mounted) _replaceProfile(profile);
    });
  }

  void _replaceProfile(AccordProfile profile) {
    final currentIds = profile.accords.map((item) => item.accord.id).toSet();
    final obsoleteIds = _valueControllers.keys
        .where((id) => !currentIds.contains(id))
        .toList();

    for (final id in obsoleteIds) {
      _valueControllers.remove(id)?.dispose();
      _valueFocusNodes.remove(id)?.dispose();
    }

    for (final item in profile.accords) {
      _valueControllers.putIfAbsent(
        item.accord.id,
        () => TextEditingController(),
      );
      _valueFocusNodes.putIfAbsent(item.accord.id, FocusNode.new);
      _valueControllers[item.accord.id]!.text = '${item.intensity}';
    }

    setState(() {
      _productProfile = profile;
      _accords = normalizeAccordOrder(profile.accords);
      _originalAccords = List.of(_accords);
      _dirty = false;
      _accordToAdd = null;
    });
  }

  Future<void> _copyReference() {
    final product = _selectedProduct;
    final reference = _selectedReference;
    if (product == null || reference == null) return Future.value();

    return _run(() async {
      final profile = await _api.assignReference(
        productId: product.id,
        referenceId: reference.id,
      );
      if (mounted) _replaceProfile(profile);
    });
  }

  void _changeIntensity(int accordId, int intensity) {
    final normalized = updateAccordIntensity(_accords, accordId, intensity);
    final controller = _valueControllers[accordId];
    if (controller != null &&
        !(_valueFocusNodes[accordId]?.hasFocus ?? false)) {
      controller.text = '$intensity';
    }
    setState(() {
      _accords = normalized;
      _dirty = true;
    });
  }

  void _removeAccord(int accordId) {
    if (_accords.length <= 1) {
      setState(() => _error = 'El perfil debe conservar al menos un acorde.');
      return;
    }

    _valueControllers.remove(accordId)?.dispose();
    _valueFocusNodes.remove(accordId)?.dispose();
    setState(() {
      _accords = normalizeAccordOrder(
        _accords.where((item) => item.accord.id != accordId).toList(),
      );
      _dirty = true;
    });
  }

  void _addAccord() {
    final accord = _accordToAdd;
    if (accord == null) return;

    final item = EditableAccord(
      accord: accord,
      intensity: 50,
      displayOrder: _accords.length + 1,
    );
    _valueControllers[accord.id] = TextEditingController(text: '50');
    _valueFocusNodes[accord.id] = FocusNode();

    setState(() {
      _accords = normalizeAccordOrder([..._accords, item]);
      _accordToAdd = null;
      _dirty = true;
    });
  }

  void _resetLocal() {
    for (final item in _originalAccords) {
      _valueControllers[item.accord.id]?.text = '${item.intensity}';
    }
    setState(() {
      _accords = List.of(_originalAccords);
      _dirty = false;
    });
  }

  Future<void> _save() {
    final product = _selectedProduct;
    if (product == null || _accords.isEmpty) return Future.value();

    return _run(() async {
      final profile = await _api.saveProductProfile(
        productId: product.id,
        accords: _accords,
      );
      if (mounted) _replaceProfile(profile);
    });
  }

  Future<void> _restore() {
    final product = _selectedProduct;
    if (product == null) return Future.value();

    return _run(() async {
      final profile = await _api.restoreProductProfile(product.id);
      if (mounted) _replaceProfile(profile);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor de acordes'),
        actions: [
          if (_authenticated)
            TextButton.icon(
              onPressed: _busy
                  ? null
                  : () {
                      _api.logout();
                      setState(() {
                        _authenticated = false;
                        _productProfile = null;
                        _accords = const [];
                      });
                    },
              icon: const Icon(Icons.logout),
              label: const Text('Salir'),
            ),
        ],
      ),
      body: SafeArea(child: _authenticated ? _buildEditor() : _buildLogin()),
    );
  }

  Widget _buildLogin() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Administración del catálogo',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Inicia sesión con el usuario administrador de Aromas Store.',
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    onSubmitted: (_) => _login(),
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _error!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _busy ? null : _login,
                    icon: _busy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                    label: const Text('Ingresar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditor() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSelectors(),
              if (_error != null) ...[
                const SizedBox(height: 12),
                MaterialBanner(
                  content: Text(_error!),
                  actions: [
                    TextButton(
                      onPressed: () => setState(() => _error = null),
                      child: const Text('Cerrar'),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              if (_accords.isEmpty)
                _buildEmptyState()
              else
                _buildProfileEditor(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectors() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Producto y referencia maestra',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 760;
                final fields = [
                  DropdownButtonFormField<Product>(
                    key: ValueKey('product-${_selectedProduct?.id}'),
                    initialValue: _selectedProduct,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Producto editable',
                    ),
                    items: [
                      for (final product in _products)
                        DropdownMenuItem(
                          value: product,
                          child: Text(product.name),
                        ),
                    ],
                    onChanged: _busy ? null : _selectProduct,
                  ),
                  DropdownButtonFormField<Brand>(
                    key: ValueKey('brand-${_selectedBrand?.id}'),
                    initialValue: _selectedBrand,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Casa de referencia',
                    ),
                    items: [
                      for (final brand in _brands)
                        DropdownMenuItem(value: brand, child: Text(brand.name)),
                    ],
                    onChanged: _busy ? null : _selectBrand,
                  ),
                  DropdownButtonFormField<PerfumeReference>(
                    key: ValueKey('reference-${_selectedReference?.id}'),
                    initialValue: _selectedReference,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Perfume de referencia',
                    ),
                    items: [
                      for (final reference in _references)
                        DropdownMenuItem(
                          value: reference,
                          child: Text(reference.name),
                        ),
                    ],
                    onChanged: _busy ? null : _selectReference,
                  ),
                ];

                if (compact) {
                  return Column(
                    children: [
                      for (final field in fields) ...[
                        field,
                        const SizedBox(height: 12),
                      ],
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final field in fields) ...[
                      Expanded(child: field),
                      if (field != fields.last) const SizedBox(width: 12),
                    ],
                  ],
                );
              },
            ),
            if (_referenceProfile != null) ...[
              const SizedBox(height: 12),
              Text(
                'Perfil maestro: ${_referenceProfile!.accords.length} acordes.',
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed:
                      _busy ||
                          _selectedProduct == null ||
                          _selectedReference == null ||
                          (_productProfile?.referenceId != null)
                      ? null
                      : _copyReference,
                  icon: const Icon(Icons.copy_all_outlined),
                  label: const Text('Copiar perfil al producto'),
                ),
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.tune, size: 54, color: AppColors.secondary),
            const SizedBox(height: 12),
            Text(
              _selectedProduct == null
                  ? 'Selecciona un producto para comenzar.'
                  : 'Este producto todavía no tiene un perfil aromático.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Selecciona una casa y una referencia para copiar su perfil maestro.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileEditor() {
    final availableAccords = _masterAccords
        .where((accord) => !_accords.any((item) => item.accord.id == accord.id))
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _productProfile?.entityName ?? 'Perfil aromático',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '${_accords.length} acordes · cambios ${_dirty ? "sin guardar" : "guardados"}',
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: _busy || !_dirty ? null : _resetLocal,
                      child: const Text('Deshacer cambios'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _restore,
                      icon: const Icon(Icons.restore),
                      label: const Text('Restaurar maestro'),
                    ),
                    FilledButton.icon(
                      onPressed: _busy || !_dirty ? null : _save,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Guardar'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<AromaAccord>(
                    key: ValueKey('add-${_accordToAdd?.id}'),
                    initialValue: _accordToAdd,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Agregar acorde',
                    ),
                    items: [
                      for (final accord in availableAccords)
                        DropdownMenuItem(
                          value: accord,
                          child: Text(accord.name),
                        ),
                    ],
                    onChanged: (value) => setState(() => _accordToAdd = value),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.tonalIcon(
                  onPressed: _accordToAdd == null ? null : _addAccord,
                  icon: const Icon(Icons.add),
                  label: const Text('Añadir'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: _accords.length * 86,
              child: Stack(
                children: [
                  for (var index = 0; index < _accords.length; index++)
                    AnimatedPositioned(
                      key: ValueKey(_accords[index].accord.id),
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      top: index * 86,
                      left: 0,
                      right: 0,
                      height: 76,
                      child: _AccordRow(
                        item: _accords[index],
                        controller:
                            _valueControllers[_accords[index].accord.id]!,
                        focusNode: _valueFocusNodes[_accords[index].accord.id]!,
                        onChanged: (value) =>
                            _changeIntensity(_accords[index].accord.id, value),
                        onRemove: () =>
                            _removeAccord(_accords[index].accord.id),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccordRow extends StatelessWidget {
  const _AccordRow({
    required this.item,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onRemove,
  });

  final EditableAccord item;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<int> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final color = _hexColor(item.accord.colorHex);
    final textColor = _hexColor(item.accord.textColorHex);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 138,
              child: Text(
                item.accord.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E9EF),
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: item.intensity / 100,
                    child: Container(
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        item.accord.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  Slider(
                    value: item.intensity.toDouble(),
                    min: 1,
                    max: 100,
                    divisions: 99,
                    activeColor: Colors.transparent,
                    inactiveColor: Colors.transparent,
                    thumbColor: Theme.of(context).colorScheme.primary,
                    onChanged: (value) => onChanged(value.round()),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 62,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                onSubmitted: (value) {
                  final parsed = int.tryParse(value);
                  if (parsed != null) onChanged(parsed.clamp(1, 100));
                },
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Eliminar acorde',
              onPressed: onRemove,
              icon: const Icon(Icons.close, color: AppColors.error),
            ),
          ],
        ),
      ),
    );
  }

  static Color _hexColor(String value) {
    final normalized = value.replaceFirst('#', '');
    final parsed = int.tryParse(normalized, radix: 16);
    return parsed == null ? AppColors.secondary : Color(0xFF000000 | parsed);
  }
}
