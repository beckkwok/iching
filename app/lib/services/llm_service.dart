import 'dart:async';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../services/gua_generator.dart';

/// Wraps flutter_gemma for the I-Ching app.
class LlmService {
  InferenceModel? _model;
  InferenceChat? _chat;
  GuaGenerator? _guaGenerator;

  bool get isReady => _chat != null;

  /// Set the Gua generator for function calling.
  set guaGenerator(GuaGenerator? g) => _guaGenerator = g;

  // ---------------------------------------------------------------------------
  // Model config — Qwen3 0.6B
  // ---------------------------------------------------------------------------

  static const String _filename = 'Qwen3-0.6B.litertlm';
  String get _modelUrl => 'https://huggingface.co/litert-community/Qwen3-0.6B/'
      'resolve/main/Qwen3-0.6B.litertlm';

  Future<String> get _modelsDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, 'models'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  Future<String> get _modelPath async => p.join(await _modelsDir, _filename);

  /// Tool definition: let the LLM request a hexagram.
  static const List<Tool> _tools = [
    Tool(
      name: 'generate_gua',
      description:
          'Casts a hexagram (gua) for the user. Call this when the user '
          'asks for a hexagram, wants guidance from the I-Ching, or when '
          'you sense a hexagram would help them reflect.',
      parameters: {
        'type': 'object',
        'properties': {
          'intent': {
            'type': 'string',
            'description':
                'What the user is seeking guidance about, if mentioned',
          },
        },
      },
    ),
  ];

  // ---------------------------------------------------------------------------
  // Init & download
  // ---------------------------------------------------------------------------

  Future<void> initialize({String? huggingFaceToken}) async {
    await FlutterGemma.initialize(huggingFaceToken: huggingFaceToken);
  }

  Future<bool> isModelInstalled() async =>
      FlutterGemma.isModelInstalled(_filename);

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
      throw HttpException('Download failed (HTTP ${response.statusCode})',
          uri: Uri.parse(_modelUrl));
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
    final modelPath = await _modelPath;
    final file = File(modelPath);
    if (!await file.exists()) throw StateError('Model file not found');
    await _copyToFlutterGemmaPath(modelPath);
    await FlutterGemma.installModel(
      modelType: ModelType.qwen3,
      fileType: ModelFileType.litertlm,
    ).fromFile(modelPath).install();
  }

  Future<void> _copyToFlutterGemmaPath(String sourcePath) async {
    if (Platform.isWindows) {
      final localAppData = Platform.environment['LOCALAPPDATA'] ?? '';
      if (localAppData.isNotEmpty) {
        final targetDir = Directory(p.join(localAppData, 'flutter_gemma'));
        if (!await targetDir.exists()) await targetDir.create(recursive: true);
        final targetPath = p.join(targetDir.path, _filename);
        if (!await File(targetPath).exists()) {
          await File(sourcePath).copy(targetPath);
        }
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Chat session
  // ---------------------------------------------------------------------------

  Future<void> openChat() async {
    await closeChat();
    await _registerAndLoad();

    _model = await FlutterGemmaPlugin.instance.createModel(
      modelType: ModelType.qwen3,
      fileType: ModelFileType.litertlm,
      maxTokens: 1024,
    );

    _chat = await _model!.createChat(
      temperature: 0.9,
      topK: 40,
      topP: 0.95,
      tokenBuffer: 100,
      modelType: ModelType.qwen3,
      isThinking: false,
      supportsFunctionCalls: true,
      tools: _tools,
      systemInstruction: _systemPrompt,
    );
  }

  // ---------------------------------------------------------------------------
  // Send message with function calling support
  // ---------------------------------------------------------------------------

  static const Duration _responseTimeout = Duration(seconds: 60);

  /// Send a message and return the response text.
  ///
  /// The LLM may call `generate_gua` to request a hexagram. This method
  /// detects the function call, generates a Gua via [GuaGenerator], feeds
  /// the result back to the LLM, and returns the final response.
  Future<String> sendMessage(String message) async {
    if (_chat == null) {
      throw StateError('Chat not opened. Call openChat() first.');
    }

    // Keep re-prompting until we get a text response (not a function call)
    // or until the LLM decides no hexagram is needed.
    String? responseText;
    int maxTurns = 3;

    await _chat!.addQuery(Message(text: message, isUser: true));

    while (responseText == null && maxTurns > 0) {
      maxTurns--;

      try {
        final response = await Future(() => _chat!.generateChatResponse())
            .timeout(_responseTimeout);

        if (response is TextResponse) {
          var text = response.token;
          text = text.replaceAll(
              RegExp(r'<think>.*?</think>', dotAll: true), '');
          text = text.replaceAll(RegExp(r'<think>', dotAll: true), '');
          text = text.replaceAll(RegExp(r'</think>', dotAll: true), '');
          responseText = text.trim();
        } else if (response is FunctionCallResponse) {
          if (response.name == 'generate_gua' && _guaGenerator != null) {
            final result = await _guaGenerator!.generateRandom();
            final context = _guaGenerator!.formatContext(result);
            // Feed the Gua result back to the chat as a tool response
            await _chat!.addQuery(
              Message.toolCall(text: context),
            );
          } else {
            // Unknown function or no generator — just continue
            await _chat!.addQuery(
              Message.toolCall(text: '(function not available)'),
            );
          }
        }
      } on TimeoutException {
        await _chat!.stopGeneration();
        responseText = '(The model took too long to respond.)';
      }
    }

    return responseText ?? '(No response could be generated.)';
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
      'You are a compassionate I-Ching consultant. Your role is to help users '
      'reflect on their life situations through the wisdom of the I-Ching '
      '(Book of Changes).\n\n'
      'You have access to the `generate_gua` function. When the user asks '
      'for guidance, or when you feel a hexagram would help them reflect, '
      'call generate_gua. After the hexagram is generated, you will receive '
      'its details — use them to offer a thoughtful reflection.\n\n'
      'Guidelines:\n'
      '- Listen carefully to what the user shares about their situation.\n'
      '- If they mention a specific hexagram by name, call generate_gua.\n'
      '- Otherwise, ask if they would like a hexagram cast, or call '
      'generate_gua when you sense it would be helpful.\n'
      '- NEVER predict good or bad fortune. Do NOT say "good luck" or '
      '"bad luck".\n'
      '- Instead, frame responses as invitations for reflection.\n'
      '- Ask open-ended questions that help the user explore their own '
      'feelings.\n'
      '- Be warm, supportive, and encouraging.\n'
      '- Keep responses concise (2-4 sentences).\n'
      '- Use gentle, poetic language when referencing I-Ching concepts.\n'
      '- Remember: the goal is emotional support and self-reflection, '
      'not divination.\n'
      '- Respond directly without using any XML or HTML tags.';
}
