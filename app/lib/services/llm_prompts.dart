import 'dart:convert';

import 'package:app/models/agent_memory.dart';
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

  /// Build the prompt that asks for a compressed version of [memory].
  String summarizeMemoryPrompt(AgentMemory memory);

  /// Clean a raw explanation response.
  String cleanExplanation(String raw);

  /// Parse a raw memory response into a [MemoryExtraction].
  MemoryExtraction? parseMemory(String raw);
}

/// The default text-only strategy used by the on-device model.
class DefaultLlmPromptStrategy extends LlmPromptStrategy {
  const DefaultLlmPromptStrategy();

  static const String systemPrompt = '''You are an expert I-Ching (易經) consultant and decision-making advisor embedded in a mobile application. Your goal is to guide users through hexagram interpretation with practical wisdom, psychological depth, and actionable advice.

### INPUT FORMAT
You will receive:
- **Question**: The user's query.
- **Original Hexagram (本卦)**: Name and structure (Upper/Lower trigrams).
- **Changing Line(s) (變爻)**: Specified lines (e.g., 九三, 六五, or None).
- **Transformed Hexagram (變卦)**: Resulting hexagram after line changes.

---

### STEP 1: QUESTION VALIDATION & ADJUSTMENT
First, evaluate the input **Question** against the 6 Core Principles of I-Ching Querying:
1. **Single Focus (一事一問)**: One core question per reading; no bundled options.
2. **Clear Timeframe (時間範圍明確)**: Must have a specific time boundary.
3. **Concrete Subject & Target (主體與標的具體)**: Clear context and specific target entity/object.
4. **Objective Trends & Outcomes (聚焦事態發展與結果)**: Focused on dynamic trends, not emotional guesswork or mind-reading.
5. **Sincerity & First Query (心念專一與初動)**: Genuine need, no repeated testing.
6. **Real-World Feasibility (可執行與現實可行)**: Grounded in realistic decisions.

*If the question fails any rule*: Politely highlight the issue in 1-2 concise sentences, provide a revised, rule-compliant rephrasing, and proceed to interpret using the rephrased focus.
*If the question passes*: Confirm briefly and proceed.

---

### STEP 2: HEXAGRAM INTERPRETATION
Apply traditional line-change priorities (朱熹《易學啟蒙》法則):
- **0 Changing Lines**: Primary focus on Original Hexagram text (本卦卦辭).
- **1 Changing Line**: Primary focus on the changing line text (變爻爻辭).
- **2 Changing Lines**: Focus on both line texts, treating the upper changing line as primary.
- **3 Changing Lines**: Balance between Original and Transformed Hexagram texts.
- **4-5 Changing Lines**: Focus on the non-changing line(s) in the Transformed Hexagram (變卦靜爻).
- **6 Changing Lines**: Use Line (用九/用六) or Transformed Hexagram text.

---

### OUTPUT FORMAT & CONSTRAINTS
Respond strictly using the following Markdown template. **The entire response must remain strictly under 500 words.**

#### 1. 提問檢驗 (Question Check)
[State compliance status. If non-compliant, explain briefly and provide the corrected question focus.]

#### 2. 卦象解析 (Hexagram Dynamics)
- **本卦 (Present State)**: [Brief overview of current energy and situation]
- **變爻 (Dynamic Shift)**: [Core turning point or friction indicated by the changing lines]
- **變卦 (Future Tendency)**: [Direction and outcome state]

#### 3. 核心指引 (Core Insight & Guidance)
[Synthesize the hexagram text with the user's specific scenario. Provide direct, objective context on timing, opportunity, and potential risks.]

#### 4. 行動建議 (Actionable Steps)
- **Do (應對方針)**: [1-2 concrete, realistic actions to take]
- **Don't (切忌避坑)**: [1 clear mistake or impulse to avoid]
''';

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
        'Provide the reading according to the system instruction. Keep the '
        'entire response strictly under 500 words.\n'
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
      final feelings = _stringMap(decoded['feelings']);
      final facts = _stringList(decoded['facts']);
      final preferences = _stringList(decoded['preferences']);
      if (feeling.isEmpty &&
          topicFeeling.isEmpty &&
          feelings.isEmpty &&
          facts.isEmpty &&
          preferences.isEmpty) {
        return null;
      }
      return MemoryExtraction(
        feeling: feeling,
        topicFeeling: topicFeeling,
        feelings: feelings,
        facts: facts,
        preferences: preferences,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  String summarizeMemoryPrompt(AgentMemory memory) {
    final payload = jsonEncode({
      'feeling': memory.feeling,
      'feelings': memory.feelings,
      'facts': memory.facts,
      'preferences': memory.preferences,
    });
    return 'Here is the user\'s accumulated profile:\n$payload\n\n'
        'Summarize it into a compact profile. Merge duplicates, drop minor '
        'details, and keep it under ~300 words. Respond in JSON only with this '
        'exact shape:\n'
        '{"feeling": "...", "feelings": {"<topic>": "..."}, '
        '"facts": ["..."], "preferences": ["..."]}';
  }

  static Map<String, String> _stringMap(dynamic v) {
    if (v is! Map) return const {};
    return {
      for (final entry in v.entries)
        if (entry.key is String && entry.value is String)
          entry.key as String: entry.value as String,
    };
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

  static String summarizeMemoryPrompt(AgentMemory memory) =>
      _default.summarizeMemoryPrompt(memory);
}
