import 'package:flutter/material.dart';

import '../features/admin/accord_editor/catalog_admin_page.dart';
import '../screens/accord_search/accord_search_page.dart';
import '../screens/home/home_page.dart';
import 'app_theme.dart';
import '../screens/perfumery_catalog/perfumery_catalog_page.dart';

class AromasStoreApp extends StatelessWidget {
  const AromasStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aromas Store',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const HomePage(),
      routes: {
        '/catalogo-perfumeria': (context) => const PerfumeryCatalogPage(),
        '/admin/acordes': (context) => const CatalogAdminPage(),
        '/admin/catalogo': (context) => const CatalogAdminPage(),
        '/acordes': (context) => const AccordSearchPage(),
      },
    );
  }
}

class MyApp extends AromasStoreApp {
  const MyApp({super.key});
}
