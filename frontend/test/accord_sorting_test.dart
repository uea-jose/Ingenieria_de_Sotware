import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/admin/accord_editor/accord_sorting.dart';
import 'package:frontend/models/aroma_accord.dart';

EditableAccord item(int id, int intensity, int order) {
  return EditableAccord(
    accord: AromaAccord(
      id: id,
      name: 'Acorde $id',
      slug: 'acorde-$id',
      colorHex: '#112233',
      textColorHex: '#FFFFFF',
      aliases: const [],
    ),
    intensity: intensity,
    displayOrder: order,
  );
}

void main() {
  test('ordena por intensidad y conserva empates de forma estable', () {
    final result = normalizeAccordOrder([
      item(1, 60, 1),
      item(2, 90, 2),
      item(3, 60, 3),
    ]);

    expect(result.map((value) => value.accord.id), [2, 1, 3]);
    expect(result.map((value) => value.displayOrder), [1, 2, 3]);
  });

  test('al modificar una barra recalcula el orden consecutivo', () {
    final result = updateAccordIntensity(
      [item(1, 100, 1), item(2, 80, 2), item(3, 60, 3)],
      3,
      90,
    );

    expect(result.map((value) => value.accord.id), [1, 3, 2]);
    expect(result.map((value) => value.intensity), [100, 90, 80]);
    expect(result.map((value) => value.displayOrder), [1, 2, 3]);
  });
}
