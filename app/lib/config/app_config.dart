import 'package:flutter/foundation.dart';

/// Build-time configuration.
class AppConfig {
  AppConfig._();

  /// Whether the model-selection screen is shown instead of auto-selecting the
  /// default model.
  ///
  /// Defaults to `true` in debug builds (development) and `false` in release
  /// builds (production, which auto-downloads [ModelCatalog.defaultModel]).
  /// Override with `--dart-define=ALLOW_MODEL_SELECTION=true|false`.
  static const bool allowModelSelection =
      bool.fromEnvironment('ALLOW_MODEL_SELECTION', defaultValue: kDebugMode);

  /// Whether the app is running in production mode (release build without
  /// `--dart-define=ALLOW_MODEL_SELECTION=true`).
  ///
  /// In production the model path and the "remove model file" action are
  /// hidden and the system prompt is read-only (issue #17).
  static const bool isProduction = !allowModelSelection;
}
