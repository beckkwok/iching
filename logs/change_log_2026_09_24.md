# Change Log 2026-09-24

## Task: Purple gradient buttons (issue #31, part of #28)

Style the primary call-to-action buttons with a deep-purple gradient fill.

### Prompt / intent
- Purple `#673AB7` (deep purple) with a lighter shade, as a **gradient**
  (purple → lighter purple).

### Changes
- `lib/widgets/gradient_button.dart` (new): a reusable `GradientButton`
  (label + optional icon, gradient `#673AB7` → `#9C4DCC`, ripple, disabled
  opacity) replacing `FilledButton`/`FilledButton.icon` for primary CTAs.
- Replaced primary CTAs with `GradientButton`:
  - `question_form_screen.dart` (Submit Question)
  - `cast_result_screen.dart` (Get Explanation)
  - `explanation_screen.dart` (Submit feedback)
  - `prompt_editor_screen.dart` (Save)
  - `model_selection_screen.dart` (Confirm & Download, Continue anyway)
  - Loading spinners inside these buttons are now white for contrast.
- `test/gradient_button_test.dart` (new): label/icon render, enabled/disabled
  tap, and gradient-fill verification.

### Verification
- `flutter analyze` — clean
- `flutter test` — 160 tests pass
