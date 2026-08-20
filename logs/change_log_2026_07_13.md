# Change Log — 2026-07-13

## Prompt
Add back the settings menu on the question form screen.

## Thinking

### Design
Added a `PopupMenuButton` (⋯) to the `QuestionFormScreen` AppBar with a
"Settings" item that navigates to `SettingsScreen`, mirroring the chat
screen's header menu. The question form already had access to both
`llmService` and `databaseService`, so both are passed through.

## Files Changed

### Modified
- `app/lib/screens/question_form_screen.dart` — settings menu in AppBar
- `app/test/question_form_screen_test.dart` — settings menu opens test

## Test Results
- Unit tests: 100/100 passed
