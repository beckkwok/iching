import 'package:flutter/material.dart';

import '../models/theme_preference.dart';

/// Holds the app's active theme mode and notifies listeners when it changes.
///
/// Created once in `main()` (seeded from the saved setting) and exposed to the
/// widget tree via [ThemeScope] so any screen can change the theme.
class ThemeController extends ChangeNotifier {
  ThemeController(this._preference);

  ThemePreference _preference;

  ThemePreference get preference => _preference;

  ThemeMode get themeMode =>
      _preference == ThemePreference.dark ? ThemeMode.dark : ThemeMode.light;

  void setPreference(ThemePreference value) {
    if (_preference == value) return;
    _preference = value;
    notifyListeners();
  }
}

/// Exposes the [ThemeController] to descendants.
class ThemeScope extends InheritedNotifier<ThemeController> {
  const ThemeScope({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  /// The controller, or `null` when no [ThemeScope] is present (e.g. in
  /// isolated widget tests).
  static ThemeController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ThemeScope>()?.notifier;
}
