import 'package:flutter/material.dart';
import '../../../data/api/catalog_admin_api.dart';
import '../../../models/aroma_accord.dart';
import '../../../models/brand.dart';
import '../../../models/category.dart';
import '../../../models/catalog_reference.dart';
import '../../../models/product.dart';
import '../../../screens/perfumery_catalog/perfumery_catalog_page.dart';
import '../../../widgets/product/accord_bar_row.dart';
import 'accord_picker.dart';
import 'accord_sorting.dart';
import 'product_form.dart';

class CatalogAdminPage extends StatefulWidget {
  const CatalogAdminPage({super.key, this.api});
  final CatalogAdminApi? api;
  @override
  State<CatalogAdminPage> createState() => _CatalogAdminPageState();
}

class _CatalogAdminPageState extends State<CatalogAdminPage> {
  late final _api = widget.api ?? CatalogAdminApi();
  final _email = TextEditingController();
  final _password = TextEditingController();
  List<Product> _products = [];
  List<Brand> _brands = [];
  List<Category> _categories = [];
  List<AromaAccord> _library = [];
  List<EditableAccord> _accords = [], _original = [];
  Product? _product, _seed;
  String _name = '', _image = '', _brand = '';
  String? _error;
  bool _ready = false, _busy = false, _dirty = false;
  bool _obscureAdminPassword = true;
  int _revision = 0;

  /// true while the "+ Añadir acorde" temporary row/picker is open.
  bool _adding = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  // ── Accord add / replace helpers ──────────────────────────────────────────

  void _addAccordFromLibrary(AromaAccord accord) {
    setState(() {
      _accords = normalizeAccordOrder([
        ..._accords,
        EditableAccord(
          accord: accord,
          intensity: 50,
          displayOrder: _accords.length + 1,
        ),
      ]);
      _dirty = true;
      _adding = false;
    });
  }

