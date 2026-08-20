import 'package:app/models/model_info.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

/// Static catalog of all available models users can download and run.
///
/// All models use `.litertlm` format. Add new models here as they become
/// available in the flutter_gemma ecosystem.
class ModelCatalog {
  ModelCatalog._();

  static const List<ModelInfo> all = [
    ModelInfo(
      key: 'gemma4_e2b',
      modelFamily: 'Gemma 4 E2B',
      bestFor: 'Next-gen multimodal chat — text, image, audio',
      language: 'Multilingual',
      sizeLabel: '2.4 GB',
      modelType: ModelType.gemma4,
      isThinking: true,
      downloadUrl:
          'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm'
          '/resolve/main/gemma-4-E2B-it.litertlm?download=true',
      filename: 'gemma-4-E2B-it.litertlm',
    ),
    ModelInfo(
      key: 'gemma4_e4b',
      modelFamily: 'Gemma 4 E4B',
      bestFor: 'Next-gen multimodal chat — text, image, audio',
      language: 'Multilingual',
      sizeLabel: '3.6 GB',
      modelType: ModelType.gemma4,
      isThinking: true,
      downloadUrl:
          'https://huggingface.co/litert-community/gemma-4-E4B-it-litert-lm'
          '/resolve/main/gemma-4-E4B-it.litertlm?download=true',
      filename: 'gemma-4-E4B-it.litertlm',
    ),
    ModelInfo(
      key: 'deepseek_r1',
      modelFamily: 'DeepSeek R1',
      bestFor: 'High-performance reasoning and code generation',
      language: 'Multilingual',
      sizeLabel: '1.7 GB',
      modelType: ModelType.deepSeek,
      isThinking: true,
      downloadUrl:
          'https://huggingface.co/litert-community/DeepSeek-R1-Distill-Qwen-1.5B'
          '/resolve/main/DeepSeek-R1-Distill-Qwen-1.5B_multi-prefill-seq_q8_ekv4096.litertlm'
          '?download=true',
      filename:
          'DeepSeek-R1-Distill-Qwen-1.5B_multi-prefill-seq_q8_ekv4096.litertlm',
    ),
    ModelInfo(
      key: 'gemma3_1b',
      modelFamily: 'Gemma 3 1B',
      bestFor: 'Balanced and efficient text generation',
      language: 'Multilingual',
      sizeLabel: '0.5 GB',
      modelType: ModelType.gemmaIt,
      isThinking: true,
      downloadUrl:
          'https://huggingface.co/litert-community/Gemma3-1B-IT'
          '/resolve/main/gemma3-1b-it-int4.litertlm?download=true',
      filename: 'gemma3-1b-it-int4.litertlm',
    ),
    ModelInfo(
      key: 'qwen2_5',
      modelFamily: 'Qwen2.5',
      bestFor: 'Strong multilingual chat and instruction following',
      language: 'Multilingual',
      sizeLabel: '1.6 GB',
      modelType: ModelType.qwen,
      isThinking: true,
      downloadUrl:
          'https://huggingface.co/litert-community/Qwen2.5-1.5B-Instruct'
          '/resolve/main/Qwen2.5-1.5B-Instruct_multi-prefill-seq_q8_ekv4096.litertlm'
          '?download=true',
      filename:
          'Qwen2.5-1.5B-Instruct_multi-prefill-seq_q8_ekv4096.litertlm',
    ),
    ModelInfo(
      key: 'qwen3',
      modelFamily: 'Qwen3',
      bestFor: 'Compact multilingual chat with function calling',
      language: 'Multilingual',
      sizeLabel: '0.6 GB',
      modelType: ModelType.qwen3,
      isThinking: true,
      downloadUrl:
          'https://huggingface.co/litert-community/Qwen3-0.6B'
          '/resolve/main/Qwen3-0.6B.litertlm?download=true',
      filename: 'Qwen3-0.6B.litertlm',
    ),
  ];

  /// Look up a model by its [key].
  static ModelInfo? byKey(String key) {
    for (final m in all) {
      if (m.key == key) return m;
    }
    return null;
  }
}
