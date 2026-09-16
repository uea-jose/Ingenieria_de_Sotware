import 'package:flutter/material.dart';

import '../features/admin/accord_editor/catalog_admin_page.dart';
import '../features/admin/sales/admin_sales_page.dart';
import '../screens/accord_search/accord_search_page.dart';
import '../screens/account/account_page.dart';
import '../screens/auth/login_page.dart';
import '../screens/auth/register_page.dart';
import '../screens/checkout/checkout_page.dart';
import '../screens/home/home_page.dart';
import '../screens/orders/my_orders_page.dart';
import '../screens/perfumery_catalog/perfumery_catalog_page.dart';
import '../state/auth_scope.dart';
import 'app_theme.dart';

/// Root widget for the Aromas Store storefront + admin app.
///
/// Wraps the entire [MaterialApp] in an [AuthScope] so any screen can
/// consume the current session via `AuthScope.of(context)`. On the very
/// first frame we call `bootstrap()` to restore a persisted session (if
/// any) and confirm the token against `GET /auth/me`.
class AromasStoreApp extends StatefulWidget {
  const AromasStoreApp({super.key});

  @override
  State<AromasStoreApp> createState() => _AromasStoreAppState();
}

class _AromasStoreAppState extends State<AromasStoreApp> {
  late final AuthController _auth;

  @override
  void initState() {
    super.initState();
    _auth = AuthController();
    // Fire-and-forget: the ChangeNotifier will drive rebuilds on completion.
    _auth.bootstrap();
  }

  @override
  void dispose() {
    _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      controller: _auth,
      child: MaterialApp(
        title: 'Aromas Store',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        initialRoute: '/',
        routes: {
          '/': (context) => const HomePage(),
          '/catalogo-perfumeria': (context) => const PerfumeryCatalogPage(),
          '/admin/acordes': (context) =>
              const RequireAuth(requireStaff: true, child: CatalogAdminPage()),
          '/admin/catalogo': (context) =>
              const RequireAuth(requireStaff: true, child: CatalogAdminPage()),
          '/admin/ventas': (context) =>
              const RequireAuth(requireStaff: true, child: AdminSalesPage()),
          '/acordes': (context) => const AccordSearchPage(),
          '/login': (context) => const LoginPage(),
          '/registro': (context) => const RegisterPage(),
          '/cuenta': (context) => const RequireAuth(child: AccountPage()),
          '/checkout': (context) => const RequireAuth(child: CheckoutPage()),
          '/mis-pedidos': (context) => const RequireAuth(child: MyOrdersPage()),
        },
      ),
    );
  }
}

class MyApp extends AromasStoreApp {
  const MyApp({super.key});
}
