import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/widgets/hexagram_view.dart';

void main() {
  testWidgets('renders the hexagram taller than it is wide', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: HexagramView(
              key: Key('hexagram'),
              lines: [true, false, true, false, true, false],
            ),
          ),
        ),
      ),
    );

    final size = tester.getSize(find.byKey(const Key('hexagram')));
    expect(size.height, greaterThan(size.width));
  });

  testWidgets('yang lines render one bar, yin lines render two', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HexagramView(lines: [true, true, true, true, true, true]),
        ),
      ),
    );
    // Six solid bars.
    expect(find.byType(Container), findsNWidgets(6));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HexagramView(lines: [false, false, false, false, false, false]),
        ),
      ),
    );
    // Six broken bars → twelve segments.
    expect(find.byType(Container), findsNWidgets(12));
  });

  testWidgets('respects a custom width while staying taller than wide', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: HexagramView(
              key: Key('hexagram'),
              lines: [true, true, true, true, true, true],
              width: 120,
              lineHeight: 12,
              gap: 10,
            ),
          ),
        ),
      ),
    );

    final size = tester.getSize(find.byKey(const Key('hexagram')));
    expect(size.width, 120);
    // 6 * 12 + 5 * 10 = 122 > 120.
    expect(size.height, 122);
    expect(size.height, greaterThan(size.width));
  });

  testWidgets('renders a label to the right of each line when provided', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HexagramView(
            key: Key('hexagram'),
            lines: [true, false, true, false, true, false],
            labels: ['少陽', '少陰', '少陽', '少陰', '少陽', '少陰'],
          ),
        ),
      ),
    );

    expect(find.text('少陽'), findsNWidgets(3));
    expect(find.text('少陰'), findsNWidgets(3));

    // The labels sit beside the bars, so the figure is wider than the bare
    // 72px bar column.
    final size = tester.getSize(find.byKey(const Key('hexagram')));
    expect(size.width, greaterThan(72));
  });

  testWidgets('labelled and unlabelled figures keep the same line spacing', (
    tester,
  ) async {
    const lines = [true, false, true, false, true, false];
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              HexagramView(
                key: Key('with-labels'),
                lines: lines,
                lineHeight: 14,
                gap: 10,
                labels: ['少陽', '少陰', '少陽', '少陰', '少陽', '少陰'],
              ),
              HexagramView(
                key: Key('plain'),
                lines: lines,
                lineHeight: 14,
                gap: 10,
              ),
            ],
          ),
        ),
      ),
    );

    final labelled = tester.getSize(find.byKey(const Key('with-labels')));
    final plain = tester.getSize(find.byKey(const Key('plain')));
    expect(labelled.height, plain.height);
  });
}
