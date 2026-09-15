import 'package:flutter/material.dart';

import '../../app/app_design_tokens.dart';
import '../../state/auth_scope.dart';

/// Public route: `/login`.
///
/// Renders a centred, mobile-friendly login form connected to
/// [AuthController.login]. On success the user is sent back to whichever
/// route they were trying to reach (`ModalRoute.settings.arguments` if it
/// was set by [RequireAuth]), or to `/` if there is no return route.
///
/// On failure we surface `controller.lastError.message` inline instead of
/// using a snackbar — the error stays visible until the user edits either
/// field.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final controller = AuthScope.read(context);
    if (controller.isBusy) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final ok = await controller.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;
    if (ok) {
      final returnTo = ModalRoute.of(context)?.settings.arguments;
      Navigator.of(context).pushNamedAndRemoveUntil(
        returnTo is String && returnTo.isNotEmpty && returnTo != '/login'
            ? returnTo
            : '/',
        (route) => false,
      );
    }
  }

  void _clearErrorIfAny(_) {
    final controller = AuthScope.read(context);
    controller.clearError();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AuthScope.of(context);
    final error = controller.lastError;
    final viewportWidth = MediaQuery.sizeOf(context).width;

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
            constraints: const BoxConstraints(maxWidth: 460),
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
                        'Iniciar sesión',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Accede a tu cuenta para revisar compras, guardar favoritos y continuar tu experiencia en Aromas Store.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        onChanged: _clearErrorIfAny,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
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
                        autofillHints: const [AutofillHints.password],
                        onChanged: _clearErrorIfAny,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
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
                          if (value == null || value.isEmpty) {
                            return 'Escribe tu contraseña.';
                          }
                          return null;
                        },
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
                            : const Icon(Icons.login),
                        label: Text(
                          controller.isBusy
                              ? 'Ingresando...'
                              : 'Iniciar sesión',
                        ),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        runAlignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          TextButton(
                            onPressed: () =>
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'La recuperación de contraseña se habilitará en una siguiente etapa.',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                ),
                            child: const Text('Olvidé mi contraseña'),
                          ),
                          TextButton(
                            onPressed: controller.isBusy
                                ? null
                                : () => Navigator.of(context).pushNamed(
                                    '/registro',
                                    arguments: ModalRoute.of(
                                      context,
                                    )?.settings.arguments,
                                  ),
                            child: const Text('Crear cuenta'),
                          ),
                        ],
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
