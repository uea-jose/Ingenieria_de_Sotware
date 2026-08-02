import '../core/utils/parsing_utils.dart';

class PerfumeReference {
  const PerfumeReference({
    required this.id,
    required this.name,
    required this.slug,
    required this.gender,
    required this.segment,
    required this.catalogAlias,
    required this.profileVersion,
  });

  final int id;
  final String name;
  final String slug;
  final String gender;
  final String segment;
  final String catalogAlias;
  final int profileVersion;

  factory PerfumeReference.fromJson(Map<String, dynamic> json) {
    return PerfumeReference(
      id: asInt(json['id']),
      name: asString(json['nombre']),
      slug: asString(json['slug']),
      gender: asString(json['genero']),
      segment: asString(json['segmento']),
      catalogAlias: asString(json['aliasCatalogo']),
      profileVersion: asInt(json['versionPerfil']),
    );
  }
}
