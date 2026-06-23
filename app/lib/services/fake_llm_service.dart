import 'package:app/models/gua.dart';
import 'package:app/services/llm_service.dart';

/// A fake [LlmService] that returns deterministic responses without
/// requiring `flutter_gemma` or a real model file.
///
/// Use in integration tests where the LLM behaviour must be predictable.
class FakeLlmService extends LlmService {
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

  @override
  Future<String> sendMessage(String message) async {
    sendCount++;
    await Future.delayed(const Duration(milliseconds: 50));
    return _nextGua != null ? cannedResponseWithGua : cannedResponse;
  }

  @override
  Gua? consumeGeneratedGua() {
    final gua = _nextGua;
    _nextGua = null;
    return gua;
  }
}
