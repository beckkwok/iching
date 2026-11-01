import 'dart:convert';

import 'package:app/models/language_preference.dart';
import 'package:app/services/llm_backend.dart';

/// Pure prompt-building and response-parsing helpers shared by every
/// [LlmBackend] (on-device or remote).
///
/// Kept side-effect free so they can be unit-tested without a model.
class LlmPrompts {
  LlmPrompts._();

  /// The default I-Ching consultant system prompt.
  static const String systemPrompt =
      'You are a compassionate I-Ching consultant. Help users reflect through '
      'the wisdom of the I-Ching (Book of Changes).\n\n'
      'A hexagram has already been cast for the user and its details are '
      'provided in the prompt. Connect that hexagram to the user\'s question '
      'and help them reflect on it.\n\n'
      'Guidelines:\n'
      '- Listen carefully to what the user shares.\n'
      '- Never predict good or bad fortune. Frame responses as invitations '
      'for reflection.\n'
      '- Ask open-ended questions to help the user explore their feelings.\n'
      '- Be warm, supportive, and encouraging. Keep responses to 3-5 '
      'sentences.\n'
      '- Use gentle, poetic language when referencing I-Ching concepts.';

  /// Build the one-shot user message that asks the model for an explanation.
  static String buildExplanationPrompt({
    required String question,
    String? questionTypeLabel,
    required String hexagramContext,
    LanguagePreference language = LanguagePreference.english,
  }) {
    final languageInstruction = switch (language) {
      LanguagePreference.english => 'Respond in English.',
      LanguagePreference.chinese => 'Respond in Traditional Chinese.',
    };
    return 'The user asked: "$question"'
        '${questionTypeLabel != null ? ' (category: $questionTypeLabel)' : ''}'
        '\n\n'
        'The hexagram below was cast for them:\n$hexagramContext\n\n'
        'Provide a compassionate I-Ching explanation that connects this '
        'hexagram to the user\'s question. Never predict fortune. Keep it to '
        '3-5 sentences and frame it as an invitation for reflection.\n'
        '$languageInstruction';
  }

  /// Strip model artifacts from a raw response: `<think>` blocks (and stray
  /// opening/closing tags) and `<|endoftext|>` tokens. Returns the trimmed
  /// result.
  static String cleanResponseText(String text) {
    var cleaned = text;
    cleaned = cleaned.replaceAll(
      RegExp(r'<think>.*?</think>', dotAll: true),
      '',
    );
    cleaned = cleaned.replaceAll(RegExp(r'<think>', dotAll: true), '');
    cleaned = cleaned.replaceAll(RegExp(r'</think>', dotAll: true), '');
    cleaned = cleaned.replaceAll(RegExp(r'<\|endoftext\|>?'), '');
    return cleaned.trim();
  }

  /// Build the prompt that asks the model to extract the user's profile as
  /// JSON.
  static String buildMemoryPrompt({
    required String question,
    required String hexagramName,
    required String explanation,
    String? comment,
    String? reaction,
    String? topicLabel,
  }) {
    final commentLine = (comment != null && comment.isNotEmpty)
        ? 'User\'s comment: "$comment"\n'
        : '';
    final reactionLine = (reaction != null && reaction.isNotEmpty)
        ? 'User\'s reaction to the answer: $reaction\n'
        : '';
    final topicLine = (topicLabel != null && topicLabel.isNotEmpty)
        ? 'Question topic: $topicLabel\n'
        : '';
    return 'A user asked an I-Ching question and received a hexagram and an '
        'explanation.\n\n'
        'Question: "$question"\n'
        '$topicLine'
        'Hexagram: $hexagramName\n'
        'Explanation: $explanation\n'
        '$commentLine'
        '$reactionLine'
        '\n'
        'Extract a concise profile of the user. Respond in JSON only, with '
        'this exact shape:\n'
        '{"feeling": "one short sentence about how the user seems to feel '
        'overall", '
        '"topic_feeling": "one short sentence about how the user seems to feel '
        'about this specific topic", '
        '"facts": ["a fact about the user"], '
        '"preferences": ["a preference or value the user expressed"]}\n'
        'Keep each fact and preference to a few words. Use empty arrays when '
        'nothing applies.';
  }

  /// Parse a JSON memory extraction. Returns `null` on malformed or empty
  /// input.
  static MemoryExtraction? parseMemoryExtraction(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    try {
      final decoded =
          jsonDecode(text.substring(start, end + 1)) as Map<String, dynamic>;
      final feeling = (decoded['feeling'] as String? ?? '').trim();
      final topicFeeling = (decoded['topic_feeling'] as String? ?? '').trim();
      final facts = _stringList(decoded['facts']);
      final preferences = _stringList(decoded['preferences']);
      if (feeling.isEmpty &&
          topicFeeling.isEmpty &&
          facts.isEmpty &&
          preferences.isEmpty) {
        return null;
      }
      return MemoryExtraction(
        feeling: feeling,
        topicFeeling: topicFeeling,
        facts: facts,
        preferences: preferences,
      );
    } catch (_) {
      return null;
    }
  }

  static List<String> _stringList(dynamic v) {
    if (v is! List) return const [];
    return v
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }
}
