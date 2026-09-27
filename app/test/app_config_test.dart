import 'package:flutter_test/flutter_test.dart';

import 'package:app/config/app_config.dart';

void main() {
  test('isProduction is the inverse of allowModelSelection', () {
    expect(AppConfig.isProduction, !AppConfig.allowModelSelection);
  });

  test('test builds are not production (debug by default)', () {
    expect(AppConfig.isProduction, isFalse);
  });
}