  /// Replaces the accord [oldId] with [next], keeping the current intensity.
  void _replaceAccord(int oldId, AromaAccord next) {
    setState(() {
      _accords = normalizeAccordOrder([
        for (final item in _accords)
          if (item.accord.id == oldId)
            EditableAccord(
              accord: next,
              intensity: item.intensity,
              displayOrder: item.displayOrder,
              copiedFromReference: false,
            )
          else
            item,
      ]);
      _dirty = true;
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _login() => _run(() async {
    await _api.login(email: _email.text, password: _password.text);
    final values = await Future.wait([
      _api.loadProducts(),
      _api.loadBrands(),
      _api.loadCategories(),
      _api.loadAccords(),
    ]);
    if (!mounted) return;
    setState(() {
      _products = values[0] as List<Product>;
      _brands = values[1] as List<Brand>;
      _categories = values[2] as List<Category>;
      _library = values[3] as List<AromaAccord>;
      _ready = true;
    });
  });

  Future<bool> _canReplace() async {
    if (!_dirty) return true;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cambios sin guardar'),
            content: const Text('Descartar los cambios del perfume actual?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Continuar editando'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Descartar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _draft(Product? product, List<EditableAccord> accords, {Product? seed}) {
    setState(() {
      _product = product;
      _seed = seed;
      _accords = List.of(accords);
      _original = List.of(accords);
      _name = (product ?? seed)?.name ?? '';
      _image = (product ?? seed)?.imageUrl ?? '';
      _brand = (product ?? seed)?.brand.name ?? '';
      _dirty = seed != null;
      _revision++;
    });
  }

  Future<void> _select(Product product) async {
    if (!await _canReplace() || !mounted) return;
    await _run(() async {
      final profile = await _api.loadProductProfile(product.id);
      if (mounted) _draft(product, profile.accords);
    });
  }

  Future<void> _reference() async {
    if (!await _canReplace() || !mounted) return;
    final reference = await Navigator.push<CatalogReference>(
      context,
      MaterialPageRoute(
        builder: (_) => const PerfumeryCatalogPage(selectReference: true),
      ),
    );
    if (reference == null || !mounted) return;
    final matching = _brands.where(
      (b) =>
          normalizeCatalogText(b.name) == normalizeCatalogText(reference.brand),
    );
    List<EditableAccord> accords = [];
    String? warning;
    try {
      if (reference.approved) accords = reference.resolveProfile(_library);
    } on FormatException catch (error) {
      warning = error.message;
    }
    _draft(
      null,
      accords,
      seed: Product.fromJson({
        'nombre': reference.alias.isEmpty ? reference.name : reference.alias,
        'marcaId': matching.isEmpty ? 0 : matching.first.id,
        'marca': {'nombre': reference.brand},
        'imagenUrl': reference.imageAsset,
        'activo': true,
      }),
    );
    setState(() => _error = warning);
  }

  void _saved(Product product) {
    if (!mounted) return;
    setState(() {
      _products = [..._products.where((p) => p.id != product.id), product];
      _product = product;
      _seed = null;
      _original = List.of(_accords);
      _dirty = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfume y acordes guardados.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: const Color(0xff101315),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xffe16b46),
        brightness: Brightness.dark,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xff111416),
        border: OutlineInputBorder(),
        isDense: true,
      ),
    );
    return Theme(
      data: theme,
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Administrar catalogo'),
            actions: [
              if (_ready)
                IconButton(
                  tooltip: 'Cerrar sesion',
                  icon: const Icon(Icons.logout),
                  onPressed: _busy
                      ? null
                      : () async {
                          if (await _canReplace() && mounted) {
                            _api.logout();
                            _draft(null, []);
                            setState(() => _ready = false);
                          }
                        },
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: _ready ? 1320 : 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_busy) const LinearProgressIndicator(),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.orangeAccent),
                        ),
                      ),
                    if (!_ready) ...[
                      const Text(
                        'Acceso al catalogo',
                        style: TextStyle(fontSize: 24),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _email,
                        decoration: const InputDecoration(labelText: 'Correo'),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _password,
                        obscureText: _obscureAdminPassword,
                        autofillHints: const [AutofillHints.password],
                        onSubmitted: (_) => _login(),
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          suffixIcon: IconButton(
                            tooltip: _obscureAdminPassword
                                ? 'Mostrar contraseña'
                                : 'Ocultar contraseña',
                            icon: Icon(
                              _obscureAdminPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setState(
                              () => _obscureAdminPassword =
                                  !_obscureAdminPassword,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _busy ? null : _login,
                        child: const Text('Ingresar'),
                      ),
                    ] else ...[
                      Text(
                        _product == null
                            ? 'Ingresar una fragancia'
                            : 'Editar fragancia',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.icon(
                            onPressed: _busy
                                ? null
                                : () async {
                                    if (await _canReplace() && mounted) {
                                      _draft(null, []);
                                    }
                                  },
                            icon: const Icon(Icons.add),
                            label: const Text('Nueva fragancia'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _busy ? null : _reference,
                            icon: const Icon(
                              Icons.collections_bookmark_outlined,
                            ),
                            label: const Text('Elegir del catalogo con imagen'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Autocomplete<Product>(
                        optionsBuilder: (value) => _products.where(
                          (p) => normalizeCatalogText(
                            '${p.name} ${p.code} ${p.brand.name}',
                          ).contains(normalizeCatalogText(value.text)),
                        ),
                        displayStringForOption: (p) =>
                            '${p.name} - ${p.brand.name}',
                        onSelected: _select,
                        fieldViewBuilder:
                            (context, controller, focus, submit) => TextField(
                              controller: controller,
                              focusNode: focus,
                              enabled: !_busy,
                              decoration: const InputDecoration(
                                labelText: 'Buscar producto para editar',
                                prefixIcon: Icon(Icons.search),
                              ),
                            ),
                      ),
                      const SizedBox(height: 24),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final fields = ProductForm(
                            key: ValueKey(_revision),
                            api: _api,
                            brands: _brands,
                            categories: _categories,
                            product: _product ?? _seed,
                            embedded: true,
                            creating: _product == null,
                            extraData: () => {
                              'acordes': _accords
                                  .map((a) => a.toJson())
                                  .toList(),
                            },
                            onSaved: _saved,
                            onSavingChanged: (value) {
                              if (mounted) setState(() => _busy = value);
                            },
                            onDraftChanged: (name, image, brand) =>
                                setState(() {
                                  _name = name;
                                  _image = image;
                                  _dirty = true;
                                  final matches = _brands.where(
                                    (b) => b.id == brand,
                                  );
                                  _brand = matches.isEmpty
                                      ? ''
                                      : matches.first.name;
                                }),
                          );
                          final editor = LayoutBuilder(
                            builder: (context, inner) => inner.maxWidth < 750
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [_accordEditor(), fields],
                                  )
                                : Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(flex: 5, child: _accordEditor()),
                                      const SizedBox(width: 20),
                                      Expanded(flex: 4, child: fields),
                                    ],
                                  ),
                          );
                          if (constraints.maxWidth < 1100) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                editor,
                                const SizedBox(height: 20),
                                _preview(),
                              ],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: editor),
                              const SizedBox(width: 24),
                              SizedBox(width: 240, child: _preview()),
                            ],
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _accordEditor() {
    final usedIds = _accords.map((a) => a.accord.id).toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Acordes aromaticos',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Wrap(
          alignment: WrapAlignment.end,
          children: [
            IconButton(
              tooltip: 'Restablecer acordes',
              onPressed: _busy
                  ? null
                  : () => setState(() {
                      _accords = List.of(_original);
                      _dirty = true;
                    }),
              icon: const Icon(Icons.undo),
            ),
            IconButton(
              tooltip: 'Limpiar acordes',
              onPressed: _busy
                  ? null
                  : () => setState(() {
                      _accords = [];
                      _dirty = true;
                    }),
              icon: const Icon(Icons.clear_all),
            ),
          ],
        ),
        if (_accords.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Sin acordes'),
          ),
        // ── Accord rows: editable name field + bar + × ───────────────────
        for (final item in _accords)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: SizedBox(
              height: 26,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Editable name field with its colour dot. Typing filters
                  // the floating list; picking replaces (keeping intensity).
                  AccordPicker(
                    key: ValueKey('name-${item.accord.id}'),
                    fieldWidth: 100,
                    autofocus: false,
                    initialText: item.accord.name,
                    leadingColorHex: item.accord.colorHex,
                    library: _library,
                    exclude: usedIds.difference({item.accord.id}),
                    onSelected: (next) => _replaceAccord(item.accord.id, next),
                    onCancel: () {},
                  ),
                  const SizedBox(width: 8),
                  // Draggable bar + × reuse AccordBarRow but hide its own name.
                  Expanded(
                    child: AccordBarRow(
                      name: item.accord.name,
                      colorHex: item.accord.colorHex,
                      intensity: item.intensity,
                      editMode: !_busy,
                      showName: false,
                      onIntensityChanged: (value) => setState(() {
                        _accords = updateAccordIntensity(
                          _accords,
                          item.accord.id,
                          value,
                        );
                        _dirty = true;
                      }),
                      onRemove: () => setState(() {
                        _accords = _accords
                            .where((a) => a.accord.id != item.accord.id)
                            .toList();
                        _dirty = true;
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        // ── Add flow: button OR temporary picker ─────────────────────────
        if (_adding)
          AccordPicker(
            library: _library,
            exclude: usedIds,
            onSelected: _addAccordFromLibrary,
            onCancel: () => setState(() => _adding = false),
          )
        else
          Align(
            alignment: Alignment.centerLeft,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                        _adding = true;
                      }),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Añadir acorde'),
              ),
            ),
          ),
      ],
    );
  }

  Widget _preview() {
    final placeholder = const Icon(Icons.local_florist_outlined, size: 64);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff191d20),
        border: Border.all(color: const Color(0xff34383d)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'VISTA PREVIA',
            style: TextStyle(
              color: Color(0xffff7da4),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _name.isEmpty ? 'Nueva fragancia' : _name,
            style: const TextStyle(fontSize: 20),
          ),
          Text(_brand),
          SizedBox(
            height: 230,
            child: _image.startsWith('assets/')
                ? Image.asset(
                    _image,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => placeholder,
                  )
                : _image.isEmpty
                ? placeholder
                : Image.network(
                    _image,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => placeholder,
                  ),
          ),
          for (final item in _accords)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AccordBarRow(
                name: item.accord.name,
                colorHex: item.accord.colorHex,
                intensity: item.intensity,
              ),
            ),
          const SizedBox(height: 12),
          Text(_dirty ? 'Cambios sin guardar' : 'Guardado'),
        ],
      ),
    );
  }
}
