import 'dart:convert';

import '../../models/user.dart';
// Conditional import: on Flutter Web we resolve `dart:html`'s
// localStorage; on any other target (including the Flutter test VM) we
// fall back to the in-memory stub. Neither branch imports `dart:html`
// unconditionally, which keeps `flutter test` compilable.
import 'auth_storage_stub.dart'
    if (dart.library.html) 'auth_storage_web.dart'
    as backend;

/// Persists the current authenticated session so the user stays logged in
/// across page reloads (or, on non-web targets, within the current process).
///
/// The API keeps two keys in sync — the raw JWT and the last-known user
/// JSON — so the UI can render the header/drawer immediately after boot
/// without waiting for a `GET /auth/me` round-trip. On any parsing failure
/// both keys are cleared to keep the two blobs consistent.
class AuthStorage {
  static String? loadToken() {
    final raw = backend.readToken();
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  static User? loadUser() {
    final raw = backend.readUserJson();
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return User.fromJson(decoded);
      if (decoded is Map) {
        return User.fromJson(decoded.cast<String, dynamic>());
      }
      return null;
    } catch (_) {
      clear();
      return null;
    }
  }

  static void save({required String token, required User user}) {
    if (token.isEmpty) {
      clear();
      return;
    }
    backend.writeBoth(token: token, userJson: jsonEncode(user.toJson()));
  }

  static void saveUser(User user) {
    backend.writeUserJson(jsonEncode(user.toJson()));
  }

  static void clear() {
    backend.clearAll();
  }
}
