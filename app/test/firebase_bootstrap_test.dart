import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/config/app_config.dart';
import 'package:app/services/firebase_bootstrap.dart';

void main() {
  test('Firebase is disabled by default', () {
    expect(AppConfig.firebaseEnabled, isFalse);
  });

  test('is not supported on Windows', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      expect(isFirebaseSupportedPlatform, isFalse);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  test('initializeFirebase returns false on unsupported platforms', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      expect(await initializeFirebase(), isFalse);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  test('initializeFirebase degrades gracefully when unconfigured', () async {
    // On the test platform (Android) the placeholder firebase_options throws;
    // initialization must be caught and reported as false.
    expect(defaultTargetPlatform, TargetPlatform.android);
    expect(await initializeFirebase(), isFalse);
  });
}
