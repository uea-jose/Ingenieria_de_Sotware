import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/admin/accord_editor/catalog_admin_page.dart';
import 'package:frontend/models/brand.dart';
import 'package:frontend/models/category.dart';
import 'package:frontend/models/product.dart';
import 'catalog_adaptation_test.dart' show FakeApi;

class AdminApi extends FakeApi {
  Map<String, dynamic>? payload;
  int? target;
  @override
  Future<List<Category>> loadCategories() async => [Category.fromJson({'id': 2, 'nombre': 'Perfumes'})];
  @override
  Future<List<Brand>> loadBrands() async => [Brand.fromJson({'id': 1, 'nombre': 'Casa'})];
  @override
  Future<List<Product>> loadProducts() async => [Product.fromJson({
    'id': 1, 'nombre': 'Perfume editable', 'codigo': 'P1', 'precio': 20,
    'marcaId': 1, 'categoriaId': 2, 'marca': {'nombre': 'Casa'},
  })];
  @override
  Future<Product> saveProduct(Map<String, dynamic> data, {int? id}) async {
    payload = data; target = id;
    return Product.fromJson({'id': id ?? 5, ...data});
  }
}

void main() {
  for (final width in [390.0, 1440.0]) {
    testWidgets('Integrated editor saves commercial data and accords at $width', (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = AdminApi();
      await tester.pumpWidget(MaterialApp(home: CatalogAdminPage(api: api)));
      await tester.tap(find.text('Ingresar'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final search = find.widgetWithText(TextField, 'Buscar producto para editar');
      await tester.enterText(search, 'Perfume editable');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Perfume editable - Casa').last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final save = find.text('Guardar producto');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(api.target, 1);
      expect(api.payload?['precio'], 20);
      expect((api.payload?['acordes'] as List).single['intensidad'], 65);
      expect(find.text('Perfume y acordes guardados.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
