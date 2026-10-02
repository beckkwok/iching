import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/screens/cast_result_screen.dart';
import 'package:app/screens/manual_cast_screen.dart';
import 'package:app/services/gua_generator.dart';
import 'package:app/services/hexagram_loader.dart';
import 'package:app/widgets/hexagram_view.dart';

String _fixtureJson(int code) => '''
{
  "卦名": "卦$code",
  "卦序": $code,
  "卦象": "䷀（下乾上乾）",
  "卦辭": "",
  "彖傳": "",
  "大象傳": "",
  "爻辭": [],
  "象徵意義": {
    "基本卦象": {"卦體": "", "自然取象": "", "說明": ""},
    "主要象徵": [],
    "生活與占事常見象徵": {},
    "總結": ""
  },
  "不同人解讀": [],
  "備註": ""
}
''';

void main() {
  final generator = GuaGenerator(HexagramLoader((code) async => _fixtureJson(code)));

  Future<void> pumpManual(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ManualCastScreen(
          question: 'Should I move?',
          generator: generator,
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
      });
      await tester.pump();
    }
    await tester.pump();
  }

  testWidgets('shows six editable lines and resolves a hexagram',
      (tester) async {
    await pumpManual(tester);

    expect(find.text('Choose the six lines'), findsOneWidget);
    for (var i = 0; i < 6; i++) {
      expect(find.byKey(ValueKey('edit-yao-$i')), findsOneWidget);
    }
    // All six lines default to 少陽.
    expect(find.text('少陽'), findsNWidgets(6));
    expect(find.text('Use this hexagram'), findsOneWidget);
  });

  testWidgets('preview figure is taller than it is wide', (tester) async {
    await pumpManual(tester);

    final figure = find.byType(HexagramView);
    expect(figure, findsOneWidget);
    final size = tester.getSize(figure);
    expect(size.height, greaterThan(size.width));
  });

  testWidgets('tapping a line lets the user change its type', (tester) async {
    await pumpManual(tester);

    await tester.tap(find.byKey(const ValueKey('edit-yao-5')));
    await tester.pumpAndSettle();

    // The four line types are offered.
    expect(find.text('老陰'), findsOneWidget);
    expect(find.text('老陽'), findsOneWidget);

    await tester.tap(find.text('老陰'));
    await tester.pumpAndSettle();

    // The chosen type is now shown on the row.
    expect(find.text('老陰'), findsOneWidget);
    expect(find.text('少陽'), findsNWidgets(5));
  });

  testWidgets('proceeding opens the cast result screen', (tester) async {
    await pumpManual(tester);

    await tester.tap(find.text('Use this hexagram'));
    await tester.pumpAndSettle();

    expect(find.byType(CastResultScreen), findsOneWidget);
  });
}
