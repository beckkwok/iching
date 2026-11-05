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
  static const bool allowModelSelection = bool.fromEnvironment(
    'ALLOW_MODEL_SELECTION',
    defaultValue: kDebugMode,
  );

  /// Whether the app is running in production mode (release build without
  /// `--dart-define=ALLOW_MODEL_SELECTION=true`).
  ///
  /// In production the model path and the "remove model file" action are
  /// hidden and the system prompt is read-only (issue #17).
  static const bool isProduction = !allowModelSelection;

  /// Whether the interpreter picker is shown (issue #22).
  ///
  /// Disabled by default and only enabled on the Windows build. Override with
  /// `--dart-define=ENABLE_INTERPRETER_SELECTION=true|false`.
  static bool get interpreterSelectionEnabled {
    const override = String.fromEnvironment('ENABLE_INTERPRETER_SELECTION');
    if (override == 'true') return true;
    if (override == 'false') return false;
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
  }

  /// Whether to initialize Firebase (issues #82/#84).
  ///
  /// Off until the Firebase project has been configured with
  /// `flutterfire configure`. Enable with
  /// `--dart-define=FIREBASE_ENABLED=true`.
  static const bool firebaseEnabled = bool.fromEnvironment(
    'FIREBASE_ENABLED',
    defaultValue: false,
  );

  /// The Gemini model used by the remote backend (issue #85).
  ///
  /// Override with `--dart-define=FIREBASE_AI_MODEL=...`.
  static const String firebaseModel = String.fromEnvironment(
    'FIREBASE_AI_MODEL',
    defaultValue: 'gemini-3.8-flash',
  );
}
