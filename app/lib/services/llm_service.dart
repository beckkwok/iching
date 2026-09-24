import 'dart:async';
import 'dart:convert';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../models/language_preference.dart';
import '../models/model_info.dart';
import '../services/gua_generator.dart';

/// Wraps flutter_gemma for the I-Ching app.
class LlmService {
  final ModelInfo modelInfo;

  InferenceModel? _model;
  InferenceChat? _chat;
  GuaGenerator? _guaGenerator;

  /// Construct with a [modelInfo] describing the model to load.
  LlmService({required this.modelInfo});

  /// Settings table key under which a custom system prompt is stored.
  static const String systemPromptSettingsKey = 'system_prompt';

  /// The system prompt used when opening a chat. Defaults to [_systemPrompt];
  /// callers can override it (e.g. from a saved user preference).
  String systemPrompt = _systemPrompt;

  bool get isReady => _chat != null;

  /// The current model filename (e.g. "Qwen3-0.6B.litertlm").
  String get modelFilename => modelInfo.filename;

  /// Full absolute path to the model file.
  Future<String> get modelFilePath async => _modelPath;

  /// Set the Gua generator used to format hexagram context for explanations.
  set guaGenerator(GuaGenerator? g) => _guaGenerator = g;

  // ---------------------------------------------------------------------------
  // Model config (derived from [modelInfo])
  // ---------------------------------------------------------------------------

  static const ModelFileType _fileType = ModelFileType.litertlm;

  /// Human-readable model name for UI display.
  String get modelDisplayName => modelInfo.modelFamily;

