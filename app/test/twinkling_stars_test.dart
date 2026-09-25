import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/widgets/twinkling_stars.dart';

void main() {
  Future<void> pumpStars(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: TwinklingStars())),
    );
  }

  testWidgets('renders a CustomPaint canvas', (tester) async {
    await pumpStars(tester);

    expect(
      find.descendant(
        of: find.byType(TwinklingStars),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
  });

  testWidgets('twinkle animation repaints over time', (tester) async {
    await pumpStars(tester);

    final finder = find.descendant(
      of: find.byType(TwinklingStars),
      matching: find.byType(CustomPaint),
    );
    final before = tester.widget<CustomPaint>(finder).painter!;

    await tester.pump(const Duration(milliseconds: 300));

    final after = tester.widget<CustomPaint>(finder).painter!;
    expect(after.shouldRepaint(before), isTrue);
  });

  test('sky background is the dark indigo #12101E', () {
    expect(TwinklingStars.background, const Color(0xFF12101E));
  });
}
