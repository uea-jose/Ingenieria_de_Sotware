import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/api/catalog_admin_api.dart';
import 'package:frontend/features/admin/accord_editor/product_form.dart';
import 'package:frontend/models/brand.dart';
import 'package:frontend/models/category.dart';
import 'package:frontend/models/product.dart';

class RecordingApi extends CatalogAdminApi {
  Map<String, dynamic>? saved;
  int? savedId;
  @override
  Future<Product> saveProduct(Map<String, dynamic> data, {int? id}) async {
    saved = data;
    savedId = id;
    return Product.fromJson({'id': id ?? 42, ...data});
  }
}

void main() {
  for (final width in [390.0, 1000.0]) {
    testWidgets('edits product at width $width without overflow', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = RecordingApi();
      final product = Product.fromJson({
        'id': 5, 'nombre': 'Perfume de prueba', 'codigo': 'TEST',
        'precio': 25, 'marcaId': 1, 'categoriaId': 2,
        'inventario': {'stock': 3},
      });
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: ProductForm(
        api: api, product: product,
        brands: [Brand.fromJson({'id': 1, 'nombre': 'Casa'})],
        categories: [Category.fromJson({'id': 2, 'nombre': 'Perfumes'})],
      ))));
      expect(tester.takeException(), isNull);
      final price = find.widgetWithText(TextFormField, 'Precio');
      await tester.enterText(price, '-1');
      await tester.ensureVisible(find.text('Guardar producto'));
      await tester.tap(find.text('Guardar producto'));
      await tester.pump();
      expect(api.saved, isNull);
      expect(find.text('Ingresa un precio mayor que cero'), findsOneWidget);
      await tester.ensureVisible(price);
      await tester.enterText(price, '35,50');
      await tester.ensureVisible(find.text('Guardar producto'));
      await tester.tap(find.text('Guardar producto'));
      await tester.pumpAndSettle();
      expect(api.savedId, 5);
      expect(api.saved?['precio'], 35.5);
      expect(api.saved?['stock'], 3);
      expect(api.saved?.containsKey('acordes'), false);
      expect(tester.takeException(), isNull);
    });
  }
}
