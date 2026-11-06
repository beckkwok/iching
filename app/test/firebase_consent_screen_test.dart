import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

import 'package:app/config/app_config.dart';
import 'package:app/models/agent_memory.dart';
import 'package:app/models/consultation.dart';
import 'package:app/screens/firebase_consent_screen.dart';
import 'package:app/screens/home_shell.dart';
import 'package:app/services/database_service.dart';
import 'package:app/theme/app_theme.dart';

/// Settings-only DB stand-in (no sqflite-ffi I/O in widget tests).
class _FakeDb extends DatabaseService {
  _FakeDb() : super(databasePath: ':memory:');

  final Map<String, String> settings = {};

  @override
  Future<String?> getSetting(String key) async => settings[key];

  @override
  Future<void> setSetting(String key, String? value) async {
    if (value == null) {
      settings.remove(key);
    } else {
      settings[key] = value;
    }
  }

  @override
  Future<AgentMemory?> getAgentMemory() async => null;

  @override
  Future<List<Consultation>> getConsultations() async => const [];
}

void main() {
  testWidgets('accepting consent persists it and opens the home shell', (
    tester,
  ) async {
    final db = _FakeDb();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        builder: (context, child) =>
            FTheme(data: buildForuiTheme(Brightness.light), child: child!),
        home: FirebaseConsentScreen(databaseService: db),
      ),
    );

    expect(find.text('Before we begin'), findsOneWidget);

    await tester.tap(find.text('Agree & continue'));
    await tester.pumpAndSettle();

    expect(db.settings[AppConfig.firebaseConsentKey], 'true');
    expect(find.byType(HomeShell), findsOneWidget);
  });
}
