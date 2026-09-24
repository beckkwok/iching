# Change Log 2026-09-24

## Task: Dark mode toggle (issue #30, part of #28)

Add a light/dark theme toggle. The app defaults to dark. The Material dark
theme is seeded from deep purple `#673AB7`, and the forui widgets switch to
`FColors.neutralDark` in dark mode.

### Prompt / intent
- Optional light/dark toggle (default dark), persisted in the settings table.
- Purple `#673AB7` (deep purple) used for the dark Material scheme.
- Follow-ups logged separately: purple gradient buttons (#31) and the
  twinkling-star background on the Ask screen (#32).

### Changes
- `lib/models/theme_preference.dart` (new): `ThemePreference` enum (dark/light)
  with `settingsKey` (`theme_mode`) and `fromCode` (defaults to dark).
- `lib/theme/theme_controller.dart` (new): `ThemeController` (ChangeNotifier,
  maps preference to `ThemeMode`) and `ThemeScope` (InheritedNotifier), mirroring
  `LocaleController`/`LocaleScope`.
- `lib/main.dart`: seeds `ThemeController` from the saved setting; adds
  `darkTheme` (deep purple seed, dark brightness), `themeMode`, and switches the
  forui `FTheme` colors on `Theme.of(context).brightness`.
- `lib/l10n/app_localizations.dart`: added `theme`, `dark`, `light` (en/zh).
- `lib/screens/settings_screen.dart`: added a Theme section with a light/dark
  `RadioGroup`, persisted via `DatabaseService.setSetting` and applied
  immediately via `ThemeScope`.
- `test/theme_preference_test.dart` (new), `test/theme_controller_test.dart`
  (new): unit + widget tests.
- `test/settings_screen_test.dart`: theme selector tests (options, default,
  persistence, saved-preference reflection).
- `test/widget_test.dart`: passes a `ThemeController` to `MyApp`.

### Verification
- `flutter analyze` — clean
- `flutter test` — 155 tests pass
