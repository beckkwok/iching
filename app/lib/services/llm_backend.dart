import 'package:app/models/agent_memory.dart';
import 'package:app/models/language_preference.dart';
import 'package:app/services/gua_generator.dart';

/// A pluggable LLM backend used to answer prompts.
///
/// The app can run either the on-device model ([LocalGemmaBackend]) or a remote
/// provider (issue #82). Screens talk to [LlmService], which delegates to the
/// active backend, so adding a backend does not change the UI layer.
abstract class LlmBackend {
  /// True once the backend is ready to generate responses.
  bool get isReady;

  /// The system instruction used for generation.
  String get systemPrompt;
  set systemPrompt(String value);

  /// Set the Gua generator used to format hexagram context.
  set guaGenerator(GuaGenerator? generator);

  /// Generate a one-shot I-Ching explanation.
  Future<String> generateExplanation({
    required String question,
    String? questionTypeLabel,
    required GenerationResult result,
    LanguagePreference language = LanguagePreference.english,
  });

  /// Extract the user's profile (agent memory) from a consultation.
  ///
  /// [language] controls the language of the extracted profile values.
  Future<MemoryExtraction?> extractMemory({
    required String question,
    required String hexagramName,
    required String explanation,
    String? comment,
    String? reaction,
    String? topicLabel,
    LanguagePreference language = LanguagePreference.english,
  });

  /// Compress an over-long profile into a compact one (issue #49).
  Future<MemoryExtraction?> summarizeMemory(
    AgentMemory memory, {
    LanguagePreference language = LanguagePreference.english,
  });

  /// Release any backend resources.
  Future<void> close();
}

/// The parsed result of a memory extraction.
class MemoryExtraction {
  /// Overall summary of how the user seems to feel.
  final String feeling;

  /// How the user seems to feel about the current consultation's topic.
  final String topicFeeling;

  /// Per-topic feelings (used when summarizing the whole profile).
  final Map<String, String> feelings;

  final List<String> facts;
  final List<String> preferences;

  const MemoryExtraction({
    required this.feeling,
    this.topicFeeling = '',
    this.feelings = const {},
    required this.facts,
    required this.preferences,
  });
}
