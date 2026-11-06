import 'package:app/models/agent_memory.dart';
import 'package:app/models/language_preference.dart';
import 'package:app/models/model_info.dart';
import 'package:app/services/gua_generator.dart';
import 'package:app/services/llm_backend.dart';
import 'package:app/services/llm_prompts.dart';
import 'package:app/services/local_gemma_backend.dart';

export 'package:app/services/llm_backend.dart'
    show LlmBackend, MemoryExtraction;
export 'package:app/services/llm_prompts.dart'
    show DefaultLlmPromptStrategy, LlmPromptStrategy;

/// Facade over the active [LlmBackend].
///
/// Today the active backend is the on-device [LocalGemmaBackend]; issue #82
/// adds a remote backend and #86 lets the user pick one. Screens keep talking
/// to this class so the UI layer does not depend on the backend.
///
/// The facade also exposes the local-model management API (download, path,
/// system prompt) that the model-selection/settings screens use.
class LlmService {
  late final LocalGemmaBackend _local;
  late final LlmBackend _active;

  /// Construct with a [modelInfo] describing the on-device model.
  ///
  /// [backend] overrides the active backend for prompt generation; when it is
  /// omitted the local backend is used. [promptStrategy] customizes how the
  /// local backend builds/parses prompts.
  LlmService({
    required ModelInfo modelInfo,
    LlmBackend? backend,
    LlmPromptStrategy? promptStrategy,
  }) {
    _local = LocalGemmaBackend(
      modelInfo: modelInfo,
      promptStrategy: promptStrategy,
    );
    _active = backend ?? _local;
  }

  /// The on-device model metadata.
  ModelInfo get modelInfo => _local.modelInfo;

  /// Settings table key under which a custom system prompt is stored.
  static const String systemPromptSettingsKey = 'system_prompt';

  /// The system prompt used when opening a chat.
  String get systemPrompt => _active.systemPrompt;
  set systemPrompt(String value) => _active.systemPrompt = value;

  bool get isReady => _active.isReady;

  /// The current model filename (e.g. "Qwen3-0.6B.litertlm").
  String get modelFilename => _local.modelFilename;

  /// Full absolute path to the model file.
  Future<String> get modelFilePath => _local.modelFilePath;

  /// Human-readable model name for UI display.
  String get modelDisplayName => _local.modelDisplayName;

  /// Set the Gua generator used to format hexagram context for explanations.
  set guaGenerator(GuaGenerator? g) {
    _local.guaGenerator = g;
    if (!identical(_active, _local)) _active.guaGenerator = g;
  }

  Future<void> initialize({String? huggingFaceToken}) =>
      _local.initialize(huggingFaceToken: huggingFaceToken);

  Future<void> downloadModel({
    String? token,
    void Function(double progress)? onProgress,
  }) => _local.downloadModel(token: token, onProgress: onProgress);

  Future<void> openExplanationChat() => _local.openExplanationChat();

  /// Generate a single explanation through the active backend.
  Future<String> generateExplanation({
    required String question,
    String? questionTypeLabel,
    required GenerationResult result,
    LanguagePreference language = LanguagePreference.english,
  }) => _active.generateExplanation(
    question: question,
    questionTypeLabel: questionTypeLabel,
    result: result,
    language: language,
  );

  /// Extract agent memory through the active backend.
  Future<MemoryExtraction?> extractMemory({
    required String question,
    required String hexagramName,
    required String explanation,
    String? comment,
    String? reaction,
    String? topicLabel,
    LanguagePreference language = LanguagePreference.english,
  }) => _active.extractMemory(
    question: question,
    hexagramName: hexagramName,
    explanation: explanation,
    comment: comment,
    reaction: reaction,
    topicLabel: topicLabel,
    language: language,
  );

  /// Compress an over-long profile through the active backend (issue #49).
  Future<MemoryExtraction?> summarizeMemory(
    AgentMemory memory, {
    LanguagePreference language = LanguagePreference.english,
  }) => _active.summarizeMemory(memory, language: language);

  /// Release the active backend and the local model resources.
  Future<void> closeChat() async {
    await _active.close();
    if (!identical(_active, _local)) {
      await _local.close();
    }
  }

  // ---------------------------------------------------------------------------
  // Prompt helpers (kept here for callers/tests; implemented by [LlmPrompts])
  // ---------------------------------------------------------------------------

  static String buildExplanationPrompt({
    required String question,
    String? questionTypeLabel,
    required String hexagramContext,
    LanguagePreference language = LanguagePreference.english,
  }) => LlmPrompts.buildExplanationPrompt(
    question: question,
    questionTypeLabel: questionTypeLabel,
    hexagramContext: hexagramContext,
    language: language,
  );

  static String cleanResponseText(String text) =>
      LlmPrompts.cleanResponseText(text);

  static String buildMemoryPrompt({
    required String question,
    required String hexagramName,
    required String explanation,
    String? comment,
    String? reaction,
    String? topicLabel,
    LanguagePreference language = LanguagePreference.english,
  }) => LlmPrompts.buildMemoryPrompt(
    question: question,
    hexagramName: hexagramName,
    explanation: explanation,
    comment: comment,
    reaction: reaction,
    topicLabel: topicLabel,
    language: language,
  );

  static MemoryExtraction? parseMemoryExtraction(String text) =>
      LlmPrompts.parseMemoryExtraction(text);
}
