import 'package:flutter/material.dart';

import '../models/language_preference.dart';

/// Holds the app's active language and notifies listeners when it changes.
///
/// Created once in `main()` (seeded from the saved setting) and exposed to the
/// widget tree via [LocaleScope] so any screen can change the language.
class LocaleController extends ChangeNotifier {
  LocaleController(this._language);

  LanguagePreference _language;

  LanguagePreference get language => _language;

  Locale get locale => _language == LanguagePreference.chinese
      ? const Locale('zh')
      : const Locale('en');

  void setLanguage(LanguagePreference value) {
    if (_language == value) return;
    _language = value;
    notifyListeners();
  }
}

/// Exposes the [LocaleController] to descendants.
class LocaleScope extends InheritedNotifier<LocaleController> {
  const LocaleScope({
    super.key,
    required LocaleController controller,
    required super.child,
  }) : super(notifier: controller);

  /// The controller, or `null` when no [LocaleScope] is present (e.g. in
  /// isolated widget tests).
  static LocaleController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LocaleScope>()?.notifier;
}
