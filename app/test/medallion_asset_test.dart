import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpMedallion(
    WidgetTester tester,
    Brightness brightness,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: Scaffold(
          body: Center(
            child: Image.asset('assets/images/taichi.png'),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('medallion asset loads in dark mode', (tester) async {
    await pumpMedallion(tester, Brightness.dark);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('medallion asset loads in light mode', (tester) async {
    await pumpMedallion(tester, Brightness.light);
    expect(find.byType(Image), findsOneWidget);
  });
}
