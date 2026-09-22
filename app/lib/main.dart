import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:forui/forui.dart';

import 'l10n/app_localizations.dart';
import 'l10n/locale_controller.dart';
import 'models/language_preference.dart';
import 'screens/model_selection_screen.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  runApp(
    MyApp(
      databaseService: db,
      localeController: LocaleController(language),
    ),
  );
}

class MyApp extends StatelessWidget {
  final DatabaseService? databaseService;
  final LocaleController localeController;

  const MyApp({
    super.key,
    required this.databaseService,
    required this.localeController,
  });

  @override
  Widget build(BuildContext context) {
    return LocaleScope(
      controller: localeController,
      child: ListenableBuilder(
        listenable: localeController,
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
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          // forui theme for the mobile widgets (bottom navigation, etc.).
          builder: (context, child) => FTheme(
            data: FThemeData(touch: true, colors: FColors.neutralLight),
            child: child!,
          ),
          home: ModelSelectionScreen(databaseService: databaseService),
        ),
      ),
    );
  }
}
