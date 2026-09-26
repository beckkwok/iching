import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/widgets/gradient_button.dart';

void main() {
  Future<void> pumpButton(
    WidgetTester tester, {
    VoidCallback? onPressed,
    Widget? icon,
    Brightness brightness = Brightness.light,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: brightness),
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

  Ink ink(WidgetTester tester) => tester.widget<Ink>(
        find.descendant(
          of: find.byType(GradientButton),
          matching: find.byType(Ink),
        ),
      );

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

  testWidgets('light mode uses the solid purple gradient', (tester) async {
    await pumpButton(tester, onPressed: () {});
    final decoration = ink(tester).decoration! as BoxDecoration;
    final gradient = decoration.gradient! as LinearGradient;

    expect(gradient.colors, [GradientButton.start, GradientButton.end]);
    expect(decoration.boxShadow, isNull);
  });

  testWidgets('dark mode has a translucent fill, gold border and glow',
      (tester) async {
    await pumpButton(tester, onPressed: () {}, brightness: Brightness.dark);
    final decoration = ink(tester).decoration! as BoxDecoration;

    expect(decoration.border, isA<Border>());
    expect(
      (decoration.border! as Border).top.color,
      GradientButton.gold.withValues(alpha: 0.55),
    );

    final shadow = decoration.boxShadow!.single;
    expect(shadow.color, GradientButton.gold.withValues(alpha: 0.5));
    expect(shadow.blurRadius, GradientButton.glowBlurRadius);
    expect(shadow.spreadRadius, GradientButton.glowSpreadRadius);
  });

  testWidgets('shrinks while pressed', (tester) async {
    await pumpButton(tester, onPressed: () {}, brightness: Brightness.dark);

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Go')),
    );
    await tester.pump();

    final scale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
    expect(scale.scale, GradientButton.pressedScale);

    await gesture.up();
    await tester.pump();
  });

  testWidgets('sizes to its content when loosely constrained', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: const Scaffold(
          body: SizedBox(
            width: 300,
            height: 200,
            child: Center(
              child: GradientButton(onPressed: _noop, label: 'Go'),
            ),
          ),
        ),
      ),
    );

    final size = tester.getSize(find.byType(GradientButton));
    expect(size.width, lessThan(200));
    expect(size.height, lessThan(60));
  });
}

void _noop() {}
