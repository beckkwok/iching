import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:forui/forui.dart';

import 'config/app_config.dart';
import 'data/model_catalog.dart';
import 'l10n/app_localizations.dart';
import 'l10n/locale_controller.dart';
import 'models/language_preference.dart';
import 'models/theme_preference.dart';
import 'screens/firebase_consent_screen.dart';
import 'screens/home_shell.dart';
import 'screens/model_selection_screen.dart';
import 'services/database_service.dart';
import 'services/firebase_ai_backend.dart';
import 'services/firebase_bootstrap.dart';
import 'services/gua_generator.dart';
import 'services/llm_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase AI Logic / App Check (issues #82/#84). Off until configured.
  if (AppConfig.firebaseEnabled) {
    await initializeFirebase();
  }

  // Attempt database initialisation across platforms. The database only
  // stores settings now; hexagrams are loaded from JSON assets.
  DatabaseService? db;
  try {
    db = await DatabaseService.create();
  } catch (e) {
    db = null;
  }

  // Seed the locale from the saved language preference (defaults to English).
  var language = LanguagePreference.english;
  if (db != null) {
    try {
      final code = await db.getSetting(LanguagePreference.settingsKey);
      language = LanguagePreference.fromCode(code);
    } catch (_) {
      // Fall back to the default language.
    }
  }

  // Seed the theme from the saved preference (defaults to dark).
  var theme = ThemePreference.dark;
  if (db != null) {
    try {
      final code = await db.getSetting(ThemePreference.settingsKey);
      theme = ThemePreference.fromCode(code);
    } catch (_) {
      // Fall back to the default theme.
    }
  }

  // Remote (Android) or local (desktop) edition (issue #86).
  LlmService? remoteLlm;
  if (AppConfig.useRemoteBackend) {
    remoteLlm = LlmService(
      modelInfo: ModelCatalog.defaultModel,
      backend: FirebaseAiBackend(),
    );
    remoteLlm.guaGenerator = GuaGenerator();
  }

  var consent = false;
  if (remoteLlm != null && db != null) {
    try {
      consent = await db.getSetting(AppConfig.firebaseConsentKey) == 'true';
    } catch (_) {
      consent = false;
    }
  }

  final Widget home;
  if (remoteLlm != null) {
    home = consent
        ? HomeShell(databaseService: db, llmService: remoteLlm)
        : FirebaseConsentScreen(databaseService: db, llmService: remoteLlm);
  } else {
    home = ModelSelectionScreen(databaseService: db);
  }

  runApp(
    MyApp(
      databaseService: db,
      localeController: LocaleController(language),
      themeController: ThemeController(theme),
      home: home,
    ),
  );
}

class MyApp extends StatelessWidget {
  final DatabaseService? databaseService;
  final LocaleController localeController;
  final ThemeController themeController;

  /// Optional startup screen. Defaults to the model-selection screen (local
  /// edition). The Android remote edition passes [HomeShell] or the consent
  /// screen.
  final Widget? home;

  const MyApp({
    super.key,
    required this.databaseService,
    required this.localeController,
    required this.themeController,
    this.home,
  });

  @override
  Widget build(BuildContext context) {
    return LocaleScope(
      controller: localeController,
      child: ThemeScope(
        controller: themeController,
        child: ListenableBuilder(
          listenable: Listenable.merge([localeController, themeController]),
          builder: (context, _) => MaterialApp(
            title: 'I-Ching',
            locale: localeController.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: buildLightTheme(),
            darkTheme: buildDarkTheme(),
            themeMode: themeController.themeMode,
            // forui theme for the mobile widgets (bottom navigation, etc.).
            builder: (context, child) => FTheme(
              data: buildForuiTheme(Theme.of(context).brightness),
              child: child!,
            ),
            home:
                home ?? ModelSelectionScreen(databaseService: databaseService),
          ),
        ),
      ),
    );
  }
}
