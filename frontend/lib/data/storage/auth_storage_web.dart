// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

import '../../config/storage_keys.dart';

/// Web backend for [AuthStorage] — persists in `window.localStorage`.
///
/// Kept behind a conditional import so the file is only pulled in when
/// `dart:html` is available (i.e. Flutter Web). On other targets the
/// in-memory stub is used instead.

String? readToken() {
  final raw = html.window.localStorage[authTokenStorageKey];
  return (raw == null || raw.isEmpty) ? null : raw;
}

String? readUserJson() {
  final raw = html.window.localStorage[authUserStorageKey];
  return (raw == null || raw.isEmpty) ? null : raw;
}

void writeBoth({required String token, required String userJson}) {
  html.window.localStorage[authTokenStorageKey] = token;
  html.window.localStorage[authUserStorageKey] = userJson;
}

void writeUserJson(String userJson) {
  html.window.localStorage[authUserStorageKey] = userJson;
}

void clearAll() {
  html.window.localStorage.remove(authTokenStorageKey);
  html.window.localStorage.remove(authUserStorageKey);
}
