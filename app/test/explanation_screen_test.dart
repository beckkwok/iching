import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/models/consultation.dart';
import 'package:app/models/gua.dart';
import 'package:app/models/yao_line_type.dart';
import 'package:app/screens/explanation_screen.dart';
import 'package:app/screens/hexagram_detail_screen.dart';
import 'package:app/services/database_service.dart';
import 'package:app/services/fake_llm_service.dart';
import 'package:app/services/gua_generator.dart';
import 'package:app/services/llm_service.dart';

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
    expect(find.textContaining('Hexagram 46'), findsOneWidget);
    expect(find.text('Interpretation'), findsOneWidget);
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
    expect(find.text('Hexagram 46'), findsOneWidget);
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

  testWidgets('saves a consultation after generating the explanation',
      (tester) async {
    final llm = FakeLlmService();
    llm.explanationResponse = 'A gentle mirror for your question.';
    final db = _RecordingDb();

    await tester.pumpWidget(
      MaterialApp(
        home: ExplanationScreen(
          question: 'Should I take the new job?',
          questionTypeLabel: 'Career Achievement',
          result: _result(),
          llmService: llm,
          databaseService: db,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(db.saved, hasLength(1));
    final c = db.saved.first;
    expect(c.question, 'Should I take the new job?');
    expect(c.questionTypeLabel, 'Career Achievement');
    expect(c.hexagramCode, 46);
    expect(c.hexagramName, '地風升');
    expect(c.hexagramContent, _guaJson);
    expect(c.explanation, 'A gentle mirror for your question.');
  });

  testWidgets('submits feedback on the consultation', (tester) async {
    final llm = FakeLlmService();
    llm.explanationResponse = 'A gentle mirror for your question.';
    final db = _RecordingDb();

    await tester.pumpWidget(
      MaterialApp(
        home: ExplanationScreen(
          question: 'Should I take the new job?',
          result: _result(),
          llmService: llm,
          databaseService: db,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Feedback'), findsOneWidget);

    // Tap the 4th star (rating = 4).
    await tester.tap(find.byIcon(Icons.star_border).at(3));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Very helpful');
    await tester.tap(find.text('Submit feedback'));
    await tester.pumpAndSettle();

    expect(db.feedback, hasLength(1));
    expect(db.feedback.first.$1, 1);
    expect(db.feedback.first.$2, 4);
    expect(db.feedback.first.$3, 'Very helpful');
    expect(find.text('Thanks for your feedback!'), findsOneWidget);
  });

  testWidgets('builds agent memory after the explanation', (tester) async {
    final llm = _MemoryLlm();
    llm.explanationResponse = 'A gentle mirror for your question.';
    final db = _RecordingDb();

    await tester.pumpWidget(
      MaterialApp(
        home: ExplanationScreen(
          question: 'Should I take the new job?',
          result: _result(),
          llmService: llm,
          databaseService: db,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(db.merges, hasLength(1));
    expect(db.merges.first.$2, contains('considering a job change'));
    expect(db.merges.first.$3, contains('values stability'));
  });
}

/// A [DatabaseService] that records consultations and feedback instead of
/// touching SQLite.
class _RecordingDb extends DatabaseService {
  _RecordingDb() : super(databasePath: ':memory:');

  final List<Consultation> saved = [];
  final List<(int, int, String?)> feedback = [];

  @override
  Future<Consultation> createConsultation(Consultation consultation) async {
    final withId = Consultation(
      id: saved.length + 1,
      question: consultation.question,
      questionTypeLabel: consultation.questionTypeLabel,
      hexagramCode: consultation.hexagramCode,
      hexagramName: consultation.hexagramName,
      hexagramContent: consultation.hexagramContent,
      explanation: consultation.explanation,
      createdAt: consultation.createdAt,
    );
    saved.add(withId);
    return withId;
  }

  @override
  Future<void> updateConsultationFeedback(
    int id, {
    required int rating,
    String? comment,
  }) async {
    feedback.add((id, rating, comment));
  }

  final List<(String, List<String>, List<String>)> merges = [];

  @override
  Future<void> mergeAgentMemory({
    required String feeling,
    required List<String> facts,
    required List<String> preferences,
  }) async {
    merges.add((feeling, facts, preferences));
  }
}

/// A [FakeLlmService] that also returns a fixed memory extraction.
class _MemoryLlm extends FakeLlmService {
  @override
  Future<MemoryExtraction?> extractMemory({
    required String question,
    required String hexagramName,
    required String explanation,
    String? comment,
  }) async {
    return MemoryExtraction(
      feeling: comment == null ? 'hopeful' : 'hopeful and reflective',
      facts: const ['considering a job change'],
      preferences: const ['values stability'],
    );
  }
}
