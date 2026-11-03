import 'package:flutter_test/flutter_test.dart';

import 'package:app/data/model_catalog.dart';
import 'package:app/models/gua.dart';
import 'package:app/models/language_preference.dart';
import 'package:app/services/gua_generator.dart';
import 'package:app/services/llm_service.dart';

void main() {
  group('LlmService.buildExplanationPrompt', () {
    test('includes the user question', () {
      final prompt = LlmService.buildExplanationPrompt(
        question: 'Should I take the new job?',
        hexagramContext: 'Hexagram: 乾為天 (gua code 1)',
      );

      expect(prompt, contains('Should I take the new job?'));
    });

    test('includes the category when provided', () {
      final prompt = LlmService.buildExplanationPrompt(
        question: 'Should I move?',
        questionTypeLabel: 'Career Achievement',
        hexagramContext: 'ctx',
      );

      expect(prompt, contains('(category: Career Achievement)'));
    });

    test('omits the category when null', () {
      final prompt = LlmService.buildExplanationPrompt(
        question: 'Should I move?',
        hexagramContext: 'ctx',
      );

      expect(prompt, isNot(contains('category')));
    });

    test('includes the hexagram context', () {
      final prompt = LlmService.buildExplanationPrompt(
        question: 'q',
        hexagramContext: 'Hexagram: 地風升 (gua code 46)',
      );

      expect(prompt, contains('Hexagram: 地風升 (gua code 46)'));
    });

    test('defaults to an English instruction', () {
      final prompt = LlmService.buildExplanationPrompt(
        question: 'q',
        hexagramContext: 'ctx',
      );

      expect(prompt, contains('Respond in English.'));
      expect(prompt, isNot(contains('Traditional Chinese')));
    });

    test('uses a Chinese instruction when requested', () {
      final prompt = LlmService.buildExplanationPrompt(
        question: 'q',
        hexagramContext: 'ctx',
        language: LanguagePreference.chinese,
      );

      expect(prompt, contains('Respond in Traditional Chinese.'));
      expect(prompt, isNot(contains('Respond in English.')));
    });

    test('does not request a JSON response (token saving)', () {
      final prompt = LlmService.buildExplanationPrompt(
        question: 'q',
        hexagramContext: 'ctx',
      );

      expect(prompt, isNot(contains('JSON')));
    });
  });

  group('LlmService.cleanResponseText', () {
    test('removes a complete think block', () {
      expect(
        LlmService.cleanResponseText('<think>reasoning here</think>Answer.'),
        'Answer.',
      );
    });

    test('removes stray think tags', () {
      expect(LlmService.cleanResponseText('<think>Answer.'), 'Answer.');
      expect(LlmService.cleanResponseText('Answer.</think>'), 'Answer.');
    });

    test('removes end-of-text tokens', () {
      expect(LlmService.cleanResponseText('Answer.<|endoftext|>'), 'Answer.');
      expect(LlmService.cleanResponseText('Answer.<|endoftext|'), 'Answer.');
    });

    test('removes Gemma 4 thinking channels', () {
      expect(
        LlmService.cleanResponseText(
          '<|channel>thought\nreasoning here<channel|>Answer.',
        ),
        'Answer.',
      );
      expect(
        LlmService.cleanResponseText(
          '<|channel>thought\r\nreasoning<channel|>\r\nAnswer.',
        ),
        'Answer.',
      );
      expect(
        LlmService.cleanResponseText(
          '<|channel>thought\na<channel|>'
          '<|channel>thought\nb<channel|>Answer.',
        ),
        'Answer.',
      );
    });

    test('removes Gemma 4 final channel markers', () {
      expect(
        LlmService.cleanResponseText('<|channel>final\nAnswer.<channel|>'),
        'Answer.',
      );
      expect(
        LlmService.cleanResponseText('<|channel|>Answer.<|channel|>'),
        'Answer.',
      );
      expect(
        LlmService.cleanResponseText('Intro. <|channel>final\nAnswer.'),
        'Intro. Answer.',
      );
    });

    test('removes common chat-template tokens', () {
      expect(
        LlmService.cleanResponseText(
          '<start_of_turn>model\nAnswer.<end_of_turn><|im_end|>',
        ),
        'Answer.',
      );
    });

    test('trims surrounding whitespace', () {
      expect(LlmService.cleanResponseText('  \n Answer. \n '), 'Answer.');
    });

    test('returns an empty string for whitespace-only input', () {
      expect(LlmService.cleanResponseText('   \n  '), isEmpty);
    });

    test('leaves normal text untouched', () {
      expect(
        LlmService.cleanResponseText('A gentle reflection.'),
        'A gentle reflection.',
      );
    });
  });

  group('LlmService memory extraction', () {
    test(
      'buildMemoryPrompt includes question, hexagram, explanation, comment',
      () {
        final prompt = LlmService.buildMemoryPrompt(
          question: 'Should I move?',
          hexagramName: '地風升',
          explanation: 'A gentle reflection.',
          comment: 'I feel hopeful.',
        );

        expect(prompt, contains('Should I move?'));
        expect(prompt, contains('地風升'));
        expect(prompt, contains('A gentle reflection.'));
        expect(prompt, contains('I feel hopeful.'));
        expect(prompt, contains('JSON'));
      },
    );

    test('buildMemoryPrompt omits the comment when null', () {
      final prompt = LlmService.buildMemoryPrompt(
        question: 'q',
        hexagramName: 'h',
        explanation: 'e',
      );
      expect(prompt, isNot(contains("User's comment")));
      expect(prompt, isNot(contains("User's reaction")));
    });

    test('buildMemoryPrompt includes the reaction when provided', () {
      final prompt = LlmService.buildMemoryPrompt(
        question: 'q',
        hexagramName: 'h',
        explanation: 'e',
        reaction: '❤️',
      );
      expect(prompt, contains("User's reaction"));
      expect(prompt, contains('❤️'));
    });

    test('buildMemoryPrompt includes the topic label when provided', () {
      final prompt = LlmService.buildMemoryPrompt(
        question: 'q',
        hexagramName: 'h',
        explanation: 'e',
        topicLabel: 'Career Achievement',
      );
      expect(prompt, contains('Question topic: Career Achievement'));
    });

    test('parseMemoryExtraction parses topic_feeling', () {
      final extraction = LlmService.parseMemoryExtraction(
        '{"feeling": "overall", "topic_feeling": "career nerves", '
        '"facts": [], "preferences": []}',
      );
      expect(extraction, isNotNull);
      expect(extraction!.feeling, 'overall');
      expect(extraction.topicFeeling, 'career nerves');
    });

    test('parseMemoryExtraction parses a JSON response', () {
      final extraction = LlmService.parseMemoryExtraction(
        '{"feeling": "hopeful", "facts": ["job change"], '
        '"preferences": ["stability"]}',
      );
      expect(extraction, isNotNull);
      expect(extraction!.feeling, 'hopeful');
      expect(extraction.facts, ['job change']);
      expect(extraction.preferences, ['stability']);
    });

    test('parseMemoryExtraction handles surrounding text', () {
      final extraction = LlmService.parseMemoryExtraction(
        'Here is it: {"feeling":"x","facts":[],"preferences":[]} done',
      );
      expect(extraction, isNotNull);
      expect(extraction!.feeling, 'x');
    });

    test('parseMemoryExtraction returns null for malformed or empty input', () {
      expect(LlmService.parseMemoryExtraction('no json here'), isNull);
      expect(
        LlmService.parseMemoryExtraction(
          '{"feeling":"","facts":[],"preferences":[]}',
        ),
        isNull,
      );
    });
  });

  group('LlmService backend delegation', () {
    test(
      'uses the injected backend for generation, memory and readiness',
      () async {
        final backend = _RecordingBackend();
        final service = LlmService(
          modelInfo: ModelCatalog.all.first,
          backend: backend,
        );

        expect(service.isReady, isTrue);

        final text = await service.generateExplanation(
          question: 'q',
          result: _result(),
        );
        expect(text, 'from-fake');
        expect(backend.explanationCalls, 1);

        final memory = await service.extractMemory(
          question: 'q',
          hexagramName: 'h',
          explanation: 'e',
        );
        expect(memory?.feeling, 'calm');
        expect(backend.memoryCalls, 1);

        await service.closeChat();
        expect(backend.closed, isTrue);
      },
    );
  });

  group('LlmPromptStrategy injection', () {
    test('local backend uses the injected strategy system prompt', () {
      final service = LlmService(
        modelInfo: ModelCatalog.all.first,
        promptStrategy: const _FakePromptStrategy(),
      );

      expect(service.systemPrompt, 'fake-system');

      service.systemPrompt = 'custom';
      expect(service.systemPrompt, 'custom');
    });

    test('default strategy matches the legacy static helpers', () {
      const strategy = DefaultLlmPromptStrategy();
      expect(
        strategy.explanationPrompt(question: 'q', hexagramContext: 'ctx'),
        LlmService.buildExplanationPrompt(
          question: 'q',
          hexagramContext: 'ctx',
        ),
      );
      expect(strategy.cleanExplanation('<think>x</think>ok'), 'ok');
    });
  });
}

