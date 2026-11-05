import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

/// Initializes Firebase + App Check on supported platforms (issue #84).
///
/// Returns `true` when Firebase is ready. Failures are caught so the app can
/// still run: the Windows/Linux edition uses the local model and does not need
/// Firebase.
Future<bool> initializeFirebase() async {
  if (!isFirebaseSupportedPlatform) return false;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Optional fixed App Check debug token (useful for emulators/CI, where
    // each install would otherwise generate a new token).
    const debugToken = String.fromEnvironment('FIREBASE_APPCHECK_DEBUG_TOKEN');
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? AndroidDebugProvider(
              debugToken: debugToken.isEmpty ? null : debugToken,
            )
          : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? const AppleDebugProvider()
          : const AppleAppAttestProvider(),
    );
    return true;
  } catch (error) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('⚠️ Firebase initialization failed: $error');
    }
    return false;
  }
}

/// Platforms where Firebase AI Logic / App Check are wired up.
///
/// Windows/Linux stay local-only; web is excluded until a reCAPTCHA App Check
/// provider is configured.
bool get isFirebaseSupportedPlatform =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS);
