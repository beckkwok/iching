import 'package:flutter_test/flutter_test.dart';

import 'package:app/config/app_config.dart';

void main() {
  test('isProduction is the inverse of allowModelSelection', () {
    expect(AppConfig.isProduction, !AppConfig.allowModelSelection);
  });

  test('test builds are not production (debug by default)', () {
    expect(AppConfig.isProduction, isFalse);
  });

  test('Android is the remote platform; desktop is local', () {
    expect(AppConfig.isAndroidPlatform, isTrue);
    expect(AppConfig.isDesktopLocal, isFalse);
    // Android defaults to the remote edition (Firebase enabled).
    expect(AppConfig.firebaseEnabled, isTrue);
    expect(AppConfig.useRemoteBackend, isTrue);
  });
}
