# Change Log 2026-09-26

## Task: Setting in production mode (issue #17)

In production mode, hide the model path and the "Remove Model File" action, and
make the system prompt read-only. Development (debug) builds keep the existing
editable behavior.

### Prompt / intent
- Issue #17: "In production model, we should hide the model path, and remove
  model file button. System prompt should be read only."

### Design
- Production is the inverse of the existing `AppConfig.allowModelSelection`
  flag (default `kDebugMode`, overridable with
  `--dart-define=ALLOW_MODEL_SELECTION`). Added `AppConfig.isProduction` as a
  `const` so it can be used as a default parameter value.
- Threaded an injectable `isProduction` / `readOnly` flag so widget tests can
  exercise both modes without relying on the build mode.

### Changes
- `lib/config/app_config.dart`: added
  `static const bool isProduction = !allowModelSelection;`.
- `lib/screens/settings_screen.dart`:
  - imports `app_config.dart`; new `isProduction` param
    (default `AppConfig.isProduction`).
  - the "Full Path" tile and the "Remove Model File" button are now rendered
    only when `!isProduction`.
  - passes `readOnly: widget.isProduction` to `PromptEditorScreen`.
- `lib/screens/prompt_editor_screen.dart`: new `readOnly` param (default
  `false`). When true, the `TextField` is `readOnly`, the Save/Reset buttons are
  hidden, and the instruction text switches to `promptReadOnly`.
- `lib/l10n/app_localizations.dart`: added `promptReadOnly` (en/zh).
- `test/app_config_test.dart` (new): `isProduction` is the inverse of
  `allowModelSelection`; test builds are not production.
- `test/settings_screen_test.dart`: development shows the model path and
  remove-file action; production hides them (while keeping other settings).
- `test/prompt_editor_screen_test.dart`: read-only mode hides Save/Reset,
  shows the read-only note, and locks the field.

### Verification
- `flutter analyze` — 3 pre-existing info lints (unrelated to this change)
- `flutter test` — 186 tests pass
