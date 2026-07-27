import '../../../models/aroma_accord.dart';

List<EditableAccord> normalizeAccordOrder(List<EditableAccord> accords) {
  final indexed = accords.indexed.toList()
    ..sort((first, second) {
      final intensityComparison = second.$2.intensity.compareTo(
        first.$2.intensity,
      );
      return intensityComparison != 0
          ? intensityComparison
          : first.$1.compareTo(second.$1);
    });

  return [
    for (var index = 0; index < indexed.length; index++)
      indexed[index].$2.copyWith(displayOrder: index + 1),
  ];
}

List<EditableAccord> updateAccordIntensity(
  List<EditableAccord> accords,
  int accordId,
  int intensity,
) {
  final boundedIntensity = intensity.clamp(1, 100);
  return normalizeAccordOrder([
    for (final item in accords)
      if (item.accord.id == accordId)
        item.copyWith(intensity: boundedIntensity, copiedFromReference: false)
      else
        item,
  ]);
}
