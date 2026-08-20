import 'package:app/data/model_catalog.dart';
import 'package:app/models/language_preference.dart';
import 'package:app/services/gua_generator.dart';
import 'package:app/services/llm_service.dart';

/// A fake [LlmService] that returns deterministic responses without
/// requiring `flutter_gemma` or a real model file.
///
/// Use in tests where the LLM behaviour must be predictable.
class FakeLlmService extends LlmService {
  FakeLlmService() : super(modelInfo: ModelCatalog.all.first);

  @override
  bool get isReady => true;

  /// Canned explanation response for [generateExplanation].
  String explanationResponse =
      'The hexagram offers a gentle mirror for your '
      'question. Reflect on how its energy applies to what you carry.';

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
}
