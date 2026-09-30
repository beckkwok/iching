import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/widgets/yao_loading_animation.dart';

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('renders six yao lines and the message', (tester) async {
    await tester.pumpWidget(
      _app(const YaoLoadingAnimation(message: 'Loading model...')),
    );
    await tester.pump(const Duration(milliseconds: 16));

    expect(find.text('Loading model...'), findsOneWidget);
    for (var i = 0; i < YaoLoadingAnimation.lineCount; i++) {
      expect(find.byKey(ValueKey('yao-line-$i')), findsOneWidget);
    }
  });

  testWidgets('cycles through the hexagram names', (tester) async {
    await tester.pumpWidget(
      _app(
        const YaoLoadingAnimation(
          message: 'Loading model...',
          hexagramNames: ['乾為天', '坤為地', '水雷屯'],
          nameInterval: Duration(seconds: 1),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.text('乾為天'), findsOneWidget);

    // Let the timer fire and the switcher finish.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('坤為地'), findsOneWidget);
    expect(find.text('乾為天'), findsNothing);
  });

  testWidgets('wraps back to the first name after the last', (tester) async {
    await tester.pumpWidget(
      _app(
        const YaoLoadingAnimation(
          message: 'Loading...',
          hexagramNames: ['A', 'B'],
          nameInterval: Duration(seconds: 1),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('B'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('A'), findsOneWidget);
  });
}
