import '../core/utils/parsing_utils.dart';

/// Currently authenticated user, as returned by the API in the `usuario`
/// payload of `POST /auth/login` and `GET /auth/me`.
///
/// The backend serializes the role as a plain string ("Administrador",
/// "Cliente", "Bodeguero", "Vendedor"), so we mirror that here without
/// converting to an enum. The convenience getters `isAdmin`, `isCliente`,
/// `isBodeguero`, `isVendedor` and `isStaff` cover the checks we need at
/// the UI level.
class User {
  const User({
    required this.id,
    required this.email,
    required this.nombres,
    required this.apellidos,
    required this.rol,
    this.activo = true,
  });

  final int id;
  final String email;
  final String nombres;
  final String apellidos;

  /// One of: `Administrador`, `Cliente`, `Bodeguero`, `Vendedor`.
  final String rol;

  final bool activo;

  bool get isAdmin => rol == 'Administrador';
  bool get isCliente => rol == 'Cliente';
  bool get isBodeguero => rol == 'Bodeguero';
  bool get isVendedor => rol == 'Vendedor';

  /// True when the user is anything but a plain customer — used to gate
  /// admin UI (side nav, `/admin/...` routes).
  bool get isStaff => isAdmin || isBodeguero || isVendedor;

  /// Full display name. Falls back to email local-part if names are empty.
  String get displayName {
    final full = '$nombres $apellidos'.trim();
    if (full.isNotEmpty) return full;
    final at = email.indexOf('@');
    return at > 0 ? email.substring(0, at) : email;
  }

  /// 1-2 letter uppercase avatar initials.
  String get initials {
    final first = nombres.trim().isNotEmpty ? nombres.trim()[0] : '';
    final second = apellidos.trim().isNotEmpty ? apellidos.trim()[0] : '';
    final joined = (first + second).toUpperCase();
    if (joined.isNotEmpty) return joined;
    return email.isNotEmpty ? email[0].toUpperCase() : '?';
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: asInt(json['id']),
      email: asString(json['correo']),
      nombres: asString(json['nombres']),
      apellidos: asString(json['apellidos']),
      rol: asString(json['rol']),
      activo: json['activo'] is bool ? json['activo'] as bool : true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'correo': email,
      'nombres': nombres,
      'apellidos': apellidos,
      'rol': rol,
      'activo': activo,
    };
  }

  User copyWith({
    int? id,
    String? email,
    String? nombres,
    String? apellidos,
    String? rol,
    bool? activo,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      nombres: nombres ?? this.nombres,
      apellidos: apellidos ?? this.apellidos,
      rol: rol ?? this.rol,
      activo: activo ?? this.activo,
    );
  }
}
