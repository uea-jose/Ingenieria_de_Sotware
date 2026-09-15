import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../models/user.dart';
import '../storage/auth_storage.dart';

/// Domain-level error thrown by [AuthService] for anything the UI needs to
/// react to. Wraps the HTTP status code and a user-facing message that we
/// take from the backend when available, or derive from the status code.
class AuthException implements Exception {
  const AuthException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Thin client for the authentication + client registration endpoints.
///
/// Endpoints used:
/// - `POST /auth/login`         →  {token, usuario}
/// - `GET  /auth/me`  (Bearer)  →  {usuario}
/// - `POST /clientes/registro`  →  {usuario, cliente}
///
/// The service also owns the in-memory copy of the current token / user so
/// the rest of the app can read the session without hitting `AuthStorage`
/// on every rebuild. Persistence is handled transparently: every successful
/// mutation (`login`, `register`, `me`, `logout`) writes through to
/// [AuthStorage] and updates the in-memory state.
class AuthService {
  AuthService({http.Client? client, this.registerAutoLogin = true})
    : _client = client ?? http.Client();

  final http.Client _client;

  /// When `true` (default) [register] chains a `login()` call so the new
  /// account is immediately usable. Tests can pass `false` to isolate the
  /// registration endpoint.
  final bool registerAutoLogin;

  String? _token;
  User? _user;

  String? get currentToken => _token;
  User? get currentUser => _user;
  bool get isAuthenticated => _token != null && _user != null;

  // ────────────────────────────────────────────────────────────────
  // Public API
  // ────────────────────────────────────────────────────────────────

  /// Attempts to restore a previously persisted session:
  /// 1. Reads token + user from [AuthStorage].
  /// 2. Populates the in-memory copy so the UI can render immediately.
  /// 3. Confirms the token is still valid by calling `GET /auth/me`.
  ///    If the server rejects it (401/expired) the local session is cleared.
  ///
  /// Returns the confirmed [User] or `null` if there is no session.
  Future<User?> restoreSession() async {
    final storedToken = AuthStorage.loadToken();
    final storedUser = AuthStorage.loadUser();
    if (storedToken == null || storedUser == null) {
      AuthStorage.clear();
      return null;
    }

    _token = storedToken;
    _user = storedUser;

    try {
      // Validate the token and refresh the user snapshot in one round-trip.
      final refreshed = await me();
      return refreshed;
    } on AuthException catch (error) {
      if (error.statusCode == 401) {
        await logout();
        return null;
      }
      // Network / server error: keep the cached session so the app is usable
      // offline until we can talk to the API again.
      return _user;
    }
  }

