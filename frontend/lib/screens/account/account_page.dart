import 'package:flutter/material.dart';

import '../../app/app_design_tokens.dart';
import '../../state/auth_scope.dart';

/// Private route: `/cuenta`.
///
/// Should be wrapped by [RequireAuth] in the route table. The page shows
/// the authenticated user's identity plus quick links to future features
/// (pedidos, favoritos, admin). Includes a hard logout button that
/// clears the session and returns to `/`.
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final user = auth.currentUser;
    final viewportWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        backgroundColor: AppColors.bgPage,
        elevation: 0,
        title: const Text(
          'Mi cuenta',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
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
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _IdentityCard(user: user),
                const SizedBox(height: 18),
                _QuickLinks(isStaff: user?.isStaff ?? false),
                const SizedBox(height: 22),
                OutlinedButton.icon(
                  onPressed: auth.isBusy
                      ? null
                      : () async {
                          await auth.logout();
                          if (!context.mounted) return;
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            '/',
                            (route) => false,
                          );
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
                    minimumSize: const Size.fromHeight(46),
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.user});
  final dynamic user;

  @override
  Widget build(BuildContext context) {
    final name = user?.displayName ?? 'Invitado';
    final email = user?.email ?? '';
    final rol = user?.rol ?? '';
    final initials = user?.initials ?? '?';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.primary,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  email,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                if (rol.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _RolePill(rol: rol),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({required this.rol});
  final String rol;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bgSoftPink,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Text(
        rol,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _QuickLinks extends StatelessWidget {
  const _QuickLinks({required this.isStaff});
  final bool isStaff;

  @override
  Widget build(BuildContext context) {
    final tiles = <_LinkTile>[
      _LinkTile(
        icon: Icons.receipt_long_outlined,
        title: 'Mis pedidos',
        subtitle: 'Historial y estado de tus compras',
        onTap: () => _pending(context),
      ),
      _LinkTile(
        icon: Icons.favorite_border,
        title: 'Favoritos',
        subtitle: 'Perfumes que guardaste para después',
        onTap: () => _pending(context),
      ),
      _LinkTile(
        icon: Icons.receipt_outlined,
        title: 'Mis facturas',
        subtitle: 'Descarga facturas de pedidos pagados',
        onTap: () => _pending(context),
      ),
      if (isStaff)
        _LinkTile(
          icon: Icons.admin_panel_settings_outlined,
          title: 'Panel administración',
          subtitle: 'Catálogo, inventario, ventas y más',
          onTap: () => Navigator.of(context).pushNamed('/admin/acordes'),
        ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, color: AppColors.borderSoft),
            tiles[i],
          ],
        ],
      ),
    );
  }

  static void _pending(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Módulo en construcción. Próximamente disponible.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppColors.bgPage,
        foregroundColor: AppColors.primary,
        child: Icon(icon),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
    );
  }
}
