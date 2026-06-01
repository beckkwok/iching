import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:app/main.dart';
import 'package:app/services/database_service.dart';

/// Shared app used for all UI-only widget tests.
/// Initialized once in setUpAll (outside the fake async zone).
MyApp? _sharedApp;

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    try {
      await deleteDatabase(inMemoryDatabasePath);
    } catch (_) {}
    final db = DatabaseService(databasePath: inMemoryDatabasePath);
    await db.database;
    _sharedApp = MyApp(databaseService: db);
  });

  tearDownAll(() async {
    if (_sharedApp != null) {
      await _sharedApp!.databaseService?.close();
      _sharedApp = null;
    }
  });

  testWidgets('shows welcome state with text field and send button',
      (tester) async {
    await tester.pumpWidget(_sharedApp!);

    expect(
      find.textContaining('Welcome. I am here to help you reflect.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Tell me what is on your mind.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.send), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('AppBar title is I-Ching before any message', (tester) async {
    await tester.pumpWidget(_sharedApp!);
    expect(find.text('I-Ching'), findsOneWidget);
  });

  testWidgets('typing shows text in the input field', (tester) async {
    await tester.pumpWidget(_sharedApp!);

    await tester.enterText(find.byType(TextField), 'Type test');
    expect(find.text('Type test'), findsOneWidget);
  });

  testWidgets('send button is tappable', (tester) async {
    await tester.pumpWidget(_sharedApp!);

    final sendButton = find.byIcon(Icons.send);
    expect(sendButton, findsOneWidget);
    await tester.tap(sendButton);
    await tester.pump();
    // No crash — button is tappable even if text is empty.
  });
}
