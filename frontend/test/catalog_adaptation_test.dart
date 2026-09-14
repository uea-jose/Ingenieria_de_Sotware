import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/catalog_reference.dart';
import 'package:frontend/models/aroma_accord.dart';
import 'package:frontend/models/accord_profile.dart';
import 'package:frontend/models/brand.dart';
import 'package:frontend/models/product.dart';
import 'package:frontend/data/api/catalog_admin_api.dart';
import 'package:frontend/features/admin/accord_editor/accord_editor_page.dart';
import 'package:frontend/screens/perfumery_catalog/perfumery_catalog_page.dart';
import 'package:frontend/widgets/product/aromatic_preview.dart';

const sweet = AromaAccord(
  id: 11,
  name: 'Dulce',
  slug: 'dulce',
  colorHex: '#FF3333',
  textColorHex: '#FFFFFF',
  aliases: [],
);
const woody = AromaAccord(
  id: 22,
  name: 'Amaderado',
  slug: 'amaderado',
  colorHex: '#995533',
  textColorHex: '#FFFFFF',
  aliases: [],
);

class FakeApi extends CatalogAdminApi {
  final product = Product.fromJson({
    'id': 1,
    'nombre': 'Mi perfume',
    'marca': {'id': 1, 'nombre': 'Mi casa'},
  });
  List<EditableAccord>? saved;
  @override
  Future<void> login({required String email, required String password}) async {}
  @override
  Future<List<Product>> loadProducts() async => [product];
  @override
  Future<List<Brand>> loadBrands() async => [];
  @override
  Future<List<AromaAccord>> loadAccords() async => [sweet, woody];
  @override
  Future<AccordProfile> loadProductProfile(
    int productId,
  ) async => AccordProfile(
    accords:
        saved ??
        [const EditableAccord(accord: sweet, intensity: 65, displayOrder: 1)],
    entityId: 1,
    entityName: 'Mi perfume',
    imageUrl: '',
    referenceId: null,
  );
  @override
  Future<AccordProfile> saveProductProfile({
    required int productId,
    required List<EditableAccord> accords,
  }) async {
    saved = List.of(accords);
    return loadProductProfile(productId);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Catalog export keeps pending profiles separate and resolves server IDs',
    () async {
      final refs = await CatalogReference.load();
      expect(refs.length, 634);
      expect(refs.where((r) => r.approved).length, 30);
      final pending = refs.firstWhere((r) => !r.approved);
      expect(pending.resolveProfile, isNotNull);
      expect(() => pending.resolveProfile([sweet]), throwsFormatException);
      final approved = refs.firstWhere((r) => r.approved);
      expect(() => approved.resolveProfile([sweet]), throwsFormatException);
      final master = [
        for (var i = 0; i < approved.accords.length; i++)
          AromaAccord(
            id: i + 100,
            name: approved.accords[i].name,
            slug: approved.accords[i].slug,
            colorHex: '#123456',
            textColorHex: '#FFFFFF',
            aliases: [],
          ),
      ];
      final resolved = approved.resolveProfile(master);
      expect(resolved.first.accord.id, 100);
      expect(resolved.first.accord.colorHex, '#123456');
      expect(resolved.length, approved.accords.length);
      expect(
        refs.any((r) => r.matches('citRICO', '', '')),
        refs.any(
          (r) => normalizeCatalogText(
            '${r.name} ${r.brand} ${r.alias} ${r.brandAliases.join(' ')}',
          ).contains('citrico'),
        ),
      );
      expect(normalizeCatalogText('Cítrico Ámbar'), 'citrico ambar');
    },
  );

  for (final width in [320.0, 390.0, 1024.0, 1440.0]) {
    testWidgets('Editor layout and shared preview at $width', (tester) async {
      tester.view.physicalSize = Size(width, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = FakeApi();
      await tester.pumpWidget(MaterialApp(home: AccordEditorPage(api: api)));
      await tester.tap(find.text('Ingresar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<Product>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mi perfume').last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(AromaticPreview), findsOneWidget);
      expect(
        tester
            .widget<AromaticPreview>(find.byType(AromaticPreview))
            .accords
            .single
            .intensity,
        65,
      );
      expect(find.textContaining('1–100'), findsNothing);
      if (width == 1440) {
        final preview = tester.getRect(find.byType(AromaticPreview));
        final bars = tester.getRect(
          find.byKey(const ValueKey('accord-current-profile')),
        );
        expect(preview.right, lessThan(bars.left));
        await tester.ensureVisible(find.byKey(const ValueKey('library-22')));
        await tester.tap(find.byKey(const ValueKey('library-22')));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<AromaticPreview>(find.byType(AromaticPreview))
              .accords
              .length,
          2,
        );
        await tester.ensureVisible(find.text('Deshacer cambios'));
        await tester.tap(find.text('Deshacer cambios'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<AromaticPreview>(find.byType(AromaticPreview))
              .accords
              .length,
          1,
        );
        expect(api.saved, isNull);
        await tester.ensureVisible(find.byKey(const ValueKey('library-22')));
        await tester.tap(find.byKey(const ValueKey('library-22')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Guardar perfil'));
        await tester.tap(find.text('Guardar perfil'));
        await tester.pumpAndSettle();
        expect(api.saved!.map((item) => item.accord.id), [11, 22]);
        expect(
          tester.widget<AromaticPreview>(find.byType(AromaticPreview)).caption,
          isNull,
        );
      }
    });
  }

  testWidgets('Catalog search by alias and responsive cards', (tester) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final references = (await tester.runAsync(CatalogReference.load))!;
    await tester.pumpWidget(
      MaterialApp(
        home: PerfumeryCatalogPage(references: Future.value(references)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'VICARO');
    await tester.pumpAndSettle();
    expect(find.text('212 VIP Men'), findsOneWidget);
    expect(find.text('Mi perfume'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
