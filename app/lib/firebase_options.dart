import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

/// Placeholder Firebase options.
///
/// Run `flutterfire configure` in `app/` to generate the real options for your
/// Firebase project. Until then, initializing Firebase throws and the app
/// falls back to the local model.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'Firebase is not configured. Run `flutterfire configure` in app/.',
    );
  }
}