  Future<String> get _modelsDir async {
    final appDir = await getApplicationSupportDirectory();
    final dir = Directory(p.join(appDir.path, 'models'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  Future<String> get _modelPath async =>
      p.join(await _modelsDir, modelInfo.filename);

  // ---------------------------------------------------------------------------
  // Init & download
  // ---------------------------------------------------------------------------

  Future<void> initialize({String? huggingFaceToken}) async {
    await FlutterGemma.initialize(
      huggingFaceToken: huggingFaceToken,
      inferenceEngines: [LiteRtLmEngine()],
    );
  }

  Future<void> downloadModel({
    String? token,
    void Function(double progress)? onProgress,
  }) async {
    final targetPath = await _modelPath;
    // ignore: avoid_print
    print('📥 Downloading model to: $targetPath');
    final file = File(targetPath);
    final request = http.Request('GET', Uri.parse(modelInfo.downloadUrl));
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    final response = await http.Client().send(request);
    if (response.statusCode != 200) {
      throw HttpException(
        'Download failed (HTTP ${response.statusCode})',
        uri: Uri.parse(modelInfo.downloadUrl),
      );
    }
    final totalBytes = response.contentLength ?? -1;
    var receivedBytes = 0;
    final sink = file.openWrite();
    await for (final chunk in response.stream) {
      sink.add(chunk);
      receivedBytes += chunk.length;
      if (totalBytes > 0) onProgress?.call(receivedBytes / totalBytes);
    }
    await sink.flush();
    await sink.close();
    await _registerAndLoad();
  }

  Future<void> _registerAndLoad() async {
    final modelPath = await modelFilePath;
    final file = File(modelPath);
    if (!await file.exists()) {
      // ignore: avoid_print
      print('❌ Model file not found at: $modelPath');
      throw StateError('Model file not found at: $modelPath');
    } else {
      // ignore: avoid_print
      print('✅ Model file found at: $modelPath');
    }
    await _copyToFlutterGemmaPath(modelPath);
    await FlutterGemma.installModel(
      modelType: modelInfo.modelType,
      fileType: _fileType,
    ).fromFile(modelPath).install();
  }

  Future<void> _copyToFlutterGemmaPath(String sourcePath) async {
    if (Platform.isWindows) {
      final localAppData = Platform.environment['LOCALAPPDATA'] ?? '';
      if (localAppData.isNotEmpty) {
        final targetDir = Directory(p.join(localAppData, 'flutter_gemma'));
        if (!await targetDir.exists()) await targetDir.create(recursive: true);
        final targetPath = p.join(targetDir.path, modelInfo.filename);
        if (!await File(targetPath).exists()) {
          await File(sourcePath).copy(targetPath);
        }
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Explanation session (form-based flow)
  // ---------------------------------------------------------------------------

  /// Open a fresh chat session for one-shot explanations.
  ///
  /// Function calling is disabled and no tools are registered, so the model
  /// answers directly instead of trying to call `generate_gua` (the hexagram
  /// is already cast in the form-based flow).
  Future<void> openExplanationChat() async {
    await closeChat();
    await _registerAndLoad();

    _model = await FlutterGemmaPlugin.instance.createModel(
      modelType: modelInfo.modelType,
      fileType: _fileType,
      maxTokens: 4096,
    );

    _chat = await _model!.createChat(
      temperature: 0.7,
      topK: 40,
      topP: 0.95,
      tokenBuffer: 100,
      modelType: modelInfo.modelType,
      isThinking: modelInfo.isThinking,
      supportsFunctionCalls: false,
      tools: const [],
      systemInstruction: systemPrompt,
    );
  }

  // ---------------------------------------------------------------------------
  // One-shot explanation (form-based flow)
  // ---------------------------------------------------------------------------

  static const Duration _responseTimeout = Duration(seconds: 60);

  /// Generate a single explanation that connects a cast [result] to the
  /// user's [question]. This is a one-shot call (no multi-turn history, no
  /// function-calling tools), so token usage stays low enough for on-device
  /// LLMs.
  ///
  /// [questionTypeLabel] is the human-readable category (e.g. "Career
  /// Achievement"). [language] selects the language the model should respond
  /// in (defaults to [LanguagePreference.english]).
  Future<String> generateExplanation({
    required String question,
    String? questionTypeLabel,
    required GenerationResult result,
    LanguagePreference language = LanguagePreference.english,
  }) async {
    // Fresh, tool-free session dedicated to the single-shot explanation.
    await openExplanationChat();

    final context = _guaGenerator!.formatContext(result);
    final prompt = buildExplanationPrompt(
      question: question,
      questionTypeLabel: questionTypeLabel,
      hexagramContext: context,
      language: language,
    );

    // Print the full prompt so the developer can verify the hexagram info,
    // the user's question, and the language preference are all included.
    // ignore: avoid_print
    print('📝 Explanation prompt:\n$prompt');

    await _chat!.addQuery(Message(text: prompt, isUser: true));

    try {
      final response = await Future(
        () => _chat!.generateChatResponse(),
      ).timeout(_responseTimeout);
      if (response is TextResponse) {
        final cleaned = cleanResponseText(response.token);
        if (cleaned.isNotEmpty) {
          return cleaned;
        }
      }
    } on TimeoutException {
      await _chat!.stopGeneration();
    }
    return '(The explanation could not be generated.)';
  }

  /// Build the one-shot user message that asks the model for an explanation.
  ///
  /// Pure and side-effect free, so it can be unit-tested without an LLM.
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
  /// result. Pure and side-effect free, so it can be unit-tested.
  static String cleanResponseText(String text) {
    var cleaned = text;
    cleaned =
        cleaned.replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), '');
    cleaned = cleaned.replaceAll(RegExp(r'<think>', dotAll: true), '');
    cleaned = cleaned.replaceAll(RegExp(r'</think>', dotAll: true), '');
    cleaned = cleaned.replaceAll(RegExp(r'<\|endoftext\|>?'), '');
    return cleaned.trim();
  }

  // ---------------------------------------------------------------------------
  // Memory extraction (agent memory, issue #3)
  // ---------------------------------------------------------------------------

  /// Extract a concise user profile (feeling, facts, preferences) from a
  /// consultation. Reuses the open chat session when one exists.
  Future<MemoryExtraction?> extractMemory({
    required String question,
    required String hexagramName,
    required String explanation,
    String? comment,
  }) async {
    if (_chat == null) {
      await openExplanationChat();
    }

    final prompt = buildMemoryPrompt(
      question: question,
      hexagramName: hexagramName,
      explanation: explanation,
      comment: comment,
    );

    await _chat!.addQuery(Message(text: prompt, isUser: true));

    try {
      final response = await Future(
        () => _chat!.generateChatResponse(),
      ).timeout(_responseTimeout);
      if (response is TextResponse) {
        return parseMemoryExtraction(cleanResponseText(response.token));
      }
    } on TimeoutException {
      await _chat!.stopGeneration();
    }
    return null;
  }

  /// Build the prompt that asks the model to extract the user's profile as
  /// JSON. Pure and side-effect free, so it can be unit-tested.
  static String buildMemoryPrompt({
    required String question,
    required String hexagramName,
    required String explanation,
    String? comment,
  }) {
    final commentLine = (comment != null && comment.isNotEmpty)
        ? 'User\'s comment: "$comment"\n'
        : '';
    return 'A user asked an I-Ching question and received a hexagram and an '
        'explanation.\n\n'
        'Question: "$question"\n'
        'Hexagram: $hexagramName\n'
        'Explanation: $explanation\n'
        '$commentLine'
        '\n'
        'Extract a concise profile of the user. Respond in JSON only, with '
        'this exact shape:\n'
        '{"feeling": "one short sentence about how the user seems to feel '
        'about this topic", '
        '"facts": ["a fact about the user"], '
        '"preferences": ["a preference or value the user expressed"]}\n'
        'Keep each fact and preference to a few words. Use empty arrays when '
        'nothing applies.';
  }

  /// Parse a JSON memory extraction. Returns `null` on malformed or empty
  /// input. Pure and side-effect free, so it can be unit-tested.
  static MemoryExtraction? parseMemoryExtraction(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    try {
      final decoded =
          jsonDecode(text.substring(start, end + 1)) as Map<String, dynamic>;
      final feeling = (decoded['feeling'] as String? ?? '').trim();
      final facts = _stringList(decoded['facts']);
      final preferences = _stringList(decoded['preferences']);
      if (feeling.isEmpty && facts.isEmpty && preferences.isEmpty) return null;
      return MemoryExtraction(
        feeling: feeling,
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

  // ---------------------------------------------------------------------------
  // Cleanup
  // ---------------------------------------------------------------------------

  Future<void> closeChat() async {
    if (_chat != null) {
      await _chat!.close();
      _chat = null;
    }
    if (_model != null) {
      await _model!.close();
      _model = null;
    }
  }

  // ---------------------------------------------------------------------------
  // I-Ching system prompt
  // ---------------------------------------------------------------------------

  static const String _systemPrompt =
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
}

/// The parsed result of a memory extraction.
class MemoryExtraction {
  final String feeling;
  final List<String> facts;
  final List<String> preferences;

  const MemoryExtraction({
    required this.feeling,
    required this.facts,
    required this.preferences,
  });
}
