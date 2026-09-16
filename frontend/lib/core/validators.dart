// Reusable form validators for the entire app.
//
// Each `Validators.*` function follows Flutter's convention for
// `TextFormField.validator`: returns `null` when the value is valid, or a
// user-facing error message when it is not.
//
// The individual checks used by the strong-password validator are
// exposed under [PasswordChecks] so the [PasswordStrengthMeter] widget
// can render live feedback (✓ / ✗ per rule) without duplicating regexes.
//
// The Ecuadorian phone validator accepts three input shapes and treats
// them as equivalent; use [normalizePhoneEcuador] to obtain the canonical
// `09XXXXXXXX` form before persisting.

class Validators {
  const Validators._();

  /// Non-empty (after trimming). Use for names, city, address, etc.
  static String? required(String? value, {String field = 'Este campo'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field es obligatorio.';
    }
    return null;
  }

  /// Simple but robust email check. Matches values with:
  /// - a local part with letters/digits/`._+-`
  /// - a `@` separator
  /// - a domain with at least one dot and a TLD of 2+ characters.
  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Escribe tu correo.';
    final regex = RegExp(r'^[\w.+\-]+@[\w\-]+(\.[\w\-]+)+$');
    if (!regex.hasMatch(v)) return 'Formato de correo no válido.';
    return null;
  }

  /// Strong password composing all four checks from [PasswordChecks].
  /// Returns the first failing rule so the message is specific.
  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Escribe una contraseña.';
    if (!PasswordChecks.hasMinLength(v)) {
      return 'Debe tener al menos 8 caracteres.';
    }
    if (!PasswordChecks.hasUppercase(v)) {
      return 'Debe incluir al menos una letra mayúscula.';
    }
    if (!PasswordChecks.hasDigit(v)) {
      return 'Debe incluir al menos un número.';
    }
    if (!PasswordChecks.hasSpecialChar(v)) {
      return 'Debe incluir un carácter especial (por ejemplo !@#\$%).';
    }
    return null;
  }

  /// Confirmation field: compares against [password]. Empty is a
  /// dedicated error message so the user knows they need to retype.
  static String? passwordMatch(String? confirm, {required String password}) {
    if (confirm == null || confirm.isEmpty) return 'Confirma tu contraseña.';
    if (confirm != password) return 'Las contraseñas no coinciden.';
    return null;
  }

  /// Ecuadorian mobile phone. Accepts:
  /// - `09XXXXXXXX`        — 10 digits starting with `09`
  /// - `+593 9XXXXXXXX`    — international format with or without spaces
  /// - `593 9XXXXXXXX`     — same, without the leading `+`
  ///
  /// Landlines and short codes are intentionally rejected because the
  /// checkout expects a mobile line for delivery contact.
  static String? phoneEcuador(String? value, {bool isRequired = false}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return isRequired ? 'Escribe tu teléfono.' : null;
    final digits = v.replaceAll(RegExp(r'[^\d]'), '');
    final ok =
        RegExp(r'^09\d{8}$').hasMatch(digits) ||
        RegExp(r'^5939\d{8}$').hasMatch(digits);
    if (!ok) {
      return 'Formato esperado: 09XXXXXXXX o +593 9XXXXXXXX.';
    }
    return null;
  }
}

/// Individual password rules — exposed so the UI can render a live checklist.
class PasswordChecks {
  const PasswordChecks._();

  static const int minLength = 8;

  static bool hasMinLength(String p) => p.length >= minLength;
  static bool hasUppercase(String p) => RegExp(r'[A-Z]').hasMatch(p);
  static bool hasDigit(String p) => RegExp(r'\d').hasMatch(p);

  /// Any non-alphanumeric character. Uses a Unicode-aware regex so accented
  /// letters count as letters (not "special"), while punctuation and
  /// symbols do count.
  static bool hasSpecialChar(String p) =>
      RegExp(r'[^A-Za-z0-9À-ÿ]').hasMatch(p);

  /// Convenience — every check must pass. Same rule as [Validators.password]
  /// but without a message; useful when the UI only needs a boolean
  /// (for example to enable a submit button).
  static bool passesAll(String p) =>
      hasMinLength(p) &&
      hasUppercase(p) &&
      hasDigit(p) &&
      hasSpecialChar(p);
}

/// Converts a user-provided Ecuadorian phone into the canonical
/// `09XXXXXXXX` form we send to the backend. Returns `null` when the
/// input can't be normalised — pair it with [Validators.phoneEcuador]
/// so the form catches invalid values before submission.
String? normalizePhoneEcuador(String? raw) {
  if (raw == null) return null;
  final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
  if (digits.length == 12 && digits.startsWith('5939')) {
    return '0${digits.substring(3)}';
  }
  if (digits.length == 10 && digits.startsWith('09')) {
    return digits;
  }
  return null;
}
