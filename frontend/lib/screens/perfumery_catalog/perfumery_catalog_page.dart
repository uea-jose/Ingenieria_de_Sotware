import 'package:flutter/material.dart';
import '../../app/app_design_tokens.dart';
import '../../models/catalog_reference.dart';
import '../../models/aroma_accord.dart';
import '../../widgets/product/aromatic_preview.dart';

class PerfumeryCatalogPage extends StatefulWidget {
  const PerfumeryCatalogPage({
    super.key,
    this.selectReference = false,
    this.references,
  });
  final bool selectReference;
  final Future<List<CatalogReference>>? references;
  @override
  State<PerfumeryCatalogPage> createState() => _PerfumeryCatalogPageState();
}

class _PerfumeryCatalogPageState extends State<PerfumeryCatalogPage> {
  late Future<List<CatalogReference>> _references;
  final _search = TextEditingController();
  final _scroll = ScrollController();
  String _gender = '', _accord = '';
  @override
  void initState() {
    super.initState();
    _references = widget.references ?? CatalogReference.load();
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Catálogo de perfumería')),
    body: FutureBuilder<List<CatalogReference>>(
      future: _references,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: TextButton(
              onPressed: () =>
                  setState(() => _references = CatalogReference.load()),
              child: const Text('No se pudo cargar. Reintentar'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final references = snapshot.data!;
        final matches = references
            .where((r) => r.matches(_search.text, _gender, _accord))
            .toList();
        final accords = <String, String>{
          for (final r in references.where((r) => r.approved))
            for (final a in r.accords) a.slug: a.name,
        };
        final options = accords.entries.toList()
          ..sort((a, b) => a.value.compareTo(b.value));
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final contentWidth = (width - 32).clamp(0.0, 1320.0);
            final columns = contentWidth >= 1100
                ? 4
                : contentWidth >= 760
                ? 3
                : contentWidth >= 520
                ? 2
                : 1;
            return CustomScrollView(
              controller: _scroll,
              slivers: [
                SliverToBoxAdapter(
                  child: Center(
                    child: SizedBox(
                      width: contentWidth,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Descubre tu próximo aroma',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Referencias de perfumería para explorar e inspirarte. La disponibilidad y los precios se consultan en la tienda.',
                            ),
                            const SizedBox(height: 16),
                            Card(
                              margin: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(
                                  color: AppColors.borderSoft,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    TextField(
                                      controller: _search,
                                      onChanged: (_) => setState(() {}),
                                      decoration: const InputDecoration(
                                        labelText:
                                            'Buscar perfume, casa o nombre del catálogo',
                                        prefixIcon: Icon(Icons.search),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      children: [
                                        SizedBox(
                                          width: contentWidth < 520
                                              ? contentWidth - 32
                                              : 200,
                                          child:
                                              DropdownButtonFormField<String>(
                                                key: ValueKey(
                                                  'gender-$_gender',
                                                ),
                                                initialValue: _gender,
                                                isExpanded: true,
                                                decoration:
                                                    const InputDecoration(
                                                      labelText: 'Para quién',
                                                    ),
                                                items: const [
                                                  DropdownMenuItem(
                                                    value: '',
                                                    child: Text('Todos'),
                                                  ),
                                                  DropdownMenuItem(
                                                    value: 'masculine',
                                                    child: Text('Hombre'),
                                                  ),
                                                  DropdownMenuItem(
                                                    value: 'feminine',
                                                    child: Text('Mujer'),
                                                  ),
                                                  DropdownMenuItem(
                                                    value: 'unisex',
                                                    child: Text('Unisex'),
                                                  ),
                                                ],
                                                onChanged: (v) => setState(
                                                  () => _gender = v ?? '',
                                                ),
                                              ),
                                        ),
                                        SizedBox(
                                          width: contentWidth < 520
                                              ? contentWidth - 32
                                              : 240,
                                          child:
                                              DropdownButtonFormField<String>(
                                                key: ValueKey(
                                                  'accord-$_accord',
                                                ),
                                                initialValue: _accord,
                                                isExpanded: true,
                                                menuMaxHeight: 260,
                                                decoration:
                                                    const InputDecoration(
                                                      labelText:
                                                          'Contiene el acorde',
                                                    ),
                                                items: [
                                                  const DropdownMenuItem(
                                                    value: '',
                                                    child: Text(
                                                      'Todos los acordes',
                                                    ),
                                                  ),
                                                  for (final a in options)
                                                    DropdownMenuItem(
                                                      value: a.key,
                                                      child: Text(a.value),
                                                    ),
                                                ],
                                                onChanged: (v) => setState(
                                                  () => _accord = v ?? '',
                                                ),
                                              ),
                                        ),
                                        TextButton.icon(
                                          onPressed: () => setState(() {
                                            _search.clear();
                                            _gender = '';
                                            _accord = '';
                                          }),
                                          icon: const Icon(
                                            Icons.filter_alt_off_outlined,
                                          ),
                                          label: const Text('Limpiar'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              '${matches.length} referencias · ${references.where((r) => r.approved).length} perfiles con acordes revisados',
                            ),
                            if (_accord.isNotEmpty)
                              const Text(
                                'Las referencias con perfil pendiente no aparecen al filtrar por acorde.',
                              ),
                            if (matches.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                  'No hay coincidencias. Prueba otro nombre o limpia los filtros.',
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    (width - contentWidth) / 2,
                    0,
                    (width - contentWidth) / 2,
                    24,
                  ),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final reference = matches[index];
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: AppColors.borderSoft),
                        ),
                        child: InkWell(
                          onTap: () => _openReference(reference),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  reference.genderLabel,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.labelMedium,
                                ),
                                Expanded(
                                  child: Image.asset(
                                    reference.imageAsset,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, _, _) => const Icon(
                                      Icons.local_florist_outlined,
                                    ),
                                  ),
                                ),
                                Text(
                                  reference.brand,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                  ),
                                ),
                                Text(
                                  reference.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                if (reference.alias.isNotEmpty)
                                  Text(
                                    reference.alias,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                const SizedBox(height: 8),
                                Text(
                                  reference.approved
                                      ? reference.accords
                                            .take(3)
                                            .map((a) => a.name)
                                            .join(' · ')
                                      : 'Perfil aromático por revisar',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Ver referencia →',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }, childCount: matches.length),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisExtent: 380,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    ),
  );

  Future<void> _openReference(CatalogReference reference) async {
    final selected = await Navigator.of(context).push<CatalogReference>(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Referencia de perfumería')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AromaticPreview(
                      name: reference.name,
                      brand: reference.brand,
                      imageAsset: reference.imageAsset,
                      title: reference.genderLabel,
                      accords: [
                        for (
                          var i = 0;
                          i < reference.accords.length && reference.approved;
                          i++
                        )
                          EditableAccord(
                            accord: AromaAccord(
                              id: i,
                              name: reference.accords[i].name,
                              slug: reference.accords[i].slug,
                              colorHex: reference.accords[i].color,
                              textColorHex: '#FFFFFF',
                              aliases: const [],
                            ),
                            intensity: reference.accords[i].intensity,
                            displayOrder: i + 1,
                          ),
                      ],
                      caption: reference.alias.isEmpty
                          ? null
                          : 'Nombre en el catálogo: ${reference.alias}',
                    ),
                    const SizedBox(height: 16),
                    if (!reference.approved)
                      const Text(
                        'Esta referencia tiene imagen y datos de origen. Sus acordes todavía necesitan revisión.',
                      ),
                    Text(
                      'Origen: ${reference.source} · página ${reference.page ?? '—'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    if (widget.selectReference)
                      FilledButton.icon(
                        onPressed: () => Navigator.of(context).pop(reference),
                        icon: const Icon(Icons.check),
                        label: const Text('Elegir referencia para el editor'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (selected != null && mounted) Navigator.of(context).pop(selected);
  }
}
