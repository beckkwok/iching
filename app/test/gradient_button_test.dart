import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/widgets/gradient_button.dart';

void main() {
  Future<void> pumpButton(
    WidgetTester tester, {
    VoidCallback? onPressed,
    Widget? icon,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GradientButton(
              onPressed: onPressed,
              label: 'Go',
              icon: icon,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders its label', (tester) async {
    await pumpButton(tester, onPressed: () {});
    expect(find.text('Go'), findsOneWidget);
  });

  testWidgets('renders an icon when provided', (tester) async {
    await pumpButton(tester, onPressed: () {}, icon: const Icon(Icons.star));
    expect(find.byIcon(Icons.star), findsOneWidget);
  });

  testWidgets('fires onPressed when enabled', (tester) async {
    var tapped = false;
    await pumpButton(tester, onPressed: () => tapped = true);
    await tester.tap(find.text('Go'));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('does not fire onPressed when disabled', (tester) async {
    var tapped = false;
    await pumpButton(tester, onPressed: null);
    await tester.tap(find.text('Go'), warnIfMissed: false);
    await tester.pump();
    expect(tapped, isFalse);
  });

  testWidgets('fills with a purple gradient', (tester) async {
    await pumpButton(tester, onPressed: () {});

    final ink = tester.widget<Ink>(
      find.descendant(
        of: find.byType(GradientButton),
        matching: find.byType(Ink),
      ),
    );
    final decoration = ink.decoration! as BoxDecoration;
    final gradient = decoration.gradient! as LinearGradient;

    expect(gradient.colors, [GradientButton.start, GradientButton.end]);
  });

  testWidgets('has a gold glow box shadow', (tester) async {
    await pumpButton(tester, onPressed: () {});

    final ink = tester.widget<Ink>(
      find.descendant(
        of: find.byType(GradientButton),
        matching: find.byType(Ink),
      ),
    );
    final decoration = ink.decoration! as BoxDecoration;
    final shadow = decoration.boxShadow!.single;

    expect(shadow.color, GradientButton.glow.withValues(alpha: 0.5));
    expect(shadow.blurRadius, GradientButton.glowBlurRadius);
    expect(shadow.spreadRadius, GradientButton.glowSpreadRadius);
  });
}
