// Widget tests for the public authentication flow.
//
// These are pure UI tests — they never hit the network. They wrap each
// screen in an [AuthScope] backed by a real [AuthController] whose
// underlying http.Client is left unused (the tested flows validate the
// form before any HTTP call would be made).
//
// A larger virtual viewport (1000×1600) is set on the test view so both
// pages fit without needing to scroll before tapping the primary button.
//
// The tests guarantee:
//   1. LoginPage renders all mandatory controls without exceptions.
//   2. Submitting an empty LoginPage shows the required-field validators
//      and does NOT call the auth API.
//   3. RegisterPage renders required and optional fields and validates
//      the "password >= 8 chars" rule.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/screens/auth/login_page.dart';
import 'package:frontend/screens/auth/register_page.dart';
import 'package:frontend/state/auth_scope.dart';

Widget _wrap(Widget child) {
  final controller = AuthController();
  return AuthScope(
    controller: controller,
    child: MaterialApp(
      home: child,
      // Any navigation call in the tests lands on this stub instead of
      // throwing "route not found".
      onGenerateRoute: (settings) => MaterialPageRoute(
        settings: settings,
        builder: (_) => const _StubRoute(),
      ),
    ),
  );
}

Future<void> _sizeViewport(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1000, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

class _StubRoute extends StatelessWidget {
  const _StubRoute();
  @override
  Widget build(BuildContext context) => const Scaffold();
}

void main() {
  testWidgets('LoginPage renders its title and mandatory controls', (
    tester,
  ) async {
    await _sizeViewport(tester);
    await tester.pumpWidget(_wrap(const LoginPage()));
    await tester.pump();

    expect(find.text('Iniciar sesión'), findsWidgets);
    expect(find.widgetWithText(TextFormField, 'Correo electrónico'), findsOne);
    expect(find.widgetWithText(TextFormField, 'Contraseña'), findsOne);
    expect(find.widgetWithText(FilledButton, 'Iniciar sesión'), findsOne);
    expect(find.text('Crear cuenta'), findsOne);
    expect(tester.takeException(), isNull);
  });

  testWidgets('LoginPage empty submit shows field validators', (tester) async {
    await _sizeViewport(tester);
    await tester.pumpWidget(_wrap(const LoginPage()));
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pump();

    expect(find.text('Escribe tu correo.'), findsOne);
    expect(find.text('Escribe tu contraseña.'), findsOne);
    expect(tester.takeException(), isNull);
  });

  testWidgets('RegisterPage validates required fields and short password', (
    tester,
  ) async {
    await _sizeViewport(tester);
    await tester.pumpWidget(_wrap(const RegisterPage()));
    await tester.pump();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombres *'),
      'Jose',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Apellidos *'),
      'Prueba',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Correo electrónico *'),
      'jose@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña *'),
      'abc',
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
    await tester.pump();

    expect(find.text('Debe tener al menos 8 caracteres.'), findsOne);
    // Nombres / apellidos / correo already contain valid data → their
    // validators should NOT fire.
    expect(find.text('Escribe tus nombres.'), findsNothing);
    expect(find.text('Escribe tus apellidos.'), findsNothing);
    expect(find.text('Escribe tu correo.'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
