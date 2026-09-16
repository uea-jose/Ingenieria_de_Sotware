import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_design_tokens.dart';
import '../../core/validators.dart';
import '../../state/auth_scope.dart';
import '../../widgets/feedback/app_feedback.dart';
import '../../widgets/feedback/feedback_banner.dart';
import '../../widgets/forms/password_strength_meter.dart';

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
  final _confirmController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _cedulaController = TextEditingController();
  final _direccionController = TextEditingController();
  final _ciudadController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    // The strength meter and the confirmation validator depend on the
    // current password text, so we rebuild on every keystroke.
    _passwordController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _nombresController.dispose();
    _apellidosController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _telefonoController.dispose();
    _cedulaController.dispose();
    _direccionController.dispose();
    _ciudadController.dispose();
    super.dispose();
  }

  void _onPasswordChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    final controller = AuthScope.read(context);
    if (controller.isBusy) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Store the phone in the canonical Ecuadorian shape (`09XXXXXXXX`)
    // regardless of how the user typed it (`+593 9...`, `09 ...`, etc.).
    final telefonoNormalizado = normalizePhoneEcuador(_telefonoController.text);

    final ok = await controller.register(
      nombres: _nombresController.text,
      apellidos: _apellidosController.text,
      email: _emailController.text,
      password: _passwordController.text,
      telefono: telefonoNormalizado ?? _telefonoController.text,
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
      AppFeedback.success(
        context,
        '¡Bienvenido a Aromas Store, ${_nombresController.text.trim()}!',
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
                              Validators.required(v, field: 'Nombres'),
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
                              Validators.required(v, field: 'Apellidos'),
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
                        validator: Validators.email,
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
                          helperText:
                              'Mínimo 8 caracteres con mayúscula, número y símbolo.',
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
                        validator: Validators.password,
                      ),
                      // Live checklist — cada regla queda ✓ mientras el
                      // usuario escribe, sin depender de tocar "Crear cuenta".
                      const SizedBox(height: 8),
                      PasswordStrengthMeter(password: _passwordController.text),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _confirmController,
                        obscureText: _obscureConfirm,
                        autofillHints: const [AutofillHints.newPassword],
                        textInputAction: TextInputAction.next,
                        onChanged: _clearErrorIfAny,
                        decoration: InputDecoration(
                          labelText: 'Confirmar contraseña *',
                          prefixIcon: const Icon(Icons.lock_reset),
                          suffixIcon: IconButton(
                            tooltip: _obscureConfirm
                                ? 'Mostrar contraseña'
                                : 'Ocultar contraseña',
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                          ),
                        ),
                        validator: (v) => Validators.passwordMatch(
                          v,
                          password: _passwordController.text,
                        ),
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
                          // Only digits + `+` for the international prefix;
                          // spaces / dashes get dropped as the user types.
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[\d+]')),
                            LengthLimitingTextInputFormatter(13),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Teléfono',
                            hintText: '09XXXXXXXX o +5939XXXXXXXX',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          // Optional field: only validate the shape when
                          // the user actually wrote something.
                          validator: (v) => Validators.phoneEcuador(v),
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
                        FeedbackBanner.error(error.message),
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
                          controller.isBusy
                              ? 'Creando cuenta...'
                              : 'Crear cuenta',
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
                                  : () => Navigator.of(context)
                                        .pushReplacementNamed(
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
      return Column(children: [left, const SizedBox(height: 14), right]);
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
