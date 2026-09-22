import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:app/data/model_catalog.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/models/model_info.dart';
import 'package:app/screens/home_shell.dart';
import 'package:app/screens/model_selection_screen.dart';
import 'package:app/services/database_service.dart';
import 'package:app/services/llm_service.dart';

/// A [MaterialApp] wrapped in an [FTheme] so forui widgets (the bottom nav in
/// [HomeShell]) can render.
Widget _app(Widget home) => MaterialApp(
      builder: (context, child) => FTheme(
        data: FThemeData(touch: true, colors: FColors.neutralLight),
        child: child!,
      ),
      home: home,
    );

/// Fake platform directory provider so the screen's model-file check runs
/// against an empty temp directory instead of the real app support dir.
class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProvider(this.root);

  final String root;

  @override
  Future<String?> getApplicationSupportPath() async => root;
}

/// In-memory [DatabaseService] stand-in. The screen only reads/writes settings,
/// so overriding those avoids touching the real sqflite-ffi DB (which deadlocks
/// when called from `initState` under the widget-test fake async).
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

/// A [DatabaseService] whose settings read always throws, so the screen's
/// startup error path can be exercised.
class _ThrowingDatabaseService extends DatabaseService {
  _ThrowingDatabaseService() : super(databasePath: ':memory:');

  @override
  Future<String?> getSetting(String key) async {
    throw StateError('boom');
  }
}

/// A [LlmService] that records the calls made by the startup flow, so the
/// embedded/auto-download path can be tested without `flutter_gemma`.
class _FakeLlmService extends LlmService {
  _FakeLlmService(ModelInfo modelInfo) : super(modelInfo: modelInfo);

  int initializeCalls = 0;
  int downloadCalls = 0;
  int openChatCalls = 0;

  @override
  Future<void> initialize({String? huggingFaceToken}) async {
    initializeCalls++;
  }

  @override
  Future<void> downloadModel({
    String? token,
    void Function(double progress)? onProgress,
  }) async {
    downloadCalls++;
    onProgress?.call(1.0);
  }

  @override
  Future<void> openExplanationChat() async {
    openChatCalls++;
  }

  @override
  bool get isReady => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('iching_model_test');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
  });

  tearDown(() async {
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  /// Pump the screen and let the real async startup (settings read + file
  /// existence check) complete. A plain `pumpAndSettle` would hang on the
  /// initialising spinner.
  Future<void> settleStartup(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('shows the setup title', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: ModelSelectionScreen(databaseService: _FakeDatabaseService())),
    );

    expect(find.text('I-Ching Setup'), findsOneWidget);

    await settleStartup(tester);
  });

  testWidgets('shows the selection grid when no model is installed',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: ModelSelectionScreen(databaseService: _FakeDatabaseService())),
    );
    await settleStartup(tester);

    expect(find.text('Choose Your Model'), findsOneWidget);
    expect(
      find.text('All models run fully offline on your device.'),
      findsOneWidget,
    );

    // Every catalog model is rendered with its family name and size.
    for (final model in ModelCatalog.all) {
      expect(find.text(model.modelFamily), findsOneWidget);
      expect(find.text(model.sizeLabel), findsOneWidget);
    }
  });

  testWidgets('tapping a model card opens the confirmation dialog',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: ModelSelectionScreen(databaseService: _FakeDatabaseService())),
    );
    await settleStartup(tester);

    await tester.ensureVisible(find.text('Gemma 3 1B'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gemma 3 1B'));
    await tester.pumpAndSettle();

    expect(find.text('Download Gemma 3 1B?'), findsOneWidget);
    expect(
      find.textContaining('This will download the Gemma 3 1B model (0.5 GB).'),
      findsOneWidget,
    );
    expect(
      find.textContaining('the model choice cannot be changed later'),
      findsOneWidget,
    );
    expect(find.text('Confirm & Download'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('cancelling the dialog returns to the selection grid',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: ModelSelectionScreen(databaseService: _FakeDatabaseService())),
    );
    await settleStartup(tester);

    // The last model card is below the fold — scroll it into view first.
    await tester.ensureVisible(find.text('Qwen3'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Qwen3'));
    await tester.pumpAndSettle();
    expect(find.text('Download Qwen3?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Download Qwen3?'), findsNothing);
    expect(find.text('Choose Your Model'), findsOneWidget);
  });

  testWidgets('shows the error view when startup fails', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: ModelSelectionScreen(databaseService: _ThrowingDatabaseService())),
    );
    await settleStartup(tester);

    expect(find.text('Startup failed'), findsOneWidget);
    expect(find.textContaining('boom'), findsOneWidget);
    expect(find.text('Continue anyway'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('"Continue anyway" opens the app shell', (tester) async {
    await tester.pumpWidget(
      _app(ModelSelectionScreen(databaseService: _ThrowingDatabaseService())),
    );
    await settleStartup(tester);

    await tester.tap(find.text('Continue anyway'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeShell), findsOneWidget);
  });

  testWidgets('shows the Chinese setup title when the locale is zh',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: ModelSelectionScreen(databaseService: _FakeDatabaseService()),
      ),
    );
    await settleStartup(tester);

    expect(find.text('易經設定'), findsOneWidget);
    expect(find.text('I-Ching Setup'), findsNothing);
  });

  testWidgets('production auto-downloads the default model', (tester) async {
    final db = _FakeDatabaseService();
    _FakeLlmService? created;

    await tester.pumpWidget(
      _app(
        ModelSelectionScreen(
          databaseService: db,
          allowSelection: false,
          llmServiceFactory: (model) => created = _FakeLlmService(model),
        ),
      ),
    );
    await settleStartup(tester);
    await tester.pumpAndSettle();

    expect(created, isNotNull);
    expect(created!.modelInfo.key, ModelCatalog.defaultModelKey);
    expect(created!.downloadCalls, 1);
    expect(created!.openChatCalls, 1);
    expect(
      await db.getSetting('selected_model_key'),
      ModelCatalog.defaultModelKey,
    );
    expect(find.byType(HomeShell), findsOneWidget);
  });

  testWidgets('production loads an installed model without downloading',
      (tester) async {
    // The default model file already exists on disk.
    await tester.runAsync(() async {
      final modelsDir = Directory(p.join(tempDir.path, 'models'));
      await modelsDir.create(recursive: true);
      await File(p.join(modelsDir.path, 'Qwen3-0.6B.litertlm'))
          .writeAsBytes([0]);
    });

    final db = _FakeDatabaseService(
      settings: {'selected_model_key': ModelCatalog.defaultModelKey},
    );
    _FakeLlmService? created;

    await tester.pumpWidget(
      _app(
        ModelSelectionScreen(
          databaseService: db,
          allowSelection: false,
          llmServiceFactory: (model) => created = _FakeLlmService(model),
        ),
      ),
    );
    await settleStartup(tester);
    await tester.pumpAndSettle();

    expect(created, isNotNull);
    expect(created!.downloadCalls, 0);
    expect(created!.openChatCalls, 1);
    expect(find.byType(HomeShell), findsOneWidget);
  });
}
