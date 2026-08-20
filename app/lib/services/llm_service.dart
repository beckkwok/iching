import 'dart:async';
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

  /// The directory where models are stored.
  Future<String> get modelDir => _modelsDir;

  /// Full absolute path to the model file.
  /// Returns the custom path if set, otherwise the default models directory.
  String? _customModelPath;
  Future<String> get modelFilePath async =>
      _customModelPath ?? await _modelPath;

  /// The download URL for the selected model.
  String get modelUrl => modelInfo.downloadUrl;

  /// Switch to a different model file path. Closes the current chat session.
  /// After calling this, call [openExplanationChat] to load it.
  Future<void> setModelFile(String filePath) async {
    await closeChat();
    _customModelPath = filePath;
  }

  /// Set the Gua generator used to format hexagram context for explanations.
  set guaGenerator(GuaGenerator? g) => _guaGenerator = g;

  // ---------------------------------------------------------------------------
  // Model config (derived from [modelInfo])
  // ---------------------------------------------------------------------------

  static const ModelFileType _fileType = ModelFileType.litertlm;

  /// Human-readable model name for UI display.
  String get modelDisplayName => modelInfo.modelFamily;

  /// Approximate file size for UI display.
  String get modelSize => modelInfo.sizeLabel;

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

  Future<bool> isModelInstalled() async =>
      FlutterGemma.isModelInstalled(modelInfo.filename);

  Future<void> downloadModel({
    String? token,
    void Function(double progress)? onProgress,
  }) async {
    final targetPath = await _modelPath;
    // ignore: avoid_print
    print('ðŸ“¥ Downloading model to: $targetPath');
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
      print('âŒ Model file not found at: $modelPath');
      throw StateError('Model file not found at: $modelPath');
    } else {
      // ignore: avoid_print
      print('âœ… Model file found at: $modelPath');
    }
    // Only copy to flutter_gemma path for default (downloaded) models.
    if (_customModelPath == null) {
      await _copyToFlutterGemmaPath(modelPath);
    }
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

    final languageInstruction = switch (language) {
      LanguagePreference.english => 'Respond in English.',
      LanguagePreference.chinese => 'Respond in Traditional Chinese.',
    };

    final prompt =
        'The user asked: "$question"'
        '${questionTypeLabel != null ? ' (category: $questionTypeLabel)' : ''}'
        '\n\n'
        'The hexagram below was cast for them:\n$context\n\n'
        'Provide a compassionate I-Ching explanation that connects this '
        'hexagram to the user\'s question. Never predict fortune. Keep it to '
        '3-5 sentences and frame it as an invitation for reflection.\n'
        '$languageInstruction';

    // Print the full prompt so the developer can verify the hexagram info,
    // the user's question, and the language preference are all included.
    // ignore: avoid_print
    print('ðŸ“ Explanation prompt:\n$prompt');

    await _chat!.addQuery(Message(text: prompt, isUser: true));

    try {
      final response = await Future(
        () => _chat!.generateChatResponse(),
      ).timeout(_responseTimeout);
      if (response is TextResponse) {
        var text = response.token;
        text = text.replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), '');
        text = text.replaceAll(RegExp(r'<think>', dotAll: true), '');
        text = text.replaceAll(RegExp(r'</think>', dotAll: true), '');
        text = text.replaceAll(RegExp(r'<\|endoftext\|>?'), '');
        final trimmed = text.trim();
        if (trimmed.isNotEmpty) {
          return trimmed;
        }
      }
    } on TimeoutException {
      await _chat!.stopGeneration();
    }
    return '(The explanation could not be generated.)';
  }

// ---------------------------------------------------------------------------
  // Cleanup
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
