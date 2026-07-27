import 'package:flutter/material.dart';

import '../screens/home/home_page.dart';
import '../features/admin/accord_editor/accord_editor_page.dart';
import 'app_theme.dart';

class AromasStoreApp extends StatelessWidget {
  const AromasStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aromas Store',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const HomePage(),
      routes: {'/admin/acordes': (context) => const AccordEditorPage()},
    );
  }
}

class MyApp extends AromasStoreApp {
  const MyApp({super.key});
}
