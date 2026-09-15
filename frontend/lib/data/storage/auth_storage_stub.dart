// In-memory backend for AuthStorage used on non-web platforms (and the
// Flutter test VM). Keeps token + user in module-level statics; suitable
// for unit / widget tests that don't need persistence between test cases.
// Not intended for production use: no encryption, no cross-tab sync, no
// disk persistence.

String? _token;
String? _userJson;

String? readToken() => _token;
String? readUserJson() => _userJson;

void writeBoth({required String token, required String userJson}) {
  _token = token;
  _userJson = userJson;
}

void writeUserJson(String userJson) {
  _userJson = userJson;
}

void clearAll() {
  _token = null;
  _userJson = null;
}
