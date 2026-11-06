import 'package:flutter_test/flutter_test.dart';

import 'package:app/models/agent_memory.dart';
import 'package:app/models/gua.dart';
import 'package:app/models/yao_line_type.dart';
import 'package:app/services/firebase_ai_backend.dart';
import 'package:app/services/gua_generator.dart';
import 'package:app/services/llm_prompts.dart';

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
  return GenerationResult(
    gua: Gua(guaCode: 46, guaName: '地風升', guaContent: _guaJson),
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

class _RecordingGenerator {
  final List<({String prompt, String systemPrompt, bool json})> calls = [];
  String? response;
  Object? error;

  Future<String?> call({
    required String prompt,
    required String systemPrompt,
    required bool json,
  }) async {
    calls.add((prompt: prompt, systemPrompt: systemPrompt, json: json));
    if (error != null) throw error!;
    return response;
  }
}

void main() {
  test(
    'generateExplanation builds the prompt and cleans the response',
    () async {
      final generator = _RecordingGenerator()
        ..response = '<|channel>thought\nreasoning<channel|>A gentle reading.';
      final backend = FirebaseAiBackend(
        guaGenerator: GuaGenerator(),
        generateContent: generator.call,
      );

      final text = await backend.generateExplanation(
        question: 'Should I take the new job?',
        result: _result(),
      );

      expect(text, 'A gentle reading.');
      final call = generator.calls.single;
      expect(call.prompt, contains('Should I take the new job?'));
      expect(call.prompt, contains('地風升'));
      expect(call.systemPrompt, LlmPrompts.systemPrompt);
      expect(call.json, isFalse);
    },
  );

  test('generateExplanation uses a custom system prompt', () async {
    final generator = _RecordingGenerator()..response = 'ok';
    final backend = FirebaseAiBackend(
      guaGenerator: GuaGenerator(),
      generateContent: generator.call,
    )..systemPrompt = 'Custom voice';

    await backend.generateExplanation(question: 'q', result: _result());

    expect(generator.calls.single.systemPrompt, 'Custom voice');
  });

  test('generateExplanation falls back when the call fails', () async {
    final generator = _RecordingGenerator()..error = StateError('offline');
    final backend = FirebaseAiBackend(
      guaGenerator: GuaGenerator(),
      generateContent: generator.call,
    );

    final text = await backend.generateExplanation(
      question: 'q',
      result: _result(),
    );

    expect(text, '(The explanation could not be generated.)');
  });

  test('extractMemory requests JSON and parses the profile', () async {
    final generator = _RecordingGenerator()
      ..response =
          '{"feeling":"hopeful","facts":["job change"],'
          '"preferences":["stability"]}';
    final backend = FirebaseAiBackend(
      guaGenerator: GuaGenerator(),
      generateContent: generator.call,
    );

    final memory = await backend.extractMemory(
      question: 'Should I move?',
      hexagramName: '地風升',
      explanation: 'A gentle reflection.',
    );

    expect(memory, isNotNull);
    expect(memory!.feeling, 'hopeful');
    expect(memory.facts, ['job change']);
    expect(memory.preferences, ['stability']);
    expect(generator.calls.single.json, isTrue);
  });

  test('extractMemory returns null when the call fails', () async {
    final generator = _RecordingGenerator()..error = StateError('offline');
    final backend = FirebaseAiBackend(
      guaGenerator: GuaGenerator(),
      generateContent: generator.call,
    );

    final memory = await backend.extractMemory(
      question: 'q',
      hexagramName: 'h',
      explanation: 'e',
    );

    expect(memory, isNull);
  });

  test('summarizeMemory sends the profile and parses the compact result',
      () async {
    final generator = _RecordingGenerator()
      ..response = '{"feeling":"calm","feelings":{"career":"hopeful"},'
          '"facts":["x"],"preferences":[]}';
    final backend = FirebaseAiBackend(
      guaGenerator: GuaGenerator(),
      generateContent: generator.call,
    );

    final summary = await backend.summarizeMemory(AgentMemory(
      feeling: 'long feeling',
      facts: const ['a'],
      preferences: const ['b'],
      updatedAt: DateTime(2026, 11, 6),
    ));

    expect(summary, isNotNull);
    expect(summary!.feeling, 'calm');
    expect(summary.feelings, {'career': 'hopeful'});
    expect(summary.facts, ['x']);
    final call = generator.calls.single;
    expect(call.json, isTrue);
    expect(call.prompt, contains('long feeling'));
  });
}
