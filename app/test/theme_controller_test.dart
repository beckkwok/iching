import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/models/theme_preference.dart';
import 'package:app/theme/theme_controller.dart';

void main() {
  group('ThemeController', () {
    test('maps dark preference to ThemeMode.dark', () {
      expect(
        ThemeController(ThemePreference.dark).themeMode,
        ThemeMode.dark,
      );
    });

    test('maps light preference to ThemeMode.light', () {
      expect(
        ThemeController(ThemePreference.light).themeMode,
        ThemeMode.light,
      );
    });

    test('setPreference notifies listeners only on change', () {
      final controller = ThemeController(ThemePreference.dark);
      var notified = 0;
      controller.addListener(() => notified++);

      controller.setPreference(ThemePreference.dark); // no change
      expect(notified, 0);

      controller.setPreference(ThemePreference.light); // change
      expect(notified, 1);
      expect(controller.preference, ThemePreference.light);
      expect(controller.themeMode, ThemeMode.light);
    });
  });

  testWidgets('ThemeScope exposes its controller', (tester) async {
    final controller = ThemeController(ThemePreference.light);

    await tester.pumpWidget(
      ThemeScope(
        controller: controller,
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(builder: _buildFromScope),
        ),
      ),
    );

    expect(find.text('true'), findsOneWidget);
  });
}

Widget _buildFromScope(BuildContext context) {
  final fromScope = ThemeScope.maybeOf(context);
  return Text('${fromScope != null}');
}
