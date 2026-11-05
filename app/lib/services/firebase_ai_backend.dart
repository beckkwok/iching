import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'package:app/config/app_config.dart';
import 'package:app/models/language_preference.dart';
import 'package:app/services/gua_generator.dart';
import 'package:app/services/llm_backend.dart';
import 'package:app/services/llm_prompts.dart';

/// A content generator so tests can avoid the network.
typedef FirebaseContentGenerator =
    Future<String?> Function({
      required String prompt,
      required String systemPrompt,
      required bool json,
    });

/// Remote LLM backend using Firebase AI Logic (Gemini) — issue #85.
///
/// The active backend is selected by [LlmService]; this class only implements
/// the one-shot explanation and memory-extraction calls.
class FirebaseAiBackend implements LlmBackend {
  final String model;
  final LlmPromptStrategy _prompts;
  final FirebaseContentGenerator? _generateContent;
  GuaGenerator _guaGenerator;
  String? _systemPrompt;

  FirebaseAiBackend({
    this.model = AppConfig.firebaseModel,
    GuaGenerator? guaGenerator,
    LlmPromptStrategy? promptStrategy,
    FirebaseContentGenerator? generateContent,
  }) : _guaGenerator = guaGenerator ?? GuaGenerator(),
       _prompts = promptStrategy ?? const DefaultLlmPromptStrategy(),
       _generateContent = generateContent;

  @override
  bool get isReady => Firebase.apps.isNotEmpty;

  @override
  String get systemPrompt => _systemPrompt ?? _prompts.defaultSystemPrompt;

  @override
  set systemPrompt(String value) => _systemPrompt = value;

  @override
  set guaGenerator(GuaGenerator? generator) =>
      _guaGenerator = generator ?? GuaGenerator();

  @override
  Future<String> generateExplanation({
    required String question,
    String? questionTypeLabel,
    required GenerationResult result,
    LanguagePreference language = LanguagePreference.english,
  }) async {
    final context = _guaGenerator.formatContext(result);
    final prompt = _prompts.explanationPrompt(
      question: question,
      questionTypeLabel: questionTypeLabel,
      hexagramContext: context,
      language: language,
    );

    try {
      final text = await _call(prompt, json: false);
      final cleaned = text == null ? '' : _prompts.cleanExplanation(text);
      if (cleaned.isNotEmpty) return cleaned;
    } catch (error) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('⚠️ Firebase AI explanation failed: $error');
      }
    }
    return '(The explanation could not be generated.)';
  }

  @override
  Future<MemoryExtraction?> extractMemory({
    required String question,
    required String hexagramName,
    required String explanation,
    String? comment,
    String? reaction,
    String? topicLabel,
  }) async {
    final prompt = _prompts.memoryPrompt(
      question: question,
      hexagramName: hexagramName,
      explanation: explanation,
      comment: comment,
      reaction: reaction,
      topicLabel: topicLabel,
    );

    try {
      final text = await _call(prompt, json: true);
      if (text == null) return null;
      return _prompts.parseMemory(_prompts.cleanExplanation(text));
    } catch (error) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('⚠️ Firebase AI memory extraction failed: $error');
      }
      return null;
    }
  }

  @override
  Future<void> close() async {}

  Future<String?> _call(String prompt, {required bool json}) {
    final generator = _generateContent;
    if (generator != null) {
      return generator(prompt: prompt, systemPrompt: systemPrompt, json: json);
    }
    return _generateWithFirebase(prompt, json: json);
  }

  Future<String?> _generateWithFirebase(
    String prompt, {
    required bool json,
  }) async {
    final generativeModel = FirebaseAI.googleAI().generativeModel(
      model: model,
      systemInstruction: Content.text(systemPrompt),
      generationConfig: GenerationConfig(
        maxOutputTokens: _maxOutputTokens,
        temperature: 0.7,
        responseMimeType: json ? 'application/json' : null,
      ),
    );
    final response = await generativeModel.generateContent([
      Content.text(prompt),
    ]);
    return response.text;
  }

  static const int _maxOutputTokens = 512;
}
