import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/screens/firebase_config_error_screen.dart';
import 'package:app/theme/app_theme.dart';

void main() {
  testWidgets('shows the missing Firebase config guidance', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: const FirebaseConfigErrorScreen(),
      ),
    );

    expect(find.text('Firebase is not configured'), findsOneWidget);
    expect(find.textContaining('firebase.local.json'), findsOneWidget);
  });
}
