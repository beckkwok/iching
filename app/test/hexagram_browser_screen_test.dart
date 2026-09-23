import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:app/screens/hexagram_browser_screen.dart';
import 'package:app/screens/hexagram_detail_screen.dart';
import 'package:app/services/database_service.dart';
import 'package:app/services/hexagram_loader.dart';

/// Minimal valid hexagram JSON for [code].
String fixtureJson(int code) {
  final names = {
    1: '乾為天',
    2: '坤為地',
    64: '未濟',
  };
  return '''
  {
    "卦名": "${names[code] ?? '卦$code'}",
    "卦序": $code,
    "卦象": "䷀（下乾上乾）",
    "卦辭": "卦辭 $code",
    "彖傳": "彖傳 $code",
    "大象傳": "大象傳 $code",
    "爻辭": [],
    "象徵意義": {
      "基本卦象": {"卦體": "下乾上乾", "自然取象": "天", "說明": "說明"},
      "主要象徵": [],
      "生活與占事常見象徵": {},
      "總結": "總結 $code"
    },
    "不同人解讀": [],
    "備註": ""
  }
  ''';
}

/// In-memory [DatabaseService] stand-in for the last-visited persistence,
/// avoiding the real sqflite-ffi DB (which deadlocks in widget-test initState).
class _FakeDb extends DatabaseService {
  _FakeDb({Map<String, String>? settings})
      : _settings = {...?settings},
        super(databasePath: ':memory:');

  final Map<String, String> _settings;

  @override
  Future<String?> getSetting(String key) async => _settings[key];

  @override
  Future<void> setSetting(String key, String? value) async {
    if (value == null) {
      _settings.remove(key);
    } else {
      _settings[key] = value;
    }
  }
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DatabaseService db;

  setUp(() async {
    try {
      await deleteDatabase(inMemoryDatabasePath);
    } catch (_) {}
    db = DatabaseService(databasePath: inMemoryDatabasePath);
    await db.database;
  });

  tearDown(() async {
    await db.close();
    try {
      await deleteDatabase(inMemoryDatabasePath);
    } catch (_) {}
  });

  final loader = HexagramLoader((code) async => fixtureJson(code));

  testWidgets('browser shows a fill-column grid of hexagram cards',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: HexagramBrowserScreen(loader: loader)),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Grid (the header bar was removed in the mobile redesign).
    expect(find.byType(GridView), findsOneWidget);

    // Verify the grid fills width via max-cross-axis-extent.
    final grid = tester.widget<GridView>(find.byType(GridView));
    expect(
      grid.gridDelegate,
      isA<SliverGridDelegateWithMaxCrossAxisExtent>(),
    );

    // First card shows 卦序 + 卦名
    expect(find.text('Hexagram 1'), findsOneWidget);
    expect(find.text('乾為天'), findsOneWidget);
    expect(find.textContaining('下乾上乾'), findsWidgets);
  });

  testWidgets('browser lists all 64 hexagrams (scrollable)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: HexagramBrowserScreen(loader: loader)),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Scroll to the last hexagram (64) to confirm it's reachable.
    await tester.scrollUntilVisible(
      find.text('未濟'),
      400,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Hexagram 64'), findsOneWidget);
    expect(find.text('未濟'), findsOneWidget);
  });

  testWidgets('tapping a hexagram card opens the detail screen',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: HexagramBrowserScreen(loader: loader)),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('乾為天'));
    await tester.pumpAndSettle();

    expect(find.byType(HexagramDetailScreen), findsOneWidget);
    expect(find.text('Hexagram 1'), findsOneWidget);
  });

  testWidgets('shows the last visited hexagram in the header', (tester) async {
    final db = _FakeDb(settings: {lastVisitedGuaSettingsKey: '1'});
    await tester.pumpWidget(
      MaterialApp(
        home: HexagramBrowserScreen(loader: loader, databaseService: db),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Last visited'), findsOneWidget);
    // The header shows the name once, plus the grid card.
    expect(find.text('乾為天'), findsNWidgets(2));
  });

  testWidgets('tapping a hexagram records it as the last visited',
      (tester) async {
    final db = _FakeDb();
    await tester.pumpWidget(
      MaterialApp(
        home: HexagramBrowserScreen(loader: loader, databaseService: db),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('乾為天'));
    await tester.pumpAndSettle();

    expect(await db.getSetting(lastVisitedGuaSettingsKey), '1');
  });

}
