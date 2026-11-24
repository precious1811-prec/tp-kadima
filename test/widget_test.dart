import 'package:cv_flutter_precious/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('connexion puis navigation entre les rubriques', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CvApp());

    expect(find.text('Bienvenue'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(
      tester
          .widget<TextField>(
            find.descendant(
              of: find.byType(TextFormField).last,
              matching: find.byType(TextField),
            ),
          )
          .obscureText,
      isTrue,
    );

    await tester.pumpWidget(const MaterialApp(home: PortfolioShell()));
    expect(find.text('Mon CV'), findsWidgets);
    expect(find.text('Michée KADIMA'), findsOneWidget);
  });
}
