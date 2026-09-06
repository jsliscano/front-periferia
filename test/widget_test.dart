import 'package:flutter_test/flutter_test.dart';

import 'package:prueba_periferia/app/app.dart';

void main() {
  testWidgets('Login page muestra título, campos y botón de registro',
      (WidgetTester tester) async {
    await tester.pumpWidget(const App());

    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Registrarse'), findsOneWidget);
  });

  testWidgets('Navega a registro y muestra campos', (WidgetTester tester) async {
    await tester.pumpWidget(const App());

    await tester.tap(find.text('Registrarse'));
    await tester.pumpAndSettle();

    expect(find.text('Registrar usuario'), findsOneWidget);
    expect(find.text('Nombre'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}
