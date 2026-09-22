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
}
