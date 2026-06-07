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
  bool _guaGenerated = false; // only one hexagram per conversation

  bool get isReady => _chat != null;

  /// The current model filename (e.g. "Qwen3-0.6B.litertlm").
  String get modelFilename => _filename;

  /// The directory where models are stored.
  Future<String> get modelDir => _modelsDir;

  /// Full absolute path to the model file.
  /// Returns the custom path if set, otherwise the default models directory.
  String? _customModelPath;
  Future<String> get modelFilePath async =>
      _customModelPath ?? await _modelPath;

  /// The download URL for the default model.
  String get modelUrl => _modelUrl;

  /// Switch to a different model file. Closes the current chat session.
  /// After calling this, call [openChat] or [_validateModel] to load it.
  Future<void> setModelFile(String filePath) async {
    await closeChat();
    _customModelPath = filePath;
    _filename = filePath.split(RegExp(r'[/\\]')).last;
    // ignore: avoid_print
    print('📁 Model file changed to: $filePath');
  }

  /// Set the Gua generator for function calling.
  set guaGenerator(GuaGenerator? g) => _guaGenerator = g;

  /// Reset the "one Gua per conversation" guard (e.g. when starting a new chat).
  void resetGuaGuard() => _guaGenerated = false;

  // ---------------------------------------------------------------------------
  // Model config — Qwen3 0.6B
  // ---------------------------------------------------------------------------

  String _filename = 'Qwen3-0.6B.litertlm';
  String get _modelUrl => 'https://huggingface.co/litert-community/'
      'Qwen3-0.6B/resolve/main/Qwen3-0.6B.litertlm';

  Future<String> get _modelsDir async {
    final appDir = await getApplicationSupportDirectory();
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
    // ignore: avoid_print
    print('📥 Downloading model to: $targetPath');
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
    // Only copy to flutter_gemma path for default (downloaded) models.
    if (_customModelPath == null) {
      await _copyToFlutterGemmaPath(modelPath);
    }
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

    _guaGenerated = false; // fresh start
    _chat = await _model!.createChat(
      temperature: 0.8,
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

    // Proactive context compression: if we're near the token limit, summarize
    // before adding more context.
    if (_chat != null) {
      final limit = _chat!.maxTokens - _chat!.tokenBuffer;
      if (_chat!.currentTokens > limit - 200) {
        // ignore: avoid_print
        print('🧹 Proactive context compression triggered '
            '(${_chat!.currentTokens}/$limit tokens)');
        await _compressContext();
      }
    }

    await _chat!.addQuery(Message(text: message, isUser: true));

    while (responseText == null && maxTurns > 0) {
      maxTurns--;

      try {
        final response = await Future(() => _chat!.generateChatResponse())
            .timeout(_responseTimeout);

        if (response is TextResponse) {
          var text = response.token;
          // Strip thinking tags and end-of-text markers
          text = text.replaceAll(
              RegExp(r'<think>.*?</think>', dotAll: true), '');
          text = text.replaceAll(RegExp(r'<think>', dotAll: true), '');
          text = text.replaceAll(RegExp(r'</think>', dotAll: true), '');
          text = text.replaceAll('<|endoftext|>', '');
          text = text.replaceAll('<|endoftext|', '');

          // Some models describe the tool instead of calling it properly.
          // Detect tool call patterns in the text and handle them.
          final cleanText = text.replaceAll(RegExp(r'<tool_code>|</tool_code>'), '');
          final toolMatch = RegExp(
            r'generate_gua',
            caseSensitive: false,
          ).hasMatch(cleanText);

          if (toolMatch && _guaGenerator != null) {
            if (_guaGenerated) {
              // ignore: avoid_print
              print('🔮 Gua already generated — ignoring duplicate request');
              await _chat!.addQuery(
                Message.toolCall(text: '(A hexagram is already active. '
                    'Continue discussing it with the user.)'),
              );
            } else {
              // ignore: avoid_print
              print('🔮 LLM described a tool — generating Gua from text...');
              final result = await _guaGenerator!.generateRandom();
              // ignore: avoid_print
              print('🔮 Generated: ${result.gua.guaName} (code ${result.gua.guaCode})');
              _guaGenerated = true;
              final context = _guaGenerator!.formatContext(result);
              await _chat!.addQuery(Message.toolCall(text: '$context\n/no_think'));
            }
            // Don't set responseText — continue the loop
          } else {
            final trimmed = text.trim();
            if (trimmed.isEmpty) {
              // Model returned only thinking tags with no actual response.
              // Nudge it and retry (keep responseText null so loop continues).
              // ignore: avoid_print
              print('⚠️ Empty response after stripping — retrying...');
              await _chat!.addQuery(
                Message.toolCall(text: '(Please respond directly without thinking tags.)'),
              );
            } else {
              responseText = trimmed;
            }
          }
        } else if (response is FunctionCallResponse) {
          if (response.name == 'generate_gua' && _guaGenerator != null) {
            if (_guaGenerated) {
              // ignore: avoid_print
              print('🔮 Gua already generated — skipping duplicate call');
              await _chat!.addQuery(
                Message.toolCall(text: '(A hexagram is already active. '
                    'Continue discussing it with the user.)'),
              );
            } else {
              // ignore: avoid_print
              print('🔮 LLM requested a hexagram — generating Gua...');
              final result = await _guaGenerator!.generateRandom();
              // ignore: avoid_print
              print('🔮 Generated: ${result.gua.guaName} (code ${result.gua.guaCode})');
              _guaGenerated = true;
              final context = _guaGenerator!.formatContext(result);
              await _chat!.addQuery(Message.toolCall(text: '$context\n/no_think'));

              // The model may have included response text after the function call JSON.
              // Extract it by finding the closing brace and taking everything after.
              final toolCallEntry = _chat!.fullHistory.lastWhere(
                (m) => m.type == MessageType.toolCall,
                orElse: () => _chat!.fullHistory.last,
              );
              final jsonEnd = toolCallEntry.text.lastIndexOf('}');
              final trailing = jsonEnd >= 0
                  ? toolCallEntry.text.substring(jsonEnd + 1).trim()
                  : '';
              if (trailing.isNotEmpty &&
                  !trailing.startsWith('(')) {
                // ignore: avoid_print
                print('📝 Trailing text after function call: "${trailing.substring(0, trailing.length.clamp(0, 80))}"');
                await _chat!.addQuery(Message(text: trailing, isUser: false));
              }
            }
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

    // If all retries failed (still null or empty), restart the chat with
    // a summary context to avoid context-length issues.
    if (responseText == null || responseText!.isEmpty) {
      // ignore: avoid_print
      print('⚠️ All retries exhausted — restarting chat with truncated context...');
      try {
        // Collect all meaningful messages in chronological order.
        final history = _chat!.fullHistory;
        final meaningful = <String>[];
        for (final msg in history) {
          if (msg.type == MessageType.toolCall ||
              msg.type == MessageType.thinking ||
              msg.text.trim().isEmpty ||
              msg.text.trim() == '<think>' ||
              msg.text.trim() == '</think>' ||
              msg.text.contains('Please respond directly')) {
            continue;
          }
          final label = msg.isUser ? 'User' : 'Assistant';
          meaningful.add('$label: ${msg.text}');
        }
        final fullConversation = meaningful.join('\n\n');

        // Step 1: Ask the LLM to summarize the conversation in ~250 words.
        // A fresh session can often handle one large pass even if multi-turn couldn't.
        await closeChat();
        await openChat();

        String summaryText = '';
        await _chat!.addQuery(Message(
          text: 'Summarize the following I-Ching consultation conversation '
              'in about 250 words. Keep key topics, the hexagram cast (if any), '
              'and the user\'s core concerns.\n\n$fullConversation',
          isUser: true,
        ));

        try {
          final summaryResponse = await Future(
            () => _chat!.generateChatResponse(),
          ).timeout(_responseTimeout);
          if (summaryResponse is TextResponse) {
            var t = summaryResponse.token;
            t = t.replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), '');
            t = t.replaceAll(RegExp(r'<think>', dotAll: true), '');
            t = t.replaceAll(RegExp(r'</think>', dotAll: true), '');
            t = t.replaceAll('<|endoftext|>', '');
            t = t.replaceAll('<|endoftext|', '');
            summaryText = t.trim();
          }
        } catch (_) {
          // ignore — fall back to empty summary, the model will respond fresh
        }

        // Step 2: Restart again with the summary + original query.
        await closeChat();
        await openChat();

        if (summaryText.isNotEmpty) {
          await _chat!.addQuery(Message(
            text: '[Summary of our previous conversation]\n$summaryText',
            isUser: true,
          ));
        }
        // Send the original user message again.
        await _chat!.addQuery(Message(text: message, isUser: true));

        final response = await Future(() => _chat!.generateChatResponse())
            .timeout(_responseTimeout);
        if (response is TextResponse) {
          var text = response.token;
          text = text.replaceAll(
              RegExp(r'<think>.*?</think>', dotAll: true), '');
          text = text.replaceAll(RegExp(r'<think>', dotAll: true), '');
          text = text.replaceAll(RegExp(r'</think>', dotAll: true), '');
          text = text.replaceAll('<|endoftext|>', '');
          text = text.replaceAll('<|endoftext|', '');
          responseText = text.trim();
        }
      } catch (e) {
        // ignore: avoid_print
        print('⚠️ Chat restart also failed: $e');
        responseText = '(The conversation context has grown long. '
            'Let us start a fresh reflection. What is on your mind?)';
      }
    }

    return responseText ?? '(No response could be generated.)';
  }

  /// Summarize the conversation history and restart the chat with compressed context.
  /// Used both proactively (before overflow) and as a fallback (after retries exhausted).
  Future<void> _compressContext() async {
    // Collect all meaningful messages in chronological order.
    final history = _chat!.fullHistory;
    final meaningful = <String>[];
    for (final msg in history) {
      if (msg.type == MessageType.toolCall ||
          msg.type == MessageType.thinking ||
          msg.text.trim().isEmpty ||
          msg.text.trim() == '<think>' ||
          msg.text.trim() == '</think>' ||
          msg.text.contains('Please respond directly')) {
        continue;
      }
      final label = msg.isUser ? 'User' : 'Assistant';
      meaningful.add('$label: ${msg.text}');
    }
    final fullConversation = meaningful.join('\n\n');

    if (fullConversation.isEmpty) return;

    // Close and reopen fresh.
    await closeChat();
    await openChat();

    // Ask the LLM to summarize.
    String summaryText = '';
    await _chat!.addQuery(Message(
      text: 'Summarize the following I-Ching consultation conversation '
          'in about 250 words. Keep key topics, the hexagram cast (if any), '
          'and the user\'s core concerns.\n\n$fullConversation',
      isUser: true,
    ));

    try {
      final summaryResponse = await Future(
        () => _chat!.generateChatResponse(),
      ).timeout(_responseTimeout);
      if (summaryResponse is TextResponse) {
        var t = summaryResponse.token;
        t = t.replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), '');
        t = t.replaceAll(RegExp(r'<think>', dotAll: true), '');
        t = t.replaceAll(RegExp(r'</think>', dotAll: true), '');
        t = t.replaceAll('<|endoftext|>', '');
        t = t.replaceAll('<|endoftext|', '');
        summaryText = t.trim();
      }
    } catch (_) {
      // ignore — proceed with empty summary
    }

    // Restart fresh again and feed the summary as context.
    await closeChat();
    await openChat();

    if (summaryText.isNotEmpty) {
      await _chat!.addQuery(Message(
        text: '[Summary of our previous conversation]\n$summaryText',
        isUser: true,
      ));
    }
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
      'call generate_gua ONCE per conversation. After the hexagram is '
      'generated, discuss it with the user — do NOT cast another one. '
      'You will receive its details — use them to offer a thoughtful '
      'reflection.\n\n'
      'Guidelines:\n'
      '- Listen carefully to what the user shares about their situation.\n'
      '- If they mention a specific hexagram by name, call generate_gua.\n'
      '- Otherwise, ask if they would like a hexagram cast, or call '
      'generate_gua when you sense it would be helpful — but only once.\n'
      '- Once a hexagram is cast, discuss it with the user. Relate its '
      'wisdom to what they have shared.\n'
      '- NEVER predict good or bad fortune. Do NOT say "good luck" or '
      '"bad luck".\n'
      '- Instead, frame responses as invitations for reflection.\n'
      '- Ask open-ended questions that help the user explore their own '
      'feelings.\n'
      '- Be warm, supportive, and encouraging.\n'
      '- Keep responses concise (2-4 sentences).\n'
      '- Use gentle, poetic language when referencing I-Ching concepts.\n'
      '- If the user asks for another hexagram, gently remind them that '
      'the current one still holds wisdom for them.\n'
      '- Remember: the goal is emotional support and self-reflection, '
      'not divination.\n'
      '- Respond directly without using any XML or HTML tags.';
}
