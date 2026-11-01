import 'dart:convert';

import 'package:app/models/language_preference.dart';
import 'package:app/services/llm_backend.dart';

/// Builds prompts and parses responses for a specific [LlmBackend].
///
/// Prompt/response handling differs per backend: the on-device model uses
/// plain text plus `<think>`/templating cleanup, while a remote provider such
/// as Gemini can use its own system instruction and structured JSON output.
/// Implement this per backend instead of sharing one implementation.
abstract class LlmPromptStrategy {
  const LlmPromptStrategy();

  /// The default system instruction for this backend.
  String get defaultSystemPrompt;

  /// Build the one-shot explanation prompt.
  String explanationPrompt({
    required String question,
    String? questionTypeLabel,
    required String hexagramContext,
    LanguagePreference language = LanguagePreference.english,
  });

  /// Build the prompt that asks for a JSON user-profile extraction.
  String memoryPrompt({
    required String question,
    required String hexagramName,
    required String explanation,
    String? comment,
    String? reaction,
    String? topicLabel,
  });

  /// Clean a raw explanation response.
  String cleanExplanation(String raw);

  /// Parse a raw memory response into a [MemoryExtraction].
  MemoryExtraction? parseMemory(String raw);
}

/// The default text-only strategy used by the on-device model.
class DefaultLlmPromptStrategy extends LlmPromptStrategy {
  const DefaultLlmPromptStrategy();

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

  @override
  String get defaultSystemPrompt => systemPrompt;

  @override
  String explanationPrompt({
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

  @override
  String cleanExplanation(String raw) {
    var cleaned = raw;

    // Gemma 4 thinking channel: <|channel>thought\n...<channel|>.
    cleaned = cleaned.replaceAll(
      RegExp(r'<\|channel>thought\s*\r?\n?.*?<channel\|>', dotAll: true),
      '',
    );

    // DeepSeek / Qwen3 reasoning blocks.
    cleaned = cleaned.replaceAll(
      RegExp(r'<think>.*?</think>', dotAll: true),
      '',
    );
    cleaned = cleaned.replaceAll(RegExp(r'</?think>'), '');

    // Remaining channel markers, e.g. <|channel>final\n ... <channel|>.
    cleaned = cleaned.replaceAll(
      RegExp(r'<\|channel>\s*(?:thought|final)?\s*\r?\n?'),
      '',
    );
    cleaned = cleaned.replaceAll(RegExp(r'<\|?channel\|?>'), '');

    // Common chat-template / control tokens.
    cleaned = cleaned.replaceAll(RegExp(r'<\|endoftext\|?>?'), '');
    cleaned = cleaned.replaceAll(
      RegExp(
        r'<\|(?:im_start|im_end|eot_id|assistant|user|system|'
        r'start_header_id|end_header_id)\|?>',
      ),
      '',
    );
    // Gemma turn markers, including the role word after the start marker.
    cleaned = cleaned.replaceAll(
      RegExp(r'<start_of_turn>\s*(?:model|user|assistant)\s*\r?\n?'),
      '',
    );
    cleaned = cleaned.replaceAll(
      RegExp(r'</?(?:start_of_turn|end_of_turn)>'),
      '',
    );

    return cleaned.trim();
  }

  @override
  String memoryPrompt({
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

  @override
  MemoryExtraction? parseMemory(String raw) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    try {
      final decoded =
          jsonDecode(raw.substring(start, end + 1)) as Map<String, dynamic>;
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

/// Backwards-compatible static helpers.
///
/// New code should inject an [LlmPromptStrategy] into its backend instead.
class LlmPrompts {
  LlmPrompts._();

  static const LlmPromptStrategy _default = DefaultLlmPromptStrategy();

  /// The default system prompt (on-device strategy).
  static const String systemPrompt = DefaultLlmPromptStrategy.systemPrompt;

  static String buildExplanationPrompt({
    required String question,
    String? questionTypeLabel,
    required String hexagramContext,
    LanguagePreference language = LanguagePreference.english,
  }) => _default.explanationPrompt(
    question: question,
    questionTypeLabel: questionTypeLabel,
    hexagramContext: hexagramContext,
    language: language,
  );

  static String cleanResponseText(String text) =>
      _default.cleanExplanation(text);

  static String buildMemoryPrompt({
    required String question,
    required String hexagramName,
    required String explanation,
    String? comment,
    String? reaction,
    String? topicLabel,
  }) => _default.memoryPrompt(
    question: question,
    hexagramName: hexagramName,
    explanation: explanation,
    comment: comment,
    reaction: reaction,
    topicLabel: topicLabel,
  );

  static MemoryExtraction? parseMemoryExtraction(String text) =>
      _default.parseMemory(text);
}
