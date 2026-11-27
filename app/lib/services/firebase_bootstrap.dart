import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

/// Whether to use the App Check debug provider.
///
/// True in debug builds, or when a sideloaded release build opts in with
/// `--dart-define=APP_CHECK_DEBUG=true`. Play-distributed release builds
/// should leave the flag off and use Play Integrity.
bool useAppCheckDebugProvider({required bool isDebugMode}) {
  const forceDebug = bool.fromEnvironment('APP_CHECK_DEBUG');
  return isDebugMode || forceDebug;
}

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
    //
    // Sideloaded release builds are not Play-distributed, so Play Integrity
    // cannot attest them. `APP_CHECK_DEBUG=true` lets a locally-built release
    // APK use the debug provider; remove it for Play Store builds.
    const debugToken = String.fromEnvironment('FIREBASE_APPCHECK_DEBUG_TOKEN');
    final useDebugProvider = useAppCheckDebugProvider(isDebugMode: kDebugMode);
    await FirebaseAppCheck.instance.activate(
      providerAndroid: useDebugProvider
          ? AndroidDebugProvider(
              debugToken: debugToken.isEmpty ? null : debugToken,
            )
          : const AndroidPlayIntegrityProvider(),
      providerApple: useDebugProvider
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
