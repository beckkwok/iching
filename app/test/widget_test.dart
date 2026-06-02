import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:app/main.dart';
import 'package:app/services/database_service.dart';

/// Shared app used for all UI-only widget tests.
MyApp? _sharedApp;

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final db = DatabaseService(databasePath: ':memory:');
    await db.database;
    _sharedApp = MyApp(databaseService: db);
  });

  tearDownAll(() async {
    if (_sharedApp != null) {
      await _sharedApp!.databaseService?.close();
      _sharedApp = null;
    }
  });

  testWidgets('shows model download screen on startup', (tester) async {
    await tester.pumpWidget(_sharedApp!);

    // Should show the initialising state or the setup screen.
    // FlutterGemma.initialize() might fail in test environment,
    // but the screen should still render.
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('AppBar title shows I-Ching Setup', (tester) async {
    await tester.pumpWidget(_sharedApp!);

    expect(find.text('I-Ching Setup'), findsOneWidget);
  });
}
