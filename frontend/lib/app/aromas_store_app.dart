import 'package:flutter/material.dart';

import '../screens/home/home_page.dart';
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
    );
  }
}

class MyApp extends AromasStoreApp {
  const MyApp({super.key});
}