GenerationResult _result() {
  final gua = Gua(guaCode: 1, guaName: '乾為天', guaContent: '{}');
  return GenerationResult(
    gua: gua,
    method: GeneratorMethod.systemGenerated,
    lines: const [true, true, true, true, true, true],
  );
}

/// A minimal [LlmBackend] that records calls.
class _RecordingBackend implements LlmBackend {
  int explanationCalls = 0;
  int memoryCalls = 0;
  bool closed = false;

  @override
  bool get isReady => true;

  @override
  Future<String> generateExplanation({
    required String question,
    String? questionTypeLabel,
    required GenerationResult result,
    LanguagePreference language = LanguagePreference.english,
  }) async {
    explanationCalls++;
    return 'from-fake';
  }

  @override
  Future<MemoryExtraction?> extractMemory({
    required String question,
    required String hexagramName,
    required String explanation,
    String? comment,
    String? reaction,
    String? topicLabel,
  }) async {
    memoryCalls++;
    return const MemoryExtraction(feeling: 'calm', facts: [], preferences: []);
  }

  @override
  Future<void> close() async {
    closed = true;
  }
}

/// A [LlmPromptStrategy] that returns fixed values, for injection tests.
class _FakePromptStrategy extends LlmPromptStrategy {
  const _FakePromptStrategy();

  @override
  String get defaultSystemPrompt => 'fake-system';

  @override
  String explanationPrompt({
    required String question,
    String? questionTypeLabel,
    required String hexagramContext,
    LanguagePreference language = LanguagePreference.english,
  }) => 'fake-explanation';

  @override
  String memoryPrompt({
    required String question,
    required String hexagramName,
    required String explanation,
    String? comment,
    String? reaction,
    String? topicLabel,
  }) => 'fake-memory';

  @override
  String cleanExplanation(String raw) => raw.trim();

  @override
  MemoryExtraction? parseMemory(String raw) => null;
}
