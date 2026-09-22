# Change Log 2026-09-21

## Task: Localize the UI so the language setting takes effect (issue #7)

Fixes issue #7: "First page does not follow language selection to display label
and content."

### Problem
The language preference (English / Chinese) was only used to choose the LLM
explanation language. There was no UI localization layer, so every screen label
was a hardcoded English string — the first page stayed English regardless of the
setting.

### Changes
- **New localization layer**
  - `lib/l10n/app_localizations.dart` — hand-written `AppLocalizations` with
    English / Traditional Chinese strings for every screen, a
    `LocalizationsDelegate`, and `supportedLocales`. `AppLocalizations.of`
    falls back to English when no delegate is installed (keeps isolated widget
    tests working).
  - `lib/l10n/locale_controller.dart` — `LocaleController` (ChangeNotifier) plus
    an `InheritedNotifier` `LocaleScope` so any screen can read/change the
    active language.
- **`main.dart`** — seeds the controller from the saved `language` setting and
  wires `MaterialApp.locale`, `supportedLocales`, and `localizationsDelegates`
  (app + `GlobalMaterial/Widgets/Cupertino`).
- **Screens localized**: QuestionFormScreen (incl. `QuestionType` labels),
  SettingsScreen, ModelSelectionScreen, CastResultScreen, ExplanationScreen,
  HexagramBrowserScreen, HexagramDetailScreen, PromptEditorScreen.
- **SettingsScreen** now updates the app-wide locale immediately when the
  language is changed (`LocaleScope.maybeOf(context)?.setLanguage`).
- Startup logic moved from `initState` to `didChangeDependencies` where
  localizations are available.
- `pubspec.yaml` — added `flutter_localizations`.

### Tests
- `test/app_localizations_test.dart` — EN/ZH strings, interpolation, supported
  locales, and `LocaleController` behaviour.
- `question_form_screen_test.dart` — regression test: with `locale: zh`, the
  first page renders Chinese labels.
- Updated existing widget/integration tests that asserted Chinese UI strings to
  the new English strings (default locale).

### Verification
- `flutter analyze` — no new issues (2 pre-existing info lints)
- `flutter test` — 107 unit tests pass
- `flutter test -d windows integration_test/cast_and_browse_test.dart` — 2 pass

### Follow-up: localized question category on the explanation page
The consultation category was still shown in English (e.g. "Career
Achievement") because the form passed `QuestionType.label` (a hardcoded English
string) through to the explanation screen.

- Moved `QuestionType` to `lib/models/question_type.dart` (dropped the hardcoded
  `label`; the icon stays).
- Added `AppLocalizations.questionTypeLabel(QuestionType)`.
- `QuestionFormScreen` now passes the **localized** category label into the
  consultation flow (used for display and the LLM prompt).
- Added a regression test: with `locale: zh`, submitting the form yields
  `questionTypeLabel == '事業成就'`.

Verification: `flutter analyze` clean, 108 unit tests pass, integration test
passes.

### Code review follow-up
Manual review (per the code-review skill) found one more untranslated string:
`ModelSelectionScreen`'s AppBar still hardcoded `'I-Ching Setup'` (and the
`setupTitle` localization was unused). Fixed to use
`AppLocalizations.of(context).setupTitle` and added a zh regression test.

Verification: `flutter analyze` clean, 109 unit tests pass, integration test
passes.

## Task: Fix hexagram display collapsed (issue #12)

The 6-line hexagram figure in `HexagramDetailScreen`'s header was drawn with
wide (160px), thin (5px) bars, so the figure was wider than tall.

- Added `lib/widgets/hexagram_view.dart` — `HexagramView` renders the six yao
  lines bottom→top with narrow bars (default 72px wide, 9px thick, 6px gaps),
  making the figure taller than it is wide.
- `HexagramDetailScreen` now uses `HexagramView`; removed the local `_Line`.
- Added `test/hexagram_view_test.dart` — asserts the figure is taller than wide,
  yang = one bar / yin = two segments, and custom dimensions.

Verification: `flutter analyze` clean, 112 unit tests pass, integration test
passes.
