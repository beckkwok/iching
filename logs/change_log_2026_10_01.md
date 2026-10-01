# Change Log 2026-10-01

## Task: Delete chat history (issue #45)

"Should provide a function to allow user to delete chat history."

### Design
- Each consultation card in the History tab gets a delete action (trash icon)
  with a confirmation dialog; deleting removes it from the database and the list
  immediately.
- `DatabaseService` gains `deleteConsultation(id)` and
  `deleteAllConsultations()` (the latter for a future "clear all").

### Changes
- `lib/services/database_service.dart`: `deleteConsultation(int id)` and
  `deleteAllConsultations()`.
- `lib/screens/history_screen.dart`: `_delete(consultation)` shows a confirm
  dialog, deletes via the DB, and removes it from `_consultations`; the card
  takes an `onDelete` callback and renders a trash `IconButton`.
- `lib/l10n/app_localizations.dart`: `delete`, `deleteConsultationTitle`,
  `deleteConsultationBody` (en/zh).
- Tests: `database_service_test` (delete one / delete all),
  `history_screen_test` (delete after confirmation, with a mutable fake DB).

### Verification
- `flutter analyze` — 3 pre-existing info lints (unrelated)
- `flutter test` — 202 tests pass

## Task: Manual hexagram input (issue #20)

Per the issue comment, "Full Generate" is tracked separately in #51, so this adds
**Manual** alongside the existing random **Quick Generate**.

### Design
- The "generate hexagram" checkbox becomes a `SegmentedButton` with two options:
  Quick Generate (default, current behaviour) and Manual.
- Choosing Manual opens `ManualCastScreen`: six yao lines (default 少陽). Tapping
  a line offers 少陰/少陽/老陰/老陽; the resulting hexagram name is resolved live.
  A "Use this hexagram" button proceeds to `CastResultScreen`.
- Manual casts reuse `GenerationResult` and `resolveCast`, with a new optional
  `method` so the prompt is framed as `GeneratorMethod.manual`.

### Changes
- `lib/services/gua_generator.dart`: `resolveCast` takes an optional
  `GeneratorMethod method`.
- `lib/screens/manual_cast_screen.dart` (new): the line-by-line picker.
- `lib/screens/question_form_screen.dart`: `CastMethod` segmented control; Manual
  opens `ManualCastScreen`, Quick keeps `generateRandom()`.
- `lib/l10n/app_localizations.dart`: `castingMethod`, `quickGenerate`,
  `manualGenerate`, `manualCastTitle`, `manualCastHint`, `manualCastLine`,
  `manualCastProceed` (en/zh).
- `AGENTS.md`: consultation-flow pattern updated.
- Tests: `test/manual_cast_screen_test.dart` (new); `question_form_screen_test`
  updated for the segmented control and the Manual path.

### Verification
- `flutter analyze` — 3 pre-existing info lints (unrelated)
- `flutter test` — 205 tests pass

## Task: Display the changed hexagram (issue #42)

"Original hexagram is current state, bi gram is the change you notice and
flipped hexagram is the possible future state."

### Design
- `GenerationResult` carries `changedLines` (the six lines after flipping every
  老陰/老陽) and `changedGua` (`null` when nothing changes), computed in
  `GuaGenerator.resolveCast()` so quick, manual and future casts all get them.
- The cast-result screen shows a "Changed hexagram (future state)" card with the
  flipped figure; tapping opens its detail screen.

### Changes
- `lib/services/gua_generator.dart`: `changedLines`/`changedGua` on
  `GenerationResult`, resolved in `resolveCast()`.
- `lib/screens/cast_result_screen.dart`: changed-hexagram card.
- `lib/l10n/app_localizations.dart`: `changedHexagram` (en/zh).
- `AGENTS.md`: key-pattern note.
- Tests: `gua_generator_test` (flip + resolve, no-change), and
  `cast_result_screen_test` (changed card).

### Verification
- `flutter analyze` — 3 pre-existing info lints (unrelated)
- `flutter test` — 208 tests pass
