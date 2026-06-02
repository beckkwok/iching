import 'dart:async';
import 'dart:io';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

/// Wraps flutter_gemma for the I-Ching app.
///
/// Models are stored in [appDocDir]/models/.  You can also pre-download
/// the model via scripts/download_model.ps1 and place it in app/models/.
class LlmService {
  InferenceModel? _model;
  InferenceChat? _chat;

  bool get isReady => _chat != null;

  // ---------------------------------------------------------------------------
  // Model configuration — Qwen3 0.6B
  // ---------------------------------------------------------------------------

  static const String _filename = 'Qwen3-0.6B.litertlm';

  String get _modelUrl =>
      'https://huggingface.co/litert-community/Qwen3-0.6B/'
      'resolve/main/Qwen3-0.6B.litertlm';

  /// Directory where models are stored: [appDocDir]/models/
  Future<String> get _modelsDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, 'models'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  Future<String> get _modelPath async => p.join(await _modelsDir, _filename);

  /// Check for a pre-downloaded model in the project's models/ directory
  /// (useful during development — run scripts/download_model.ps1 first).
  Future<String?> _findPreDownloadedModel() async {
    // During development with `flutter run`, the working directory is
    // the project root.  Check several common locations.
    final candidates = [
      p.join('models', _filename),                       // app/
      p.join(Directory.current.path, 'models', _filename), // absolute from CWD
      p.join(Directory.current.path, 'app', 'models', _filename),
    ];
    for (final c in candidates) {
      final f = File(c);
      if (await f.exists()) {
        return f.path;
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Initialisation & download
  // ---------------------------------------------------------------------------

  Future<void> initialize({String? huggingFaceToken}) async {
    await FlutterGemma.initialize(
      huggingFaceToken: huggingFaceToken,
    );
  }

  /// Check if the model is already registered with flutter_gemma.
  Future<bool> isModelInstalled() async {
    return FlutterGemma.isModelInstalled(_filename);
  }

  /// Copy model file to flutter_gemma's default Windows path so its file
  /// validation in [createModel] can find it.
  Future<void> _copyToFlutterGemmaPath(String sourcePath) async {
    if (Platform.isWindows) {
      final localAppData = Platform.environment['LOCALAPPDATA'] ?? '';
      if (localAppData.isNotEmpty) {
        final targetDir = Directory(p.join(localAppData, 'flutter_gemma'));
        if (!await targetDir.exists()) {
          await targetDir.create(recursive: true);
        }
        final targetPath = p.join(targetDir.path, _filename);
        // ignore: avoid_print
        print('📁 FlutterGemma expected path: $targetPath');
        if (!await File(targetPath).exists()) {
          await File(sourcePath).copy(targetPath);
          // ignore: avoid_print
          print('📁 Copied model to flutter_gemma path');
        } else {
          // ignore: avoid_print
          print('📁 Model already exists at flutter_gemma path');
        }
      }
    }
  }

  /// Download model file to [appDocDir]/models/ and register it.
  Future<void> downloadModel({
    String? token,
    void Function(double progress)? onProgress,
  }) async {
    final targetPath = await _modelPath;
    final file = File(targetPath);

    final request = http.Request('GET', Uri.parse(_modelUrl));
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.Client().send(request);
    if (response.statusCode != 200) {
      throw HttpException(
        'Download failed (HTTP ${response.statusCode})',
        uri: Uri.parse(_modelUrl),
      );
    }

    final totalBytes = response.contentLength ?? -1;
    var receivedBytes = 0;

    final sink = file.openWrite();
    await for (final chunk in response.stream) {
      sink.add(chunk);
      receivedBytes += chunk.length;
      if (totalBytes > 0) {
        onProgress?.call(receivedBytes / totalBytes);
      }
    }
    await sink.flush();
    await sink.close();

    await _registerAndLoad();
  }

  /// Register the model file (from our models/ or pre-downloaded) and load it.
  Future<void> _registerAndLoad() async {
    final modelPath = await _modelPath;
    // ignore: avoid_print
    print('📁 Model path: $modelPath');
    final file = File(modelPath);

    if (!await file.exists()) {
      // Try pre-downloaded model in project directory
      final preDownloaded = await _findPreDownloadedModel();
      if (preDownloaded != null) {
        // Copy to the expected models/ directory
        final modelsDir = await _modelsDir;
        await Directory(modelsDir).create(recursive: true);
        await File(preDownloaded).copy(modelPath);
      } else {
        throw StateError(
          'Model file not found. Download it first, or run:\n'
          '  cd app && scripts/download_model.ps1',
        );
      }
    }

    // Copy to flutter_gemma's default path on Windows (AppData/Local/flutter_gemma/)
    // so its file validation in createModel() finds the file.
    await _copyToFlutterGemmaPath(modelPath);

    // Register with flutter_gemma via fromFile so the file path is explicit.
    await FlutterGemma.installModel(
      modelType: ModelType.qwen3,
      fileType: ModelFileType.litertlm,
    ).fromFile(modelPath).install();
  }

  // ---------------------------------------------------------------------------
  // Chat session
  // ---------------------------------------------------------------------------

  Future<void> openChat() async {
    await closeChat();

    // Ensure the model is registered (idempotent on subsequent calls)
    await _registerAndLoad();

    // Create the model.  Bypass getActiveModel() and use the plugin
    // directly — this avoids flutter_gemma's active-model validation
    // which can fail on Windows even when the file exists.
    _model = await FlutterGemmaPlugin.instance.createModel(
      modelType: ModelType.qwen3,
      fileType: ModelFileType.litertlm,
      maxTokens: 1024,
    );

    _chat = await _model!.createChat(
      temperature: 0.9,
      topK: 40,
      topP: 0.95,
      tokenBuffer: 100, // reserve 100 tokens before context rotation
      modelType: ModelType.qwen3,
      isThinking: false, // disable thinking mode to prevent hangs
      systemInstruction: _systemPrompt,
    );
  }

  /// Send a message and return the response text.
  ///
  /// Uses the streaming API ([generateChatResponseAsync]) which naturally
  /// separates thinking tokens from text tokens — no manual regex needed.
  /// Maximum time to wait for the model to finish generating.
  static const Duration _responseTimeout = Duration(seconds: 60);

  /// Send a message and return the response text.
  ///
  /// Uses the sync API ([generateChatResponse]) to avoid issues with
  /// flutter_gemma's streaming context rotation on Windows.
  /// Strips any leftover `think` tags from the raw response.
  Future<String> sendMessage(String message) async {
    if (_chat == null) {
      throw StateError('Chat not opened. Call openChat() first.');
    }

    await _chat!.addQuery(Message(text: message, isUser: true));

    try {
      final response = await Future(() => _chat!.generateChatResponse())
          .timeout(_responseTimeout);

      if (response is TextResponse) {
        var text = response.token;
        // Strip any <think>...</think> tags the model may emit
        text = text.replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), '');
        text = text.replaceAll(RegExp(r'<think>', dotAll: true), '');
        text = text.replaceAll(RegExp(r'</think>', dotAll: true), '');
        text = text.trim();
        if (text.isEmpty) {
          return 'I am here. Please tell me more about what is on your mind.';
        }
        return text;
      }
      return '[unexpected response: ${response.runtimeType}]';
    } on TimeoutException {
      await _chat!.stopGeneration();
      return '(The model took too long to respond. Please try again.)';
    }
  }

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
      'You are a compassionate I-Ching consultant. Your role is to help users '
      'reflect on their life situations through the wisdom of the I-Ching '
      '(Book of Changes).\n\n'
      'Guidelines:\n'
      '- Listen carefully to what the user shares about their situation.\n'
      '- If they mention a specific hexagram (gua), incorporate its wisdom.\n'
      '- Otherwise, gently suggest that a hexagram may offer perspective.\n'
      '- NEVER predict good or bad fortune. Do NOT say "good luck" or "bad luck".\n'
      '- Instead, frame responses as invitations for reflection.\n'
      '- Ask open-ended questions that help the user explore their own feelings.\n'
      '- Be warm, supportive, and encouraging.\n'
      '- Keep responses concise (2-4 sentences).\n'
      '- Use gentle, poetic language when referencing I-Ching concepts.\n'
      '- Remember: the goal is emotional support and self-reflection, '
          'not divination.\n'
      '- Respond directly without using any XML or HTML tags.';
}
