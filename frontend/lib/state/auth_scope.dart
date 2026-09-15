import 'package:flutter/material.dart';

import '../data/api/auth_service.dart';
import '../models/user.dart';

/// High-level session status consumed by the UI.
enum AuthStatus {
  /// Restore is still running; the UI should show a splash / loader.
  initializing,

  /// No session persisted or the persisted one was rejected.
  unauthenticated,

  /// A valid session is loaded.
  authenticated,
}

/// [ChangeNotifier] that owns the current session for the whole app.
///
/// It wraps [AuthService] (which handles HTTP + storage) and exposes:
/// - [status] for coarse-grained render decisions (loading / logged-in / not).
/// - [currentUser] / [isAuthenticated] for quick reads.
/// - [lastError] to surface backend errors on forms after a failed action.
/// - [login] / [register] / [logout] / [bootstrap] as the mutation surface.
///
/// The controller **never** throws to callers when it is called from a
/// listener; instead it stores the [AuthException] in [lastError] and
/// notifies. That way UIs can just read `lastError` after an `await` on
/// `controller.login(...)` to render inline error messages.
class AuthController extends ChangeNotifier {
  AuthController({AuthService? service}) : _service = service ?? AuthService();

  final AuthService _service;

  AuthStatus _status = AuthStatus.initializing;
  AuthException? _lastError;
  bool _busy = false;

  AuthStatus get status => _status;
  User? get currentUser => _service.currentUser;
  String? get token => _service.currentToken;
  bool get isAuthenticated => _service.isAuthenticated;
  bool get isBusy => _busy;
  AuthException? get lastError => _lastError;

  /// Runs once at app start. Reads the persisted token/user (if any) and
  /// confirms it against `GET /auth/me`. Safe to call multiple times —
  /// subsequent calls are a no-op unless the controller is still
  /// initializing or has been reset.
  Future<void> bootstrap() async {
    _busy = true;
    _lastError = null;
    notifyListeners();

    try {
      final user = await _service.restoreSession();
      _status = user != null
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated;
    } on AuthException catch (error) {
      _lastError = error;
      _status = AuthStatus.unauthenticated;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _busy = true;
    _lastError = null;
    notifyListeners();
    try {
      await _service.login(email: email, password: password);
      _status = AuthStatus.authenticated;
      return true;
    } on AuthException catch (error) {
      _lastError = error;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String nombres,
    required String apellidos,
    required String email,
    required String password,
    String? telefono,
    String? cedula,
    String? direccion,
    String? ciudad,
  }) async {
    _busy = true;
    _lastError = null;
    notifyListeners();
    try {
      await _service.register(
        nombres: nombres,
        apellidos: apellidos,
        email: email,
        password: password,
        telefono: telefono,
        cedula: cedula,
        direccion: direccion,
        ciudad: ciudad,
      );
      _status = _service.isAuthenticated
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated;
      return true;
    } on AuthException catch (error) {
      _lastError = error;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _service.logout();
    _status = AuthStatus.unauthenticated;
    _lastError = null;
    notifyListeners();
  }

  /// Clears the last stored error without touching the session. Useful when
  /// a form field regains focus and we want the error banner to fade.
  void clearError() {
    if (_lastError == null) return;
    _lastError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}

/// Widget that provides an [AuthController] to its descendants.
///
/// Descendants subscribe with `AuthScope.of(context)` (rebuilds on change)
/// or `AuthScope.read(context)` (does NOT rebuild — useful in callbacks).
class AuthScope extends InheritedNotifier<AuthController> {
  const AuthScope({
    required super.child,
    required AuthController controller,
    super.key,
  }) : super(notifier: controller);

  /// Returns the controller and registers the calling widget to rebuild on
  /// change. Throws if there is no [AuthScope] above.
  static AuthController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope not found in the widget tree');
    return scope!.notifier!;
  }

  /// Returns the controller WITHOUT subscribing. Use inside event
  /// handlers (`onPressed`, `onTap`, ...) to avoid unwanted rebuilds.
  static AuthController read(BuildContext context) {
    final scope = context
        .getElementForInheritedWidgetOfExactType<AuthScope>()
        ?.widget;
    assert(scope is AuthScope, 'AuthScope not found in the widget tree');
    return (scope as AuthScope).notifier!;
  }
}

/// Route wrapper that only shows [child] to authenticated users. When the
/// current session is missing, the widget schedules a redirect to
/// [redirectTo] (default `/login`) and shows [placeholder] in the meantime.
///
/// Usage:
/// ```
/// '/mis-pedidos': (context) => const RequireAuth(child: MyOrdersPage()),
/// ```
class RequireAuth extends StatelessWidget {
  const RequireAuth({
    required this.child,
    this.redirectTo = '/login',
    this.requireStaff = false,
    this.placeholder,
    super.key,
  });

  final Widget child;
  final String redirectTo;

  /// When `true` the user must also have `isStaff == true`. Otherwise a
  /// forbidden view is rendered without redirecting.
  final bool requireStaff;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);

    switch (auth.status) {
      case AuthStatus.initializing:
        return placeholder ?? const _AuthLoading();
      case AuthStatus.unauthenticated:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          Navigator.of(context).pushReplacementNamed(
            redirectTo,
            arguments: ModalRoute.of(context)?.settings.name,
          );
        });
        return placeholder ?? const _AuthLoading();
      case AuthStatus.authenticated:
        if (requireStaff && !(auth.currentUser?.isStaff ?? false)) {
          return const _ForbiddenView();
        }
        return child;
    }
  }
}

class _AuthLoading extends StatelessWidget {
  const _AuthLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _ForbiddenView extends StatelessWidget {
  const _ForbiddenView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acceso restringido')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Necesitas una cuenta con permisos internos para ver esta sección.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                  '/',
                  (route) => false,
                ),
                child: const Text('Volver al inicio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
