// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/main.dart';

void main() {
  testWidgets('App displays loading state', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoadingView()));

    // The app starts with a skeleton layout while it loads API data.
    expect(find.byType(TopNavigationSkeleton), findsOneWidget);
    expect(find.text('Catalogo publico'), findsNothing);
  });
}
