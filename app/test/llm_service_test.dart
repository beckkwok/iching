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
}
