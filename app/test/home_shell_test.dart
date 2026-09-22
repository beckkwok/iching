import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

import 'package:app/screens/home_shell.dart';
import 'package:app/screens/history_screen.dart';
import 'package:app/screens/profile_screen.dart';
import 'package:app/screens/question_form_screen.dart';

void main() {
  Widget app() => MaterialApp(
        builder: (context, child) => FTheme(
          data: FThemeData(touch: true, colors: FColors.neutralLight),
          child: child!,
        ),
        home: const HomeShell(databaseService: null),
      );

  testWidgets('shows the five bottom-nav destinations', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    for (final label in ['History', 'Profile', 'Ask', 'Browse', 'Preference']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('starts on the Ask tab', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.byType(QuestionFormScreen), findsOneWidget);
  });

  testWidgets('switching to History shows the History screen', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    expect(find.byType(HistoryScreen), findsOneWidget);
  });

  testWidgets('switching to Profile shows the Profile screen', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileScreen), findsOneWidget);
  });
}
