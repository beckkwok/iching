import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:app/models/question_type.dart';
import 'package:app/screens/cast_result_screen.dart';
import 'package:app/screens/explanation_screen.dart';
import 'package:app/screens/question_form_screen.dart';
import 'package:app/services/database_service.dart';
import 'package:app/services/fake_llm_service.dart';
import 'package:app/services/gua_generator.dart';
import 'package:app/services/hexagram_loader.dart';

/// In-memory [DatabaseService] stand-in (settings only) to avoid opening the
/// real sqflite-ffi DB inside widget tests.
class _FakeDatabaseService extends DatabaseService {
  _FakeDatabaseService({Map<String, String>? settings})
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

/// Minimal valid hexagram JSON for [code].
String _fixtureJson(int code) => '''
{
  "卦名": "卦$code",
  "卦序": $code,
  "卦象": "䷀（下乾上乾）",
  "卦辭": "卦辭 $code",
  "彖傳": "",
  "大象傳": "",
  "爻辭": [],
  "象徵意義": {"基本卦象": {}, "主要象徵": [], "生活與占事常見象徵": {}, "總結": ""},
  "不同人解讀": [],
  "備註": ""
}
''';

/// [HttpOverrides] that records and blocks every HTTP request, proving the
/// app makes no network calls during normal use.
class _BlockingHttpOverrides extends HttpOverrides {
  final List<Uri> requests = [];

  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      _BlockingHttpClient(this);
}

class _BlockingHttpClient implements HttpClient {
  _BlockingHttpClient(this._overrides);

  final _BlockingHttpOverrides _overrides;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #openUrl) {
      final url = invocation.positionalArguments[1] as Uri;
      _overrides.requests.add(url);
      return Future<HttpClientRequest>.error(
        StateError('Blocked network request to $url'),
      );
    }
    return super.noSuchMethod(invocation);
  }
}

Directory _packageRoot() {
  var dir = Directory.current;
  while (true) {
    if (File(p.join(dir.path, 'pubspec.yaml')).existsSync()) return dir;
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('Could not locate package root from ${dir.path}');
    }
    dir = parent;
  }
}

void main() {
  group('static guard: no network APIs outside the model download', () {
    // The only file allowed to reference networking (the explicit, user-
    // initiated model download).
    final allowed = {p.join('lib', 'services', 'llm_service.dart')};

    final patterns = <String, RegExp>{
      'package:http': RegExp(r'package:http/'),
      'HttpClient': RegExp(r'\bHttpClient\b'),
      'WebSocket': RegExp(r'\bWebSocket\b'),
      'RawDatagramSocket': RegExp(r'\bRawDatagramSocket\b'),
      'Socket': RegExp(r'\bSocket\b'),
      'HttpOverrides': RegExp(r'\bHttpOverrides\b'),
      'NetworkImage': RegExp(r'\bNetworkImage\b'),
      'Image.network': RegExp(r'\bImage\.network\b'),
    };

    test('lib/ uses no network APIs outside the model download', () {
      final root = _packageRoot();
      final libDir = Directory(p.join(root.path, 'lib'));
      expect(libDir.existsSync(), isTrue, reason: 'lib/ not found');

      final offenders = <String>[];
      for (final file in libDir.listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.dart')) continue;
        final rel = p.relative(file.path, from: root.path);
        if (allowed.contains(rel)) continue;
        final source = file.readAsStringSync();
        patterns.forEach((label, pattern) {
          if (pattern.hasMatch(source)) offenders.add('$rel -> $label');
        });
      }

      expect(
        offenders,
        isEmpty,
        reason: 'Network APIs must only be used for the model download '
            '(lib/services/llm_service.dart):\n${offenders.join('\n')}',
      );
    });
  });

  group('runtime guard: no network during normal use', () {
    test('the guard blocks direct HTTP requests', () async {
      final overrides = _BlockingHttpOverrides();
      final previous = HttpOverrides.current;
      HttpOverrides.global = overrides;
      addTearDown(() => HttpOverrides.global = previous);

      final uri = Uri.parse('https://example.com/telemetry');
      await expectLater(
        HttpClient().openUrl('GET', uri),
        throwsA(isA<StateError>()),
      );
      expect(overrides.requests, contains(uri));
    });

    testWidgets('the consultation flow makes no network requests',
        (tester) async {
      final overrides = _BlockingHttpOverrides();
      final previous = HttpOverrides.current;
      HttpOverrides.global = overrides;
      addTearDown(() => HttpOverrides.global = previous);

      final generator =
          GuaGenerator(HexagramLoader((code) async => _fixtureJson(code)));
      final llm = FakeLlmService();

      await tester.pumpWidget(
        MaterialApp(
          home: QuestionFormScreen(
            databaseService: _FakeDatabaseService(),
            llmService: llm,
            guaGenerator: generator,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Fill and submit the question form.
      await tester.tap(find.byType(DropdownButtonFormField<QuestionType>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Career Achievement').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField),
        'Should I take the new job?',
      );
      await tester.tap(find.text('Submit Question'));

      // Let the async cast complete.
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        });
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(CastResultScreen), findsOneWidget);

      // Generate the one-shot explanation.
      await tester.scrollUntilVisible(
        find.text('Get Explanation'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Get Explanation'));
      await tester.pumpAndSettle();
      expect(find.byType(ExplanationScreen), findsOneWidget);

      expect(
        overrides.requests,
        isEmpty,
        reason: 'The consultation flow must not touch the network.',
      );
    });
  });
}
