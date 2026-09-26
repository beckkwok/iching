import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/models/gua.dart';
import 'package:app/models/question_type.dart';
import 'package:app/models/yao_line_type.dart';
import 'package:app/screens/cast_result_screen.dart';
import 'package:app/screens/explanation_screen.dart';
import 'package:app/screens/hexagram_detail_screen.dart';
import 'package:app/services/gua_generator.dart';
import 'package:app/widgets/hexagram_view.dart';

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

/// A richer hexagram with life-symbols and a 現代白話/通解 interpretation.
const _richJson = '''
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
    "生活與占事常見象徵": {
      "事業地位": "逐步晉升。",
      "學問修養": "勤學。",
      "時機": "處於生長期。",
      "態度": "謙遜。"
    },
    "總結": "總結"
  },
  "不同人解讀": [
    {
      "解讀者": "現代白話／通解（綜合）",
      "卦辭解讀": "升卦象徵上升。",
      "爻辭解讀": {"初九": "潛藏待時。", "六四": "審時而動。"}
    }
  ],
  "備註": ""
}
''';

GenerationResult _richResult() {
  final gua = Gua(guaCode: 46, guaName: '地風升', guaContent: _richJson);
  return GenerationResult(
    gua: gua,
    method: GeneratorMethod.systemGenerated,
    lines: const [true, false, true, false, true, false],
    lineTypes: const [
      YaoLineType.oldYang,
      YaoLineType.youngYin,
      YaoLineType.youngYang,
      YaoLineType.oldYin,
      YaoLineType.youngYang,
      YaoLineType.youngYin,
    ],
  );
}

void main() {
  testWidgets('cast result shows the hexagram symbol', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: CastResultScreen(result: _result())),
    );

    expect(find.text('Hexagram 46'), findsOneWidget);
    expect(find.text('地風升'), findsWidgets);
    expect(find.text('䷭（下巽上坤）'), findsOneWidget);
  });

  testWidgets('cast result shows a hexagram figure taller than it is wide',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: CastResultScreen(result: _result())),
    );

    final figure = find.byType(HexagramView);
    expect(figure, findsOneWidget);
    final size = tester.getSize(figure);
    expect(size.height, greaterThan(size.width));
  });

  testWidgets('爻象 bars are aligned and centred', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: CastResultScreen(result: _result())),
    );

    final centers = <double>[];
    for (var i = 0; i < 6; i++) {
      centers.add(tester.getCenter(find.byKey(ValueKey('yao-bar-$i'))).dx);
    }

    // Every bar shares the same horizontal centre...
    expect(centers.toSet().length, 1);
    // ...and that centre is the middle of the screen.
    final screenCenter = tester.getSize(find.byType(MaterialApp)).width / 2;
    expect((centers.first - screenCenter).abs(), lessThan(1));
  });

  testWidgets('cast result shows all four yao line types', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: CastResultScreen(result: _result())),
    );

    expect(find.text('Line pattern'), findsOneWidget);
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
    expect(find.text('Hexagram 46'), findsWidgets);
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

    await tester.scrollUntilVisible(
      find.text('Get Explanation'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
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

  testWidgets('result section shows 象徵意義 and 爻辭', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CastResultScreen(
          result: _richResult(),
          questionType: QuestionType.timing,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Scroll to the last item of the 結果 section so it is all laid out.
    await tester.scrollUntilVisible(
      find.text('六四：審時而動。'),
      250,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Result'), findsOneWidget);
    expect(find.text('Symbolic Meaning'), findsOneWidget);
    expect(find.text('Line Texts'), findsOneWidget);

    // Life-symbol entry for the selected question type (timing → 時機).
    expect(find.text('時機：處於生長期。'), findsOneWidget);

    // The modern 通解 interpretation, shown under 爻辭.
    expect(
      find.text('Judgment interpretation：升卦象徵上升。'),
      findsOneWidget,
    );
    expect(find.text('初九：潛藏待時。'), findsOneWidget);
    expect(find.text('六四：審時而動。'), findsOneWidget);
  });
}
