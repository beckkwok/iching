import 'package:flutter_test/flutter_test.dart';

import 'package:app/models/language_preference.dart';
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
      expect(
        LlmService.cleanResponseText('Answer.<|endoftext|>'),
        'Answer.',
      );
      expect(
        LlmService.cleanResponseText('Answer.<|endoftext|'),
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
    test('buildMemoryPrompt includes question, hexagram, explanation, comment',
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
    });

    test('buildMemoryPrompt omits the comment when null', () {
      final prompt = LlmService.buildMemoryPrompt(
        question: 'q',
        hexagramName: 'h',
        explanation: 'e',
      );
      expect(prompt, isNot(contains("User's comment")));
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

    test('parseMemoryExtraction returns null for malformed or empty input',
        () {
      expect(LlmService.parseMemoryExtraction('no json here'), isNull);
      expect(
        LlmService.parseMemoryExtraction(
          '{"feeling":"","facts":[],"preferences":[]}',
        ),
        isNull,
      );
    });
  });
}
