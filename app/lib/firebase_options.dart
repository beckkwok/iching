import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase options loaded from build-time environment values.
///
/// Values come from a local, git-ignored file passed with
/// `--dart-define-from-file=firebase.local.json` (or individual
/// `--dart-define` flags / CI secrets). No API key is committed to the repo.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Firebase web is not configured.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'Firebase is only configured for Android in this project.',
        );
      default:
        throw UnsupportedError(
          'Firebase is not supported on ${defaultTargetPlatform.name}.',
        );
    }
  }

  static FirebaseOptions get _android {
    const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
    if (apiKey.isEmpty) {
      throw UnsupportedError(
        'Firebase is not configured. Pass '
        '--dart-define-from-file=firebase.local.json '
        '(see docs/firebase-setup.md).',
      );
    }
    return const FirebaseOptions(
      apiKey: apiKey,
      appId: String.fromEnvironment('FIREBASE_APP_ID'),
      messagingSenderId:
          String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
      projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
    );
  }
}
