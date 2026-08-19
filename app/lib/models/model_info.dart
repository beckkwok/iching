import 'package:flutter_gemma/flutter_gemma.dart';

/// Metadata for an available LLM model that can be downloaded and used.
class ModelInfo {
  /// Unique key persisted in settings (e.g. "gemma4_e2b").
  final String key;

  /// Human-readable family name (e.g. "Gemma 4 E2B").
  final String modelFamily;

  /// Short description of what the model excels at.
  final String bestFor;

  /// Language support description (e.g. "Multilingual").
  final String language;

  /// Human-readable size (e.g. "2.4 GB").
  final String sizeLabel;

  /// flutter_gemma model type.
  final ModelType modelType;

  /// Whether the model supports thinking/reasoning mode.
  final bool isThinking;

  /// Full download URL from HuggingFace.
  final String downloadUrl;

  /// Local filename extracted from URL (e.g. "gemma-4-E2B-it.litertlm").
  final String filename;

  const ModelInfo({
    required this.key,
    required this.modelFamily,
    required this.bestFor,
    required this.language,
    required this.sizeLabel,
    required this.modelType,
    required this.isThinking,
    required this.downloadUrl,
    required this.filename,
  });
}
