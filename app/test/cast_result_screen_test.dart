import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/models/gua.dart';
import 'package:app/models/yao_line_type.dart';
import 'package:app/screens/cast_result_screen.dart';
import 'package:app/screens/explanation_screen.dart';
import 'package:app/screens/hexagram_detail_screen.dart';
import 'package:app/services/gua_generator.dart';

const _guaJson = '''
{
  "卦名": "地風升",
  "卦序": 46,
  "卦象": "䷭（下巽上坤）",
  "卦辭": "升：元亨。",
  "彖傳": "",
  "大象傳": "",
  "爻辭": [],
  "象徵意義": {
    "基本卦象": {"卦體": "下巽上坤", "自然取象": "地中生木", "說明": "說明"},
    "主要象徵": [],
    "生活與占事常見象徵": {},
    "總結": "總結"
  },
  "不同人解讀": [],
  "備註": ""
}
''';

GenerationResult _result() {
  final gua = Gua(
    guaCode: 46,
    guaName: '地風升',
    guaContent: _guaJson,
  );
  final lines = [true, false, true, false, true, false];
  final lineTypes = [
    YaoLineType.oldYang,
    YaoLineType.youngYin,
    YaoLineType.youngYang,
    YaoLineType.oldYin,
    YaoLineType.youngYang,
    YaoLineType.youngYin,
  ];
  return GenerationResult(
    gua: gua,
    method: GeneratorMethod.systemGenerated,
    lines: lines,
    lineTypes: lineTypes,
  );
}

void main() {
  testWidgets('cast result shows the hexagram symbol', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: CastResultScreen(result: _result())),
    );

    expect(find.text('第46卦'), findsOneWidget);
    expect(find.text('地風升'), findsWidgets);
    expect(find.text('䷭（下巽上坤）'), findsOneWidget);
  });

  testWidgets('cast result shows all four yao line types', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: CastResultScreen(result: _result())),
    );

    expect(find.text('爻象'), findsOneWidget);
    // Old/changing lines get a 變 suffix.
    expect(find.textContaining('老陽'), findsOneWidget);
    expect(find.textContaining('老陰'), findsOneWidget);
    // Stable lines.
    expect(find.text('少陽'), findsNWidgets(2));
    expect(find.text('少陰'), findsNWidgets(2));
  });

  testWidgets('cast result shows line positions 初..上', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: CastResultScreen(result: _result())),
    );

    expect(find.text('初'), findsOneWidget);
    expect(find.text('二'), findsOneWidget);
    expect(find.text('三'), findsOneWidget);
    expect(find.text('四'), findsOneWidget);
    expect(find.text('五'), findsOneWidget);
    expect(find.text('上'), findsOneWidget);
  });

  testWidgets('tapping the 卦象 card opens the hexagram detail screen',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: CastResultScreen(result: _result())),
    );

    await tester.tap(find.text('Tap for details'));
    await tester.pumpAndSettle();

    expect(find.byType(HexagramDetailScreen), findsOneWidget);
    expect(find.text('第46卦'), findsWidgets);
  });

  testWidgets('Get Explanation button opens the explanation screen when a '
      'question is provided', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CastResultScreen(
          result: _result(),
          question: 'Should I take the new job?',
          questionTypeLabel: 'Career Achievement',
        ),
      ),
    );

    expect(find.text('Get Explanation'), findsOneWidget);
    await tester.tap(find.text('Get Explanation'));
    await tester.pumpAndSettle();

    expect(find.byType(ExplanationScreen), findsOneWidget);
    expect(find.text('Should I take the new job?'), findsOneWidget);
  });

  testWidgets('Get Explanation button is hidden when no question is provided',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: CastResultScreen(result: _result())),
    );

    expect(find.text('Get Explanation'), findsNothing);
  });

  testWidgets('back button pops back to the previous screen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CastResultScreen(result: _result()),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(CastResultScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.byType(CastResultScreen), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });
}
