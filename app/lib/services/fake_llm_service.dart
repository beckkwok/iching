import 'package:app/data/model_catalog.dart';
import 'package:app/models/gua.dart';
import 'package:app/models/language_preference.dart';
import 'package:app/services/gua_generator.dart';
import 'package:app/services/llm_service.dart';

/// A fake [LlmService] that returns deterministic responses without
/// requiring `flutter_gemma` or a real model file.
///
/// Use in integration tests where the LLM behaviour must be predictable.
class FakeLlmService extends LlmService {
  FakeLlmService() : super(modelInfo: ModelCatalog.all.first);
  Gua? _nextGua;

  /// Called after [sendMessage] — use this to assert the LLM was invoked.
  int sendCount = 0;

  /// The canned response returned by [sendMessage].
  String cannedResponse =
      'Thank you for sharing. Take a moment to reflect on what '
      'this situation reveals about your path.';

  /// The canned response with extra text that includes a gua hint.
  String cannedResponseWithGua =
      'The hexagram of creativity and strength has appeared. '
      'Consider how its energy applies to your situation.';

  /// Configure the next call to [consumeGeneratedGua] to return [gua].
  void willProduceGua(Gua gua) => _nextGua = gua;

  @override
  bool get isReady => true;

  /// Canned explanation response for [generateExplanation].
  String explanationResponse =
      'The hexagram offers a gentle mirror for your '
      'question. Reflect on how its energy applies to what you carry.';

  @override
  Future<String> sendMessage(String message) async {
    sendCount++;
    await Future.delayed(const Duration(milliseconds: 50));
    return _nextGua != null ? cannedResponseWithGua : cannedResponse;
  }

  @override
  Future<String> generateExplanation({
    required String question,
    String? questionTypeLabel,
    required GenerationResult result,
    LanguagePreference language = LanguagePreference.english,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));
    if (language == LanguagePreference.chinese) {
      return '此卦為您的問題提供一面溫柔的鏡子，請反思其能量如何應用於您所背負的事物。';
    }
    return explanationResponse;
  }

  @override
  Gua? consumeGeneratedGua() {
    final gua = _nextGua;
    _nextGua = null;
    return gua;
  }
}
