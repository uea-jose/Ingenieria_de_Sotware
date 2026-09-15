import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_design_tokens.dart';
import '../../state/auth_scope.dart';

/// Right-anchored slide-in drawer with the account panel.
///
/// Content is reactive to [AuthController]:
/// - Not signed in → inline login form connected to the real API + link
///   to the full registration page (`/registro`) and the standalone
///   login page (`/login`).
/// - Signed in → identity summary + shortcuts to `/cuenta`, admin
///   (if the user has staff role), and logout.
Future<void> showAccountDrawer(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar panel de cuenta',
    barrierColor: Colors.black.withValues(alpha: 0.48),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      // The drawer needs the AuthScope from the calling context, which is
      // outside the modal route. We wrap the panel in a Builder that reads
      // from `dialogContext` — the InheritedNotifier is inherited from the
      // Navigator, so both contexts see the same scope.
      return const _AccountDrawerRoute();
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      );
    },
  );
}

class _AccountDrawerRoute extends StatelessWidget {
  const _AccountDrawerRoute();

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      child: Actions(
        actions: {
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              Navigator.of(context).maybePop();
              return null;
            },
          ),
        },
        child: const Align(
          alignment: Alignment.centerRight,
          child: _AccountDrawerPanel(),
        ),
      ),
    );
  }
}

class _AccountDrawerPanel extends StatelessWidget {
  const _AccountDrawerPanel();

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final drawerWidth = width < 560 ? width : width.clamp(420.0, 520.0);

    return Material(
      color: AppColors.surface,
      child: SafeArea(
        left: false,
        child: SizedBox(
          width: drawerWidth,
          height: double.infinity,
          child: FocusTraversalGroup(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 22, 28, 28),
              child: auth.isAuthenticated
                  ? const _AuthenticatedView()
                  : const _LoginForm(),
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Not signed in — inline login form
// ────────────────────────────────────────────────────────────────

class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
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
    final auth = AuthScope.read(context);
    if (auth.isBusy) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final ok = await auth.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).maybePop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bienvenido, ${auth.currentUser?.displayName ?? ''}.'),
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
    final auth = AuthScope.of(context);
    final error = auth.lastError;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Accede a tu cuenta',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Cerrar panel de cuenta',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Ingresa para revisar compras, guardar favoritos y continuar tu experiencia en Aromas Store.',
            style: TextStyle(color: AppColors.textSecondary, height: 1.35),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.next,
            onChanged: _clearErrorIfAny,
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
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            onChanged: _clearErrorIfAny,
            onFieldSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                tooltip: _obscurePassword
                    ? 'Mostrar contraseña'
                    : 'Ocultar contraseña',
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
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
            const SizedBox(height: 14),
            _ErrorBanner(message: error.message),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _showPendingMessage(
                context,
                'La recuperación de contraseña se habilitará en una siguiente etapa.',
              ),
              child: const Text('Olvidé mi contraseña'),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: auth.isBusy ? null : _submit,
              icon: auth.isBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.login),
              label: Text(auth.isBusy ? 'Ingresando...' : 'Iniciar sesión'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: auth.isBusy
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed('/registro');
                    },
              child: const Text('Crear cuenta'),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Signed in — identity summary + shortcuts
// ────────────────────────────────────────────────────────────────

class _AuthenticatedView extends StatelessWidget {
  const _AuthenticatedView();

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final user = auth.currentUser!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Tu cuenta',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Cerrar panel de cuenta',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary,
              child: Text(
                user.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bgSoftPink,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      user.rol,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _MenuTile(
          icon: Icons.person_outline,
          title: 'Ver mi cuenta',
          onTap: () {
            Navigator.of(context).pop();
            Navigator.of(context).pushNamed('/cuenta');
          },
        ),
        _MenuTile(
          icon: Icons.receipt_long_outlined,
          title: 'Mis pedidos',
          onTap: () {
            Navigator.of(context).pop();
            Navigator.of(context).pushNamed('/mis-pedidos');
          },
        ),
        _MenuTile(
          icon: Icons.favorite_border,
          title: 'Favoritos',
          onTap: () => _showPendingMessage(
            context,
            'La sección de favoritos se habilitará en una siguiente etapa.',
          ),
        ),
        if (user.isStaff)
          _MenuTile(
            icon: Icons.admin_panel_settings_outlined,
            title: 'Panel administración',
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/admin/acordes');
            },
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              await auth.logout();
              if (!context.mounted) return;
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sesión cerrada.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              minimumSize: const Size.fromHeight(46),
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.textPrimary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
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

void _showPendingMessage(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
  );
}