  Future<User> login({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    if (cleanEmail.isEmpty || password.isEmpty) {
      throw const AuthException(
        'Ingresa correo y contraseña para continuar.',
        statusCode: 400,
      );
    }

    final json = await _request(
      '/auth/login',
      method: 'POST',
      body: {'correo': cleanEmail, 'contrasena': password},
    );

    final token = json['token']?.toString();
    final usuarioJson = json['usuario'];

    if (token == null || token.isEmpty || usuarioJson is! Map) {
      throw const AuthException(
        'La respuesta del servidor no contiene token válido.',
      );
    }

    final user = User.fromJson(usuarioJson.cast<String, dynamic>());
    _persist(token: token, user: user);
    return user;
  }

  /// Registers a new customer via `POST /clientes/registro` and, if
  /// [registerAutoLogin] is true, immediately logs them in so the returned
  /// [User] already has a live session.
  Future<User> register({
    required String nombres,
    required String apellidos,
    required String email,
    required String password,
    String? telefono,
    String? cedula,
    String? direccion,
    String? ciudad,
  }) async {
    final body = <String, dynamic>{
      'nombres': nombres.trim(),
      'apellidos': apellidos.trim(),
      'correo': email.trim().toLowerCase(),
      'contrasena': password,
      if (telefono != null && telefono.trim().isNotEmpty)
        'telefono': telefono.trim(),
      if (cedula != null && cedula.trim().isNotEmpty) 'cedula': cedula.trim(),
      if (direccion != null && direccion.trim().isNotEmpty)
        'direccion': direccion.trim(),
      if (ciudad != null && ciudad.trim().isNotEmpty) 'ciudad': ciudad.trim(),
    };

    final json = await _request(
      '/clientes/registro',
      method: 'POST',
      body: body,
    );

    final usuarioJson = json['usuario'];
    if (usuarioJson is! Map) {
      throw const AuthException(
        'El servidor no devolvió los datos del nuevo usuario.',
      );
    }
    final user = User.fromJson(usuarioJson.cast<String, dynamic>());

    if (!registerAutoLogin) {
      return user;
    }

    // Backend does not return a token from the registration endpoint, so
    // we chain a login call using the just-created credentials.
    return login(email: email, password: password);
  }

  /// Confirms the current token against the API and refreshes the persisted
  /// user snapshot. Throws [AuthException] with statusCode 401 if the token
  /// is invalid or expired.
  Future<User> me() async {
    if (_token == null) {
      throw const AuthException('No hay sesión activa.', statusCode: 401);
    }

    final json = await _request('/auth/me');
    final usuarioJson = json['usuario'];
    if (usuarioJson is! Map) {
      throw const AuthException('Respuesta de /auth/me malformada.');
    }
    final user = User.fromJson(usuarioJson.cast<String, dynamic>());
    _user = user;
    AuthStorage.saveUser(user);
    return user;
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    AuthStorage.clear();
  }

  /// Frees the underlying HTTP client. Safe to call multiple times.
  void dispose() {
    _client.close();
  }

  // ────────────────────────────────────────────────────────────────
  // Internal helpers
  // ────────────────────────────────────────────────────────────────

  void _persist({required String token, required User user}) {
    _token = token;
    _user = user;
    AuthStorage.save(token: token, user: user);
  }

  Future<Map<String, dynamic>> _request(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$apiBaseUrl$path');
    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (_token != null && _token!.isNotEmpty)
        'Authorization': 'Bearer $_token',
    };

    late http.Response response;
    try {
      switch (method) {
        case 'POST':
          response = await _client.post(
            uri,
            headers: headers,
            body: jsonEncode(body ?? const {}),
          );
        case 'PUT':
          response = await _client.put(
            uri,
            headers: headers,
            body: jsonEncode(body ?? const {}),
          );
        default:
          response = await _client.get(uri, headers: headers);
      }
    } on Object catch (error) {
      throw AuthException(
        'No se pudo contactar el servidor: $error',
        statusCode: 0,
      );
    }

    final decoded = response.body.isEmpty
        ? const <String, dynamic>{}
        : _safeDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(
        _extractErrorMessage(decoded, response.statusCode),
        statusCode: response.statusCode,
      );
    }

    return decoded;
  }

  static Map<String, dynamic> _safeDecode(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return decoded.cast<String, dynamic>();
    } catch (_) {
      // fall through to empty map
    }
    return const {};
  }

  static String _extractErrorMessage(Map<String, dynamic> json, int status) {
    // Aromas API returns `{error: "string"}`. Prisma / express-async errors
    // sometimes include `{error, detalles}`. We try both.
    final err = json['error'];
    if (err is String && err.trim().isNotEmpty) return err.trim();
    if (err is Map) {
      final msg = err['mensaje'] ?? err['message'];
      if (msg != null) return msg.toString();
    }
    switch (status) {
      case 400:
        return 'Los datos enviados no son válidos.';
      case 401:
        return 'Credenciales inválidas o sesión expirada.';
      case 403:
        return 'No tienes permisos para esta acción.';
      case 404:
        return 'Recurso no encontrado.';
      case 409:
        return 'El recurso ya existe.';
      default:
        return 'Error HTTP $status.';
    }
  }
}
