import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/models/gua.dart';
import 'package:app/models/yao_line_type.dart';
import 'package:app/screens/explanation_screen.dart';
import 'package:app/screens/hexagram_detail_screen.dart';
import 'package:app/services/fake_llm_service.dart';
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
  testWidgets('shows question, hexagram, and LLM explanation', (tester) async {
    final llm = FakeLlmService();
    llm.explanationResponse = 'A gentle mirror for your question.';

    await tester.pumpWidget(
      MaterialApp(
        home: ExplanationScreen(
          question: 'Should I take the new job?',
          questionTypeLabel: 'Career Achievement',
          result: _result(),
          llmService: llm,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Career Achievement'), findsOneWidget);
    expect(find.text('Should I take the new job?'), findsOneWidget);
    expect(find.text('地風升'), findsOneWidget);
    expect(find.textContaining('第46卦'), findsOneWidget);
    expect(find.text('解讀'), findsOneWidget);
    expect(find.text('A gentle mirror for your question.'), findsOneWidget);
  });

  testWidgets('tapping the hexagram card opens the detail screen',
      (tester) async {
    final llm = FakeLlmService();
    llm.explanationResponse = 'A gentle mirror for your question.';

    await tester.pumpWidget(
      MaterialApp(
        home: ExplanationScreen(
          question: 'Should I take the new job?',
          result: _result(),
          llmService: llm,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('地風升'));
    await tester.pumpAndSettle();

    expect(find.byType(HexagramDetailScreen), findsOneWidget);
    expect(find.text('第46卦'), findsOneWidget);
  });

  testWidgets('shows placeholder when no LLM is available', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ExplanationScreen(
          question: 'Should I take the new job?',
          result: _result(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('No model available'), findsOneWidget);
  });
}
