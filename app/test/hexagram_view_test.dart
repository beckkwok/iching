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

  testWidgets('yang lines render one bar, yin lines render two',
      (tester) async {
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

  testWidgets('respects a custom width while staying taller than wide',
      (tester) async {
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
}
