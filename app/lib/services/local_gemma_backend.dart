import 'dart:async';
import 'dart:io';

import 'package:app/models/language_preference.dart';
import 'package:app/models/model_info.dart';
import 'package:app/services/gua_generator.dart';
import 'package:app/services/llm_backend.dart';
import 'package:app/services/llm_prompts.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// On-device LLM backend powered by `flutter_gemma` (`.litertlm` models).
///
/// Owns model download/path/initialization plus the single shot explanation
/// session. See [LlmBackend] for the backend contract.
class LocalGemmaBackend implements LlmBackend {
  final ModelInfo modelInfo;

  InferenceModel? _model;
  InferenceChat? _chat;
  GuaGenerator? _guaGenerator;

  /// Construct with a [modelInfo] describing the model to load.
  LocalGemmaBackend({required this.modelInfo});

  /// The system prompt used when opening a chat.
  String systemPrompt = LlmPrompts.systemPrompt;

  @override
  bool get isReady => _chat != null;

  /// The current model filename (e.g. "Qwen3-0.6B.litertlm").
  String get modelFilename => modelInfo.filename;

  /// Full absolute path to the model file.
  Future<String> get modelFilePath async => _modelPath;

  /// Human-readable model name for UI display.
  String get modelDisplayName => modelInfo.modelFamily;

  /// Set the Gua generator used to format hexagram context for explanations.
  set guaGenerator(GuaGenerator? g) => _guaGenerator = g;

  // ---------------------------------------------------------------------------
  // Model config (derived from [modelInfo])
  // ---------------------------------------------------------------------------

  static const ModelFileType _fileType = ModelFileType.litertlm;

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
  ///
  /// The loaded [InferenceModel] is **reused** across calls: only the
  /// conversation is recreated. Reloading the native engine per explanation
  /// allocates a second copy of the model and gets the app killed by the OS
  /// lowmemorykiller on memory-constrained devices. The model is created with
  /// the CPU backend because the default GPU/WebGPU path allocates several
  /// gigabytes for `.litertlm` models.
  Future<void> openExplanationChat() async {
    if (_model == null) {
      await _registerAndLoad();

      _model = await FlutterGemmaPlugin.instance.createModel(
        modelType: modelInfo.modelType,
        fileType: _fileType,
        maxTokens: 4096,
        preferredBackend: PreferredBackend.cpu,
      );
    } else if (_chat != null) {
      // Reuse the model; only start a fresh conversation.
      await _chat!.close();
      _chat = null;
    }

    _chat = await _model!.createChat(
      temperature: 0.7,
      topK: 40,
      topP: 0.95,
      tokenBuffer: 100,
      modelType: modelInfo.modelType,
      // The explanation is a short 3-5 sentence answer, so a reasoning pass is
      // unnecessary and makes CPU inference exceed the response timeout.
      // For Qwen3 this also appends `/no_think` to suppress reasoning.
      isThinking: false,
      // Cap the generated response so CPU inference stays responsive.
      maxOutputTokens: _maxOutputTokens,
      supportsFunctionCalls: false,
      tools: const [],
      systemInstruction: systemPrompt,
    );
  }

  // ---------------------------------------------------------------------------
  // One-shot explanation (form-based flow)
  // ---------------------------------------------------------------------------

  static const Duration _responseTimeout = Duration(seconds: 120);

  /// Upper bound on tokens generated per response. CPU inference is used to
  /// keep memory low, so the output is capped to keep latency reasonable.
  static const int _maxOutputTokens = 512;

  @override
  Future<String> generateExplanation({
    required String question,
    String? questionTypeLabel,
    required GenerationResult result,
    LanguagePreference language = LanguagePreference.english,
  }) async {
    // Fresh, tool-free session dedicated to the single-shot explanation.
    await openExplanationChat();

    final context = _guaGenerator!.formatContext(result);
    final prompt = LlmPrompts.buildExplanationPrompt(
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
        final cleaned = LlmPrompts.cleanResponseText(response.token);
        if (cleaned.isNotEmpty) {
          return cleaned;
        }
      }
    } on TimeoutException {
      await _chat!.stopGeneration();
    }
    return '(The explanation could not be generated.)';
  }

  // ---------------------------------------------------------------------------
  // Memory extraction (agent memory, issue #3)
  // ---------------------------------------------------------------------------

  /// Extract a concise user profile (feeling, facts, preferences) from a
  /// consultation. Reuses the open chat session when one exists.
  @override
  Future<MemoryExtraction?> extractMemory({
    required String question,
    required String hexagramName,
    required String explanation,
    String? comment,
    String? reaction,
    String? topicLabel,
  }) async {
    if (_chat == null) {
      await openExplanationChat();
    }

    final prompt = LlmPrompts.buildMemoryPrompt(
      question: question,
      hexagramName: hexagramName,
      explanation: explanation,
      comment: comment,
      reaction: reaction,
      topicLabel: topicLabel,
    );

    await _chat!.addQuery(Message(text: prompt, isUser: true));

    try {
      final response = await Future(
        () => _chat!.generateChatResponse(),
      ).timeout(_responseTimeout);
      if (response is TextResponse) {
        return LlmPrompts.parseMemoryExtraction(
          LlmPrompts.cleanResponseText(response.token),
        );
      }
    } on TimeoutException {
      await _chat!.stopGeneration();
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Cleanup
  // ---------------------------------------------------------------------------

  @override
  Future<void> close() async {
    if (_chat != null) {
      await _chat!.close();
      _chat = null;
    }
    if (_model != null) {
      await _model!.close();
      _model = null;
    }
  }
}
