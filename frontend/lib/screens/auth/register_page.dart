import 'package:flutter/material.dart';

import '../../app/app_design_tokens.dart';
import '../../state/auth_scope.dart';

/// Public route: `/registro`.
///
/// Renders a customer registration form connected to
/// [AuthController.register]. Only 4 fields are required (nombres,
/// apellidos, correo, contraseña ≥ 8 chars) — the backend accepts the
/// others as optional.
///
/// On success the [AuthService] transparently chains a login call so the
/// user lands already authenticated; we push them to the requested
/// `returnTo` route (or `/`) and clear the navigation stack.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _nombresController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _cedulaController = TextEditingController();
  final _direccionController = TextEditingController();
  final _ciudadController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidosController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _telefonoController.dispose();
    _cedulaController.dispose();
    _direccionController.dispose();
    _ciudadController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final controller = AuthScope.read(context);
    if (controller.isBusy) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final ok = await controller.register(
      nombres: _nombresController.text,
      apellidos: _apellidosController.text,
      email: _emailController.text,
      password: _passwordController.text,
      telefono: _telefonoController.text,
      cedula: _cedulaController.text,
      direccion: _direccionController.text,
      ciudad: _ciudadController.text,
    );

    if (!mounted) return;
    if (ok) {
      final returnTo = ModalRoute.of(context)?.settings.arguments;
      Navigator.of(context).pushNamedAndRemoveUntil(
        returnTo is String && returnTo.isNotEmpty && returnTo != '/registro'
            ? returnTo
            : '/',
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Bienvenido a Aromas Store, ${_nombresController.text.trim()}!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _clearErrorIfAny(_) {
    AuthScope.read(context).clearError();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AuthScope.of(context);
    final error = controller.lastError;
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final compact = viewportWidth < 600;

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        backgroundColor: AppColors.bgPage,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/', (route) => false);
            }
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: AppLayout.horizontalPadding(viewportWidth),
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Card(
              elevation: 0,
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.card),
                side: const BorderSide(color: AppColors.borderSoft),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Crear cuenta',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Regístrate para comprar, ver tus pedidos y guardar tus favoritos.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Two-column layout on wider screens.
                      _TwoCol(
                        compact: compact,
                        left: TextFormField(
                          controller: _nombresController,
                          textInputAction: TextInputAction.next,
                          onChanged: _clearErrorIfAny,
                          decoration: const InputDecoration(
                            labelText: 'Nombres *',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Escribe tus nombres.'
                                  : null,
                        ),
                        right: TextFormField(
                          controller: _apellidosController,
                          textInputAction: TextInputAction.next,
                          onChanged: _clearErrorIfAny,
                          decoration: const InputDecoration(
                            labelText: 'Apellidos *',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Escribe tus apellidos.'
                                  : null,
                        ),
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.newUsername],
                        textInputAction: TextInputAction.next,
                        onChanged: _clearErrorIfAny,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico *',
                          prefixIcon: Icon(Icons.mail_outline),
                        ),
                        validator: (value) {
                          final v = value?.trim() ?? '';
                          if (v.isEmpty) return 'Escribe tu correo.';
                          if (!v.contains('@') || !v.contains('.')) {
                            return 'Formato de correo no válido.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        autofillHints: const [AutofillHints.newPassword],
                        textInputAction: TextInputAction.next,
                        onChanged: _clearErrorIfAny,
                        decoration: InputDecoration(
                          labelText: 'Contraseña *',
                          helperText: 'Mínimo 8 caracteres.',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? 'Mostrar contraseña'
                                : 'Ocultar contraseña',
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        validator: (value) {
                          final v = value ?? '';
                          if (v.isEmpty) return 'Escribe una contraseña.';
                          if (v.length < 8) {
                            return 'Debe tener al menos 8 caracteres.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 22),

                      const _SectionLabel('Datos opcionales'),
                      const SizedBox(height: 12),

                      _TwoCol(
                        compact: compact,
                        left: TextFormField(
                          controller: _telefonoController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          onChanged: _clearErrorIfAny,
                          decoration: const InputDecoration(
                            labelText: 'Teléfono',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                        ),
                        right: TextFormField(
                          controller: _cedulaController,
                          textInputAction: TextInputAction.next,
                          onChanged: _clearErrorIfAny,
                          decoration: const InputDecoration(
                            labelText: 'Cédula / DNI',
                            prefixIcon: Icon(Icons.credit_card_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _TwoCol(
                        compact: compact,
                        left: TextFormField(
                          controller: _direccionController,
                          textInputAction: TextInputAction.next,
                          onChanged: _clearErrorIfAny,
                          decoration: const InputDecoration(
                            labelText: 'Dirección',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                        ),
                        right: TextFormField(
                          controller: _ciudadController,
                          textInputAction: TextInputAction.done,
                          onChanged: _clearErrorIfAny,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: const InputDecoration(
                            labelText: 'Ciudad',
                            prefixIcon: Icon(Icons.location_city_outlined),
                          ),
                        ),
                      ),

                      if (error != null) ...[
                        const SizedBox(height: 16),
                        _ErrorBanner(message: error.message),
                      ],

                      const SizedBox(height: 22),
                      FilledButton.icon(
                        onPressed: controller.isBusy ? null : _submit,
                        icon: controller.isBusy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.person_add_alt),
                        label: Text(
                          controller.isBusy ? 'Creando cuenta...' : 'Crear cuenta',
                        ),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text('¿Ya tienes cuenta?  '),
                            TextButton(
                              onPressed: controller.isBusy
                                  ? null
                                  : () => Navigator.of(context).pushReplacementNamed(
                                      '/login',
                                      arguments: ModalRoute.of(
                                        context,
                                      )?.settings.arguments,
                                    ),
                              child: const Text('Iniciar sesión'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
        fontSize: 12,
      ),
    );
  }
}

/// Two-column row that collapses to a single column below 600 px, so the
/// registration form stays comfortable on mobile.
class _TwoCol extends StatelessWidget {
  const _TwoCol({
    required this.left,
    required this.right,
    required this.compact,
  });

  final Widget left;
  final Widget right;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Column(
        children: [left, const SizedBox(height: 14), right],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 14),
        Expanded(child: right),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.errorSoft,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
